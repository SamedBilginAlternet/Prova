import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../features/tryon/data/tryon_repository.dart';
import '../../../features/tryon/providers/tryon_provider.dart';
import '../../../shared/widgets/image_shimmer.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(tryonHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Denemelerim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () => _HistoryShimmer(),
        error: (e, _) => _ErrorState(onRetry: () => ref.refresh(tryonHistoryProvider)),
        data: (history) {
          if (history.isEmpty) {
            return const _EmptyState();
          }
          return RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () async => ref.refresh(tryonHistoryProvider),
            child: GridView.builder(
              padding: AppSpacing.pageInsetsWithBottom,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
              ),
              itemCount: history.length,
              itemBuilder: (context, i) =>
                  _HistoryResultCard(result: history[i]),
            ),
          );
        },
      ),
    );
  }
}

class _HistoryResultCard extends ConsumerWidget {
  final Map<String, dynamic> result;

  const _HistoryResultCard({required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storagePath = result['storage_path'] as String;
    final isFavorite = result['is_favorite'] as bool? ?? false;
    final resultId = result['id'] as String;

    // Get signed URL for private bucket
    final urlAsync = ref.watch(tryonResultUrlProvider(storagePath));

    // Garment info from joined data
    final job = result['tryon_jobs'] as Map<String, dynamic>?;
    final garment = job?['garments'] as Map<String, dynamic>?;
    final garmentName = garment?['name_tr'] as String? ?? '';

    return GestureDetector(
      onTap: () => context.go(AppRoutes.tryonResult, extra: {'resultId': resultId}),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.borderRadiusLg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: urlAsync.when(
                loading: () => ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusLg),
                  ),
                  child: const ResultCardShimmer(),
                ),
                error: (_, __) => const Center(
                  child: Icon(Icons.broken_image_outlined, color: AppColors.onSurfaceMuted),
                ),
                data: (url) => url == null
                    ? const Center(child: Icon(Icons.image_outlined))
                    : ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppSpacing.radiusLg),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                            ),
                            if (isFavorite)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.favorite_rounded,
                                    size: 14,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    garmentName,
                    style: AppTextStyles.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _formatDate(result['created_at'] as String?),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return '';
    return '${dt.day}.${dt.month}.${dt.year}';
  }
}

class _HistoryShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: AppSpacing.pageInsetsWithBottom,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const ResultCardShimmer(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.accentSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.photo_library_outlined,
              size: 48,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Henüz deneme yok',
            style: AppTextStyles.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Bir kıyafet seç ve nasıl durduğunu gör!',
            style: AppTextStyles.body.copyWith(color: AppColors.onSurfaceMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          GestureDetector(
            onTap: () => context.go(AppRoutes.home),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: Text(
                'Keşfetmeye Başla',
                style: AppTextStyles.label.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.onSurfaceMuted),
          const SizedBox(height: AppSpacing.base),
          const Text('Geçmiş yüklenemedi'),
          const SizedBox(height: AppSpacing.base),
          TextButton(onPressed: onRetry, child: const Text('Tekrar Dene')),
        ],
      ),
    );
  }
}
