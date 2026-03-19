import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/garment.dart';

part 'garment_repository.g.dart';

@riverpod
GarmentRepository garmentRepository(GarmentRepositoryRef ref) {
  return GarmentRepository();
}

class GarmentRepository {
  Future<List<Garment>> getGarments({String? category}) async {
    var query = supabase
        .from('garments')
        .select()
        .eq('is_active', true);

    if (category != null && category != 'all') {
      query = query.eq('category', category);
    }

    final data = await query.order('created_at', ascending: false);
    return data.map<Garment>((json) => Garment.fromJson(json)).toList();
  }

  Future<Garment?> getGarment(String id) async {
    final data = await supabase
        .from('garments')
        .select()
        .eq('id', id)
        .single();
    return Garment.fromJson(data);
  }

  /// Get the public URL for a garment image.
  /// Garment bucket is public so no signed URL needed.
  String getGarmentImageUrl(String storagePath) {
    return supabase.storage
        .from('garment-images')
        .getPublicUrl(storagePath);
  }

  String getGarmentThumbnailUrl(String? thumbnailPath, String storagePath) {
    final path = thumbnailPath ?? storagePath;
    return supabase.storage.from('garment-images').getPublicUrl(path);
  }
}
