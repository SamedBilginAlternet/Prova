import 'package:freezed_annotation/freezed_annotation.dart';

part 'tryon_job.freezed.dart';
part 'tryon_job.g.dart';

enum TryonJobStatus {
  @JsonValue('pending') pending,
  @JsonValue('processing') processing,
  @JsonValue('completed') completed,
  @JsonValue('failed') failed,
}

@freezed
class TryonJob with _$TryonJob {
  const factory TryonJob({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'photo_id') required String photoId,
    @JsonKey(name: 'garment_id') required String garmentId,
    required TryonJobStatus status,
    @JsonKey(name: 'error_msg') String? errorMsg,
    @JsonKey(name: 'hf_job_id') String? hfJobId,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _TryonJob;

  factory TryonJob.fromJson(Map<String, dynamic> json) =>
      _$TryonJobFromJson(json);
}

@freezed
class TryonResult with _$TryonResult {
  const factory TryonResult({
    required String id,
    @JsonKey(name: 'job_id') required String jobId,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'storage_path') required String storagePath,
    @JsonKey(name: 'is_favorite') @Default(false) bool isFavorite,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _TryonResult;

  factory TryonResult.fromJson(Map<String, dynamic> json) =>
      _$TryonResultFromJson(json);
}
