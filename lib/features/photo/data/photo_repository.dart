import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../core/supabase/supabase_client.dart';

part 'photo_repository.g.dart';

@riverpod
PhotoRepository photoRepository(PhotoRepositoryRef ref) {
  return PhotoRepository();
}

class PhotoRepository {
  static const _bucket = 'user-photos';

  /// Compress and upload a user photo, return the storage path.
  Future<String> uploadUserPhoto({
    required File file,
    required String userId,
  }) async {
    final photoId = const Uuid().v4();
    final ext = path.extension(file.path).toLowerCase();
    final storagePath = '$userId/$photoId$ext';

    // Compress before upload (max 1080px width, 85% quality)
    final compressed = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      minWidth: 768,
      minHeight: 1024,
      quality: 85,
      format: CompressFormat.jpeg,
    );

    if (compressed == null) throw Exception('Image compression failed');

    await supabase.storage
        .from(_bucket)
        .uploadBinary(
          storagePath,
          compressed,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );

    return storagePath;
  }

  /// Create a record in user_photos table and return the row id.
  Future<String> createPhotoRecord({
    required String userId,
    required String storagePath,
    int? width,
    int? height,
  }) async {
    // Deactivate all previous active photos
    await supabase
        .from('user_photos')
        .update({'is_active': false})
        .eq('user_id', userId)
        .eq('is_active', true);

    final result = await supabase
        .from('user_photos')
        .insert({
          'user_id': userId,
          'storage_path': storagePath,
          'is_active': true,
          if (width != null) 'width': width,
          if (height != null) 'height': height,
        })
        .select()
        .single();

    return result['id'] as String;
  }

  /// Get signed URL for a user photo (private bucket).
  Future<String> getSignedUrl(String storagePath) async {
    return supabase.storage
        .from(_bucket)
        .createSignedUrl(storagePath, 3600); // 1 hour
  }

  /// Get the current active user photo for [userId].
  Future<Map<String, dynamic>?> getActivePhoto(String userId) async {
    final result = await supabase
        .from('user_photos')
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .maybeSingle();
    return result;
  }
}
