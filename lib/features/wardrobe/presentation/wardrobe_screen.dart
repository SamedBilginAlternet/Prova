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
import '../models/wardrobe_item.dart';
import '../providers/wardrobe_provider.dart';

class WardrobeScreen extends ConsumerWidget {
  const WardrobeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(wardrobeItemsProvider);
    final filter = ref.watch(wardrobeFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gardırobum'),
        actions: [
          if (filter.category != null || filter.season != null || filter.occasion != null)
            TextButton(
              onPressed: () => ref.read(wardrobeFilterProvider.notifier).clear(),
              child: const Text('Temizle'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Category filter row
          _CategoryFilterRow(),
          const SizedBox(height: AppSpacing.sm),

          // Items grid
          Expanded(
            child: itemsAsync.when(
              loading: () => _WardrobeGridShimmer(),
              error: (e, _) => _ErrorState(
                onRetry: () => ref.refresh(wardrobeItemsProvider),
              ),
              data: (items) {
                if (items.isEmpty) return const _EmptyWardrobe();
                return RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: () async => ref.refresh(wardrobeItemsProvider),
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pagePadding,
                      0,
                      AppSpacing.pagePadding,
                      100, // space for FAB
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.72,
                      mainAxisSpacing: AppSpacing.sm,
                      crossAxisSpacing: AppSpacing.sm,
                    ),
                    itemCount: items.length,
                    itemBuilder: (_, i) => WardrobeItemCard(item: items[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Add item FAB
      floatingActionButton: ProvaFAB(
        icon: Icons.add_rounded,
        label: 'Kıyafet Ekle',
        onPressed: () => context.push(AppRoutes.addWardrobeItem),
      ),
    );
  }
}

class _CategoryFilterRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(wardrobeFilterProvider);
    final notifier = ref.read(wardrobeFilterProvider.notifier);

    final categories = [null, ...WardrobeCategory.values];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.pageInsets,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final isSelected = filter.category == cat?.value;
          final label = cat == null ? 'Tümü' : '${cat.emoji} ${cat.labelTr}';

          return GestureDetector(
            onTap: () => notifier.setCategory(cat?.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : AppColors.surface,
                borderRadius: AppSpacing.borderRadiusFull,
                border: Border.all(
                  color: isSelected ? AppColors.accent : AppColors.border,
                ),
              ),
              child: Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isSelected ? Colors.white : AppColors.onSurface,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class WardrobeItemCard extends ConsumerWidget {
  final WardrobeItem item;
  final bool selectable;
  final bool isSelected;
  final VoidCallback? onTap;

  const WardrobeItemCard({
    super.key,
    required this.item,
    this.selectable = false,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlAsync = ref.watch(wardrobeItemUrlProvider(item.storagePath));
    final cat = WardrobeCategory.fromValue(item.category);

    return GestureDetector(
      onTap: onTap ?? () => context.push(AppRoutes.wardrobeItemDetail, extra: item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusMd - 1),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    urlAsync.when(
                      loading: () => const ImageShimmer(borderRadius: 0),
                      error: (_, __) => Container(
                        color: AppColors.surfaceVariant,
                        child: Center(
                          child: Text(cat.emoji, style: const TextStyle(fontSize: 32)),
                        ),
                      ),
                      data: (url) => url != null
                          ? CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const ImageShimmer(borderRadius: 0),
                              errorWidget: (_, __, ___) => Container(
                                color: AppColors.surfaceVariant,
                                child: Center(
                                  child: Text(cat.emoji, style: const TextStyle(fontSize: 32)),
                                ),
                              ),
                            )
                          : Container(
                              color: AppColors.surfaceVariant,
                              child: Center(
                                child: Text(cat.emoji, style: const TextStyle(fontSize: 32)),
                              ),
                            ),
                    ),
                    if (item.isFavorite)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.favorite_rounded,
                              size: 10, color: Colors.red),
                        ),
                      ),
                    if (selectable && isSelected)
                      Container(
                        color: AppColors.accent.withOpacity(0.3),
                        child: const Center(
                          child: Icon(Icons.check_circle_rounded,
                              color: Colors.white, size: 28),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Label
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name ?? cat.labelTr,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.color != null)
                    Text(
                      item.color!,
                      style: AppTextStyles.caption.copyWith(fontSize: 9),
                      maxLines: 1,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WardrobeGridShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: AppSpacing.pageInsetsWithBottom,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.72,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
      ),
      itemCount: 9,
      itemBuilder: (_, __) => const ImageShimmer(borderRadius: AppSpacing.radiusMd),
    );
  }
}

class _EmptyWardrobe extends StatelessWidget {
  const _EmptyWardrobe();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.pageInsets,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.accentSurface,
                shape: BoxShape.circle,
              ),
              child: const Text('👗', style: TextStyle(fontSize: 48)),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text('Gardırobun boş', style: AppTextStyles.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Sahip olduğun kıyafetleri ekle.\nStilisti n sana özel kombinler önersin.',
              style: AppTextStyles.body.copyWith(color: AppColors.onSurfaceMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            GestureDetector(
              onTap: () => context.push(AppRoutes.addWardrobeItem),
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
                  'İlk Kıyafeti Ekle',
                  style: AppTextStyles.label.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
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
          const Text('Gardırop yüklenemedi'),
          const SizedBox(height: AppSpacing.base),
          TextButton(onPressed: onRetry, child: const Text('Tekrar Dene')),
        ],
      ),
    );
  }
}
