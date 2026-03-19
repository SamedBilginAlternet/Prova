import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/photo/data/photo_repository.dart';
import '../data/tryon_repository.dart';
import '../models/tryon_job.dart';

part 'tryon_provider.g.dart';

/// Watches a tryon job via Realtime and resolves once completed/failed.
@riverpod
Stream<TryonJob> tryonJobStream(Ref ref, String jobId) {
  final repo = ref.watch(tryonRepositoryProvider);
  return repo.watchJob(jobId);
}

/// Fetch a specific result by its ID.
@riverpod
Future<TryonResult?> tryonResultByJob(
  Ref ref,
  String jobId,
) async {
  final repo = ref.watch(tryonRepositoryProvider);
  return repo.getResultForJob(jobId);
}

/// Get signed URL for a result image.
@riverpod
Future<String?> tryonResultUrl(
  Ref ref,
  String storagePath,
) async {
  final repo = ref.read(tryonRepositoryProvider);
  return repo.getResultUrl(storagePath);
}

/// User's history of try-on results.
@riverpod
Future<List<Map<String, dynamic>>> tryonHistory(Ref ref) async {
  ref.watch(currentUserProvider); // invalidate on auth change
  final repo = ref.watch(tryonRepositoryProvider);
  return repo.getUserHistory();
}

/// State for triggering a try-on job.
sealed class TryonTriggerState {}
class TryonTriggerIdle extends TryonTriggerState {}
class TryonTriggerLoading extends TryonTriggerState {}
class TryonTriggerSuccess extends TryonTriggerState {
  final String jobId;
  TryonTriggerSuccess(this.jobId);
}
class TryonTriggerError extends TryonTriggerState {
  final String message;
  TryonTriggerError(this.message);
}

@riverpod
class TryonTriggerNotifier extends _$TryonTriggerNotifier {
  @override
  TryonTriggerState build() => TryonTriggerIdle();

  Future<void> trigger({
    required String garmentId,
  }) async {
    state = TryonTriggerLoading();

    try {
      // Get the user's active photo
      final user = ref.read(currentUserProvider);
      if (user == null) {
        state = TryonTriggerError('Oturum açmanız gerekiyor');
        return;
      }

      final photoRepo = ref.read(photoRepositoryProvider);
      final activePhoto = await photoRepo.getActivePhoto(user.id);

      if (activePhoto == null) {
        state = TryonTriggerError('Önce bir fotoğraf yüklemeniz gerekiyor');
        return;
      }

      final repo = ref.read(tryonRepositoryProvider);
      final jobId = await repo.triggerTryon(
        photoId: activePhoto['id'] as String,
        garmentId: garmentId,
      );

      state = TryonTriggerSuccess(jobId);
    } catch (e) {
      state = TryonTriggerError('Deneme başlatılamadı: ${e.toString()}');
    }
  }

  void reset() => state = TryonTriggerIdle();
}
