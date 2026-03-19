import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/prova_button.dart';
import '../data/tryon_repository.dart';
import '../models/tryon_job.dart';
import '../providers/tryon_provider.dart';

class TryonResultScreen extends ConsumerStatefulWidget {
  final String resultId;

  const TryonResultScreen({super.key, required this.resultId});

  @override
  ConsumerState<TryonResultScreen> createState() => _TryonResultScreenState();
}

class _TryonResultScreenState extends ConsumerState<TryonResultScreen> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    // We need to fetch result by ID — for MVP we load from history context
    // or refetch. In production, add a getResultById repo method.
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ProvaIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    iconColor: Colors.white,
                    onPressed: () => context.go(AppRoutes.home),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: AppSpacing.borderRadiusFull,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'AI Önizleme',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ProvaIconButton(
                    icon: _isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    iconColor: _isFavorite ? Colors.red : Colors.white,
                    onPressed: _toggleFavorite,
                  ),
                ],
              ),
            ),

            // Result image — full screen
            Expanded(
              child: _ResultImage(resultId: widget.resultId)
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(
                    begin: const Offset(0.96, 0.96),
                    duration: 600.ms,
                    curve: Curves.easeOut,
                  ),
            ),

            // Bottom action bar
            Container(
              padding: const EdgeInsets.all(AppSpacing.base),
              color: Colors.black,
              child: Column(
                children: [
                  // Disclaimer
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: AppSpacing.borderRadiusMd,
                    ),
                    child: Text(
                      'Bu görsel bir AI önizlemesidir. Gerçek kıyafet görünümü farklılık gösterebilir.',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Actions row
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.go(AppRoutes.garmentBrowser),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppSpacing.borderRadiusMd,
                            ),
                          ),
                          icon: const Icon(Icons.checkroom_outlined, size: 18),
                          label: const Text('Başka Kıyafet Dene'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      ProvaIconButton(
                        icon: Icons.share_rounded,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        iconColor: Colors.white,
                        size: 50,
                        onPressed: _share,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleFavorite() async {
    setState(() => _isFavorite = !_isFavorite);
    try {
      await ref.read(tryonRepositoryProvider).toggleFavorite(
            widget.resultId,
            _isFavorite,
          );
    } catch (_) {
      setState(() => _isFavorite = !_isFavorite); // revert
    }
  }

  void _share() {
    // TODO: implement share_plus integration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Paylaşım yakında geliyor!')),
    );
  }
}

class _ResultImage extends ConsumerWidget {
  final String resultId;

  const _ResultImage({required this.resultId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch the result record to get storage_path
    // In MVP we pass storage_path directly or look up by ID
    // For now, show placeholder — in production hook up properly
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_outlined, color: Colors.white30, size: 64),
            const SizedBox(height: 16),
            Text(
              'Sonuç yükleniyor...',
              style: AppTextStyles.body.copyWith(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}

