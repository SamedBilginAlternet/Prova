import 'package:freezed_annotation/freezed_annotation.dart';

part 'stylist_models.freezed.dart';
part 'stylist_models.g.dart';

// =============================================
// Stylist Session & Messages
// =============================================

@freezed
class StylistSession with _$StylistSession {
  const factory StylistSession({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    String? title,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _StylistSession;

  factory StylistSession.fromJson(Map<String, dynamic> json) =>
      _$StylistSessionFromJson(json);
}

@freezed
class StylistMessage with _$StylistMessage {
  const factory StylistMessage({
    required String id,
    @JsonKey(name: 'session_id') required String sessionId,
    @JsonKey(name: 'user_id') required String userId,
    required String role,
    required String content,
    @JsonKey(name: 'structured_data') Map<String, dynamic>? structuredData,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _StylistMessage;

  factory StylistMessage.fromJson(Map<String, dynamic> json) =>
      _$StylistMessageFromJson(json);

  // Convenience: parse structured AI response
  StylistResponse? get parsedResponse {
    if (structuredData == null) return null;
    try {
      return StylistResponse.fromJson(structuredData!);
    } catch (_) {
      return null;
    }
  }
}

// =============================================
// Structured AI Response — rendered as UI cards
// =============================================

enum StylistResponseType {
  @JsonValue('outfit_suggestion') outfitSuggestion,
  @JsonValue('style_advice') styleAdvice,
  @JsonValue('outfit_rating') outfitRating,
  @JsonValue('wardrobe_analysis') wardrobeAnalysis,
  @JsonValue('general') general,
}

@freezed
class StylistResponse with _$StylistResponse {
  const factory StylistResponse({
    @JsonKey(name: 'response_type')
    @Default(StylistResponseType.general)
    StylistResponseType responseType,
    required String message,
    @JsonKey(name: 'outfit_suggestions')
    @Default([])
    List<OutfitSuggestion> outfitSuggestions,
    @JsonKey(name: 'style_tips') @Default([]) List<String> styleTips,
    @JsonKey(name: 'missing_items') @Default([]) List<String> missingItems,
    @JsonKey(name: 'rating') OutfitRating? rating,
    @JsonKey(name: 'follow_up_questions')
    @Default([])
    List<String> followUpQuestions,
  }) = _StylistResponse;

  factory StylistResponse.fromJson(Map<String, dynamic> json) =>
      _$StylistResponseFromJson(json);
}

@freezed
class OutfitSuggestion with _$OutfitSuggestion {
  const factory OutfitSuggestion({
    required String name,
    @JsonKey(name: 'item_ids') @Default([]) List<String> itemIds,
    @JsonKey(name: 'missing_items') @Default([]) List<String> missingItems,
    String? reasoning,
    String? occasion,
    @Default(0.8) double confidence,
  }) = _OutfitSuggestion;

  factory OutfitSuggestion.fromJson(Map<String, dynamic> json) =>
      _$OutfitSuggestionFromJson(json);
}

@freezed
class OutfitRating with _$OutfitRating {
  const factory OutfitRating({
    @Default(7) int score,        // 1-10
    String? summary,
    @Default([]) List<String> positives,
    @Default([]) List<String> improvements,
  }) = _OutfitRating;

  factory OutfitRating.fromJson(Map<String, dynamic> json) =>
      _$OutfitRatingFromJson(json);
}

// =============================================
// Saved Outfit
// =============================================

@freezed
class SavedOutfit with _$SavedOutfit {
  const factory SavedOutfit({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    String? name,
    String? occasion,
    String? season,
    @JsonKey(name: 'ai_generated') @Default(false) bool aiGenerated,
    @JsonKey(name: 'ai_reasoning') String? aiReasoning,
    String? notes,
    @JsonKey(name: 'cover_path') String? coverPath,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @Default([]) List<OutfitItemRef> items,
  }) = _SavedOutfit;

  factory SavedOutfit.fromJson(Map<String, dynamic> json) =>
      _$SavedOutfitFromJson(json);
}

@freezed
class OutfitItemRef with _$OutfitItemRef {
  const factory OutfitItemRef({
    required String id,
    @JsonKey(name: 'outfit_id') required String outfitId,
    @JsonKey(name: 'wardrobe_item_id') String? wardrobeItemId,
    @JsonKey(name: 'garment_id') String? garmentId,
    @Default(0) int position,
    // Resolved item data (joined)
    @JsonKey(name: 'wardrobe_items') Map<String, dynamic>? wardrobeItemData,
    @JsonKey(name: 'garments') Map<String, dynamic>? garmentData,
  }) = _OutfitItemRef;

  factory OutfitItemRef.fromJson(Map<String, dynamic> json) =>
      _$OutfitItemRefFromJson(json);
}
