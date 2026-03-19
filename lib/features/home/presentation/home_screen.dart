import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/garments/data/garment_repository.dart';
import '../../../features/garments/models/garment.dart';
import '../../../features/garments/providers/garments_provider.dart';
import '../../../features/photo/providers/photo_provider.dart';
import '../../../shared/widgets/image_shimmer.dart';
import '../../../shared/widgets/prova_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final activePhotoAsync = ref.watch(activeUserPhotoProvider);
    final garmentsAsync = ref.watch(garmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.background,
            title: const Text(
              'PROVA',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                color: AppColors.onSurface,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: () {},
              ),
              const SizedBox(width: 4),
            ],
          ),

          // Photo upload banner (if no photo yet)
          SliverToBoxAdapter(
            child: activePhotoAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (photo) {
                if (photo == null) {
                  return _UploadPhotoBanner();
                }
                return _PhotoReadyBanner();
              },
            ),
          ),

          // Section: Featured garments
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.xl,
                AppSpacing.pagePadding,
                AppSpacing.base,
              ),
              child: _SectionHeader(
                title: 'Yeni Gelenler',
                subtitle: 'Bu sezon öne çıkan parçalar',
              ),
            ),
          ),

          // Category filter chips
          SliverToBoxAdapter(
            child: _CategoryFilterRow(),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

          // Garment grid
          garmentsAsync.when(
            loading: () => SliverPadding(
              padding: AppSpacing.pageInsetsWithBottom,
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => const GarmentCardShimmer(),
                  childCount: 6,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                ),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.onSurfaceMuted),
                      const SizedBox(height: AppSpacing.base),
                      const Text('Kıyafetler yüklenemedi'),
                      const SizedBox(height: AppSpacing.base),
                      TextButton(
                        onPressed: () => ref.refresh(garmentsProvider),
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            data: (garments) {
              if (garments.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xxl),
                      child: Text('Henüz kıyafet eklenmedi'),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: AppSpacing.pageInsetsWithBottom,
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _HomeGarmentCard(garment: garments[i]),
                    childCount: garments.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _UploadPhotoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.sm,
        AppSpacing.pagePadding,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC8A96E), Color(0xFFE8C98A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppSpacing.borderRadiusLg,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fotoğrafını Yükle',
                  style: AppTextStyles.title.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kıyafetleri sende görmek için önce bir fotoğraf ekle.',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.uploadPhoto),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppSpacing.borderRadiusMd,
                    ),
                    child: Text(
                      'Fotoğraf Ekle',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.accentDark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.base),
          const Icon(
            Icons.person_add_alt_1_rounded,
            size: 56,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _PhotoReadyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.sm,
        AppSpacing.pagePadding,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentSurface,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.accentLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: AppColors.accent, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Fotoğrafın hazır! Bir kıyafet seçip deneye başla.',
              style: AppTextStyles.caption.copyWith(color: AppColors.accentDark),
            ),
          ),
          GestureDetector(
            onTap: () => context.push(AppRoutes.uploadPhoto),
            child: Text(
              'Değiştir',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.accent,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.headlineSmall),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: AppTextStyles.caption,
          ),
        ],
      ],
    );
  }
}

class _CategoryFilterRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCategoryProvider);

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.pageInsets,
        itemCount: GarmentCategory.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final cat = GarmentCategory.values[i];
          final isSelected = cat == selected;
          return GestureDetector(
            onTap: () => ref.read(selectedCategoryProvider.notifier).select(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
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
                cat.labelTr,
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

class _HomeGarmentCard extends ConsumerWidget {
  final Garment garment;

  const _HomeGarmentCard({required this.garment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(garmentRepositoryProvider);
    final thumbUrl = repo.getGarmentThumbnailUrl(
      garment.thumbnailPath,
      garment.storagePath,
    );

    return GestureDetector(
      onTap: () {
        ref.read(selectedGarmentProvider.notifier).select(garment);
        context.push(AppRoutes.garmentBrowser);
      },
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
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusLg),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: thumbUrl,
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
                    // Try-on CTA overlay
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: AppSpacing.borderRadiusFull,
                        ),
                        child: Text(
                          'Dene',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                  if (garment.brand != null)
                    Text(garment.brand!, style: AppTextStyles.caption, maxLines: 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
