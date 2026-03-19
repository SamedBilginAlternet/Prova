import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/photo_repository.dart';

part 'photo_provider.g.dart';

/// The currently selected local file (before upload).
@riverpod
class SelectedPhotoFile extends _$SelectedPhotoFile {
  @override
  File? build() => null;

  void set(File file) => state = file;
  void clear() => state = null;
}

/// The active uploaded photo record (storage_path + id).
@riverpod
Future<Map<String, dynamic>?> activeUserPhoto(Ref ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final repo = ref.watch(photoRepositoryProvider);
  return repo.getActivePhoto(user.id);
}

/// Signed URL for the active user photo.
@riverpod
Future<String?> activePhotoUrl(Ref ref) async {
  final photo = await ref.watch(activeUserPhotoProvider.future);
  if (photo == null) return null;

  final repo = ref.read(photoRepositoryProvider);
  return repo.getSignedUrl(photo['storage_path'] as String);
}

/// Upload state machine
sealed class UploadState {}
class UploadIdle extends UploadState {}
class UploadInProgress extends UploadState {
  final double progress;
  UploadInProgress(this.progress);
}
class UploadSuccess extends UploadState {
  final String photoId;
  UploadSuccess(this.photoId);
}
class UploadError extends UploadState {
  final String message;
  UploadError(this.message);
}

@riverpod
class PhotoUploadNotifier extends _$PhotoUploadNotifier {
  @override
  UploadState build() => UploadIdle();

  Future<void> upload(File file) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = UploadError('Oturum açmanız gerekiyor');
      return;
    }

    state = UploadInProgress(0.1);

    try {
      final repo = ref.read(photoRepositoryProvider);

      // Upload to storage
      state = UploadInProgress(0.4);
      final storagePath = await repo.uploadUserPhoto(
        file: file,
        userId: user.id,
      );

      // Create DB record
      state = UploadInProgress(0.8);
      final photoId = await repo.createPhotoRecord(
        userId: user.id,
        storagePath: storagePath,
      );

      state = UploadSuccess(photoId);

      // Refresh the active photo cache
      ref.invalidate(activeUserPhotoProvider);
      ref.invalidate(activePhotoUrlProvider);
    } catch (e) {
      state = UploadError('Fotoğraf yüklenemedi: ${e.toString()}');
    }
  }

  void reset() => state = UploadIdle();
}
