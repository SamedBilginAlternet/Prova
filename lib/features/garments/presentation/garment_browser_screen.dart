import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/image_shimmer.dart';
import '../../../shared/widgets/prova_button.dart';
import '../data/garment_repository.dart';
import '../models/garment.dart';
import '../providers/garments_provider.dart';

class GarmentBrowserScreen extends ConsumerWidget {
  const GarmentBrowserScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final garmentsAsync = ref.watch(garmentsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedGarment = ref.watch(selectedGarmentProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kıyafet Seç'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Category filter chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: AppSpacing.pageInsets,
              itemCount: GarmentCategory.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, i) {
                final cat = GarmentCategory.values[i];
                final isSelected = cat == selectedCategory;
                return FilterChip(
                  label: Text(cat.labelTr),
                  selected: isSelected,
                  onSelected: (_) =>
                      ref.read(selectedCategoryProvider.notifier).select(cat),
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.accentSurface,
                  checkmarkColor: AppColors.accent,
                  labelStyle: AppTextStyles.labelSmall.copyWith(
                    color: isSelected ? AppColors.accent : AppColors.onSurface,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.accent : AppColors.border,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.base),

          // Garment grid
          Expanded(
            child: garmentsAsync.when(
              loading: () => _GarmentGridShimmer(),
              error: (e, _) => _ErrorState(onRetry: () => ref.refresh(garmentsProvider)),
              data: (garments) {
                if (garments.isEmpty) {
                  return const _EmptyState();
                }
                return GridView.builder(
                  padding: AppSpacing.pageInsetsWithBottom,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                  ),
                  itemCount: garments.length,
                  itemBuilder: (context, i) {
                    final garment = garments[i];
                    final isSelected = selectedGarment?.id == garment.id;
                    return GarmentCard(
                      garment: garment,
                      isSelected: isSelected,
                      onTap: () {
                        ref.read(selectedGarmentProvider.notifier).select(garment);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // Bottom CTA — active when a garment is selected
      bottomNavigationBar: selectedGarment != null
          ? SafeArea(
              child: Padding(
                padding: AppSpacing.pageInsetsWithBottom,
                child: ProvaButton(
                  label: '"${selectedGarment.nameTr}" ile Dene',
                  onPressed: () => context.go(
                    AppRoutes.tryonLoading,
                    extra: {'garmentId': selectedGarment.id},
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class GarmentCard extends ConsumerWidget {
  final Garment garment;
  final bool isSelected;
  final VoidCallback onTap;

  const GarmentCard({
    super.key,
    required this.garment,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(garmentRepositoryProvider);
    final thumbUrl = repo.getGarmentThumbnailUrl(
      garment.thumbnailPath,
      garment.storagePath,
    );

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.accent.withOpacity(0.15)
                  : Colors.black.withOpacity(0.04),
              blurRadius: isSelected ? 16 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSpacing.radiusLg - 1),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: thumbUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const GarmentCardShimmer(),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.surfaceVariant,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.onSurfaceMuted,
                        ),
                      ),
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: AppSpacing.borderRadiusFull,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    garment.nameTr,
                    style: AppTextStyles.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (garment.brand != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      garment.brand!,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GarmentGridShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: AppSpacing.pageInsetsWithBottom,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const GarmentCardShimmer(),
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
          const Icon(
            Icons.checkroom_outlined,
            size: 64,
            color: AppColors.onSurfaceMuted,
          ),
          const SizedBox(height: AppSpacing.base),
          Text(
            'Bu kategoride kıyafet bulunamadı',
            style: AppTextStyles.body.copyWith(color: AppColors.onSurfaceMuted),
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
          const Text('Kıyafetler yüklenemedi'),
          const SizedBox(height: AppSpacing.base),
          TextButton(onPressed: onRetry, child: const Text('Tekrar Dene')),
        ],
      ),
    );
  }
}
