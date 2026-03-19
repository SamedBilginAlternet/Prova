import 'package:freezed_annotation/freezed_annotation.dart';

part 'wardrobe_item.freezed.dart';
part 'wardrobe_item.g.dart';

@freezed
abstract class WardrobeItem with _$WardrobeItem {
  const factory WardrobeItem({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    String? name,
    required String category,
    String? color,
    @JsonKey(name: 'color_hex') String? colorHex,
    String? pattern,
    String? season,
    String? occasion,
    String? brand,
    @JsonKey(name: 'storage_path') required String storagePath,
    @JsonKey(name: 'thumbnail_path') String? thumbnailPath,
    @JsonKey(name: 'is_favorite') @Default(false) bool isFavorite,
    String? notes,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _WardrobeItem;

  factory WardrobeItem.fromJson(Map<String, dynamic> json) =>
      _$WardrobeItemFromJson(json);
}

enum WardrobeCategory {
  top('Üst', 'top', '👕'),
  bottom('Alt', 'bottom', '👖'),
  dress('Elbise', 'dress', '👗'),
  outerwear('Dış Giyim', 'outerwear', '🧥'),
  shoes('Ayakkabı', 'shoes', '👟'),
  bag('Çanta', 'bag', '👜'),
  accessory('Aksesuar', 'accessory', '💍'),
  other('Diğer', 'other', '🎽');

  final String labelTr;
  final String value;
  final String emoji;

  const WardrobeCategory(this.labelTr, this.value, this.emoji);

  static WardrobeCategory fromValue(String? value) =>
      WardrobeCategory.values.firstWhere(
        (c) => c.value == value,
        orElse: () => WardrobeCategory.other,
      );
}

enum WardrobeSeason {
  all('Her Mevsim', 'all'),
  spring('İlkbahar', 'spring'),
  summer('Yaz', 'summer'),
  autumn('Sonbahar', 'autumn'),
  winter('Kış', 'winter');

  final String labelTr;
  final String value;
  const WardrobeSeason(this.labelTr, this.value);
}

enum WardrobeOccasion {
  all('Her Ortam', 'all'),
  casual('Günlük', 'casual'),
  work('İş', 'work'),
  evening('Gece', 'evening'),
  formal('Resmi', 'formal'),
  sport('Spor', 'sport');

  final String labelTr;
  final String value;
  const WardrobeOccasion(this.labelTr, this.value);
}
