import 'package:freezed_annotation/freezed_annotation.dart';

part 'garment.freezed.dart';
part 'garment.g.dart';

@freezed
abstract class Garment with _$Garment {
  const factory Garment({
    required String id,
    @JsonKey(name: 'name_tr') required String nameTr,
    @JsonKey(name: 'name_en') String? nameEn,
    String? brand,
    required String category,
    String? color,
    @JsonKey(name: 'storage_path') required String storagePath,
    @JsonKey(name: 'thumbnail_path') String? thumbnailPath,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _Garment;

  factory Garment.fromJson(Map<String, dynamic> json) => _$GarmentFromJson(json);
}

enum GarmentCategory {
  top('Üst', 'top'),
  bottom('Alt', 'bottom'),
  dress('Elbise', 'dress'),
  outerwear('Dış Giyim', 'outerwear'),
  all('Tümü', 'all');

  final String labelTr;
  final String value;
  const GarmentCategory(this.labelTr, this.value);
}
