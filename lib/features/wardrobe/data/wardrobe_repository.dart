import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/wardrobe_item.dart';

part 'wardrobe_repository.g.dart';

@riverpod
WardrobeRepository wardrobeRepository(Ref ref) {
  return WardrobeRepository();
}

class WardrobeRepository {
  static const _bucket = 'wardrobe-items';
  static const _table = 'wardrobe_items';

  Future<List<WardrobeItem>> getItems({
    String? category,
    String? season,
    String? occasion,
  }) async {
    var query = supabase.from(_table).select();

    if (category != null) query = query.eq('category', category);
    if (season != null && season != 'all') query = query.eq('season', season);
    if (occasion != null && occasion != 'all') query = query.eq('occasion', occasion);

    final data = await query.order('created_at', ascending: false);
    return data.map<WardrobeItem>((j) => WardrobeItem.fromJson(j)).toList();
  }

  Future<WardrobeItem> getItem(String id) async {
    final data = await supabase.from(_table).select().eq('id', id).single();
    return WardrobeItem.fromJson(data);
  }

  Future<WardrobeItem> addItem({
    required String userId,
    required File imageFile,
    required String category,
    String? name,
    String? color,
    String? colorHex,
    String? pattern,
    String? season,
    String? occasion,
    String? brand,
    String? notes,
  }) async {
    final itemId = const Uuid().v4();
    final ext = p.extension(imageFile.path).toLowerCase().replaceAll('.', '');
    final storagePath = '$userId/$itemId.jpg';

    // Compress image
    final compressed = await FlutterImageCompress.compressWithFile(
      imageFile.absolute.path,
      minWidth: 600,
      minHeight: 800,
      quality: 85,
      format: CompressFormat.jpeg,
    );
    if (compressed == null) throw Exception('Görsel sıkıştırılamadı');

    // Upload to storage
    await supabase.storage.from(_bucket).uploadBinary(
          storagePath,
          compressed,
          fileOptions: FileOptions(contentType: 'image/jpeg', upsert: true),
        );

    // Insert DB record
    final data = await supabase
        .from(_table)
        .insert({
          'id': itemId,
          'user_id': userId,
          'category': category,
          'storage_path': storagePath,
          if (name != null) 'name': name,
          if (color != null) 'color': color,
          if (colorHex != null) 'color_hex': colorHex,
          if (pattern != null) 'pattern': pattern,
          if (season != null) 'season': season,
          if (occasion != null) 'occasion': occasion,
          if (brand != null) 'brand': brand,
          if (notes != null) 'notes': notes,
        })
        .select()
        .single();

    return WardrobeItem.fromJson(data);
  }

  Future<void> updateItem(String id, Map<String, dynamic> updates) async {
    await supabase.from(_table).update(updates).eq('id', id);
  }

  Future<void> deleteItem(WardrobeItem item) async {
    // Delete from storage first
    await supabase.storage.from(_bucket).remove([item.storagePath]);
    if (item.thumbnailPath != null) {
      await supabase.storage.from(_bucket).remove([item.thumbnailPath!]);
    }
    // Delete DB record
    await supabase.from(_table).delete().eq('id', item.id);
  }

  Future<void> toggleFavorite(String id, bool isFavorite) async {
    await supabase.from(_table).update({'is_favorite': isFavorite}).eq('id', id);
  }

  /// Get signed URL for a wardrobe item image.
  Future<String> getSignedUrl(String storagePath) async {
    return supabase.storage.from(_bucket).createSignedUrl(storagePath, 3600);
  }

  /// Build a compact wardrobe summary for AI context.
  /// Returns a list of maps with just the fields the AI needs.
  Future<List<Map<String, dynamic>>> getWardrobeSummary(String userId) async {
    final data = await supabase
        .from(_table)
        .select('id, name, category, color, pattern, season, occasion, brand')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(100); // cap context size

    return List<Map<String, dynamic>>.from(data);
  }
}
