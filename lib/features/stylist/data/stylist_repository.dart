import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/stylist_models.dart';

part 'stylist_repository.g.dart';

@riverpod
StylistRepository stylistRepository(StylistRepositoryRef ref) {
  return StylistRepository();
}

class StylistRepository {
  // ── Sessions ──────────────────────────────────────────────
  Future<StylistSession> createSession({String? title}) async {
    final data = await supabase
        .from('stylist_sessions')
        .insert({'title': title})
        .select()
        .single();
    return StylistSession.fromJson(data);
  }

  Future<List<StylistSession>> getSessions() async {
    final data = await supabase
        .from('stylist_sessions')
        .select()
        .order('updated_at', ascending: false)
        .limit(20);
    return data.map<StylistSession>((j) => StylistSession.fromJson(j)).toList();
  }

  Future<void> updateSessionTitle(String id, String title) async {
    await supabase
        .from('stylist_sessions')
        .update({'title': title})
        .eq('id', id);
  }

  Future<void> deleteSession(String id) async {
    await supabase.from('stylist_sessions').delete().eq('id', id);
  }

  // ── Messages ──────────────────────────────────────────────
  Future<List<StylistMessage>> getMessages(String sessionId) async {
    final data = await supabase
        .from('stylist_messages')
        .select()
        .eq('session_id', sessionId)
        .order('created_at', ascending: true);
    return data.map<StylistMessage>((j) => StylistMessage.fromJson(j)).toList();
  }

  Future<StylistMessage> addUserMessage({
    required String sessionId,
    required String userId,
    required String content,
    List<String>? wardrobeItemIds,
  }) async {
    final data = await supabase
        .from('stylist_messages')
        .insert({
          'session_id': sessionId,
          'user_id': userId,
          'role': 'user',
          'content': content,
          if (wardrobeItemIds != null)
            'wardrobe_snapshot': wardrobeItemIds,
        })
        .select()
        .single();
    return StylistMessage.fromJson(data);
  }

  Future<StylistMessage> addAssistantMessage({
    required String sessionId,
    required String userId,
    required String content,
    Map<String, dynamic>? structuredData,
  }) async {
    final data = await supabase
        .from('stylist_messages')
        .insert({
          'session_id': sessionId,
          'user_id': userId,
          'role': 'assistant',
          'content': content,
          if (structuredData != null) 'structured_data': structuredData,
        })
        .select()
        .single();
    return StylistMessage.fromJson(data);
  }

  // ── Outfits ────────────────────────────────────────────────
  Future<SavedOutfit> saveOutfit({
    required String userId,
    required String name,
    required List<String> wardrobeItemIds,
    List<String>? garmentIds,
    String? occasion,
    String? season,
    String? aiReasoning,
    String? sessionId,
    bool aiGenerated = true,
  }) async {
    // Create outfit record
    final outfitData = await supabase
        .from('outfits')
        .insert({
          'user_id': userId,
          'name': name,
          'ai_generated': aiGenerated,
          if (occasion != null) 'occasion': occasion,
          if (season != null) 'season': season,
          if (aiReasoning != null) 'ai_reasoning': aiReasoning,
          if (sessionId != null) 'session_id': sessionId,
        })
        .select()
        .single();

    final outfitId = outfitData['id'] as String;

    // Add outfit items
    final items = [
      for (int i = 0; i < wardrobeItemIds.length; i++)
        {
          'outfit_id': outfitId,
          'wardrobe_item_id': wardrobeItemIds[i],
          'position': i,
        },
      if (garmentIds != null)
        for (int i = 0; i < garmentIds.length; i++)
          {
            'outfit_id': outfitId,
            'garment_id': garmentIds[i],
            'position': wardrobeItemIds.length + i,
          },
    ];

    if (items.isNotEmpty) {
      await supabase.from('outfit_items').insert(items);
    }

    return SavedOutfit.fromJson({
      ...outfitData,
      'items': [],
    });
  }

  Future<List<SavedOutfit>> getOutfits() async {
    final data = await supabase
        .from('outfits')
        .select('''
          *,
          outfit_items (
            *,
            wardrobe_items (id, name, category, color, storage_path),
            garments (id, name_tr, category, storage_path)
          )
        ''')
        .order('created_at', ascending: false);

    return data.map<SavedOutfit>((json) {
      final items = (json['outfit_items'] as List?)
              ?.map((i) => OutfitItemRef.fromJson(i))
              .toList() ??
          [];
      return SavedOutfit.fromJson({...json, 'items': items});
    }).toList();
  }

  Future<void> deleteOutfit(String id) async {
    await supabase.from('outfits').delete().eq('id', id);
  }
}
