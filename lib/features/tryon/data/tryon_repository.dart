import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/tryon_job.dart';

part 'tryon_repository.g.dart';

@riverpod
TryonRepository tryonRepository(Ref ref) {
  return TryonRepository();
}

class TryonRepository {
  static const _jobsTable = 'tryon_jobs';
  static const _resultsTable = 'tryon_results';
  static const _resultsBucket = 'tryon-results';

  /// Trigger a try-on job via the Edge Function.
  /// Returns the created job ID.
  Future<String> triggerTryon({
    required String photoId,
    required String garmentId,
  }) async {
    final response = await supabase.functions.invoke(
      'trigger-tryon',
      body: {
        'photo_id': photoId,
        'garment_id': garmentId,
      },
    );

    if (response.status != 200) {
      throw Exception('Deneme başlatılamadı: ${response.data}');
    }

    return response.data['job_id'] as String;
  }

  /// Stream real-time updates for a specific job.
  Stream<TryonJob> watchJob(String jobId) {
    return supabase
        .from(_jobsTable)
        .stream(primaryKey: ['id'])
        .eq('id', jobId)
        .map((rows) {
          if (rows.isEmpty) throw Exception('Job not found');
          return TryonJob.fromJson(rows.first);
        });
  }

  /// Get a single job by ID.
  Future<TryonJob> getJob(String jobId) async {
    final data = await supabase
        .from(_jobsTable)
        .select()
        .eq('id', jobId)
        .single();
    return TryonJob.fromJson(data);
  }

  /// Get result for a completed job.
  Future<TryonResult?> getResultForJob(String jobId) async {
    final data = await supabase
        .from(_resultsTable)
        .select()
        .eq('job_id', jobId)
        .maybeSingle();
    if (data == null) return null;
    return TryonResult.fromJson(data);
  }

  /// Get signed URL for a try-on result (private bucket).
  Future<String> getResultUrl(String storagePath) async {
    return supabase.storage
        .from(_resultsBucket)
        .createSignedUrl(storagePath, 3600);
  }

  /// Get all try-on results for the current user.
  Future<List<Map<String, dynamic>>> getUserHistory() async {
    // Join results with jobs and garments for rich history view
    final data = await supabase
        .from(_resultsTable)
        .select('''
          *,
          tryon_jobs!inner(
            garment_id,
            created_at,
            garments(name_tr, thumbnail_path, storage_path)
          )
        ''')
        .order('created_at', ascending: false)
        .limit(50);

    return List<Map<String, dynamic>>.from(data);
  }

  /// Toggle favorite on a result.
  Future<void> toggleFavorite(String resultId, bool isFavorite) async {
    await supabase
        .from(_resultsTable)
        .update({'is_favorite': isFavorite})
        .eq('id', resultId);
  }
}
