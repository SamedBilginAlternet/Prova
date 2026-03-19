import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/prova_button.dart';
import '../models/wardrobe_item.dart';
import '../data/wardrobe_repository.dart';
import '../providers/wardrobe_provider.dart';

class WardrobeItemDetailScreen extends ConsumerStatefulWidget {
  final WardrobeItem item;

  const WardrobeItemDetailScreen({super.key, required this.item});

  @override
  ConsumerState<WardrobeItemDetailScreen> createState() =>
      _WardrobeItemDetailScreenState();
}

class _WardrobeItemDetailScreenState
    extends ConsumerState<WardrobeItemDetailScreen> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.item.isFavorite;
  }

  @override
  Widget build(BuildContext context) {
    final cat = WardrobeCategory.fromValue(widget.item.category);
    final urlAsync = ref.watch(wardrobeItemUrlProvider(widget.item.storagePath));

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
                  _DarkIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => context.pop(),
                  ),
                  Text(
                    widget.item.name ?? cat.labelTr,
                    style: AppTextStyles.title.copyWith(color: Colors.white),
                  ),
                  _DarkIconButton(
                    icon: _isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    iconColor: _isFavorite ? Colors.red : Colors.white,
                    onTap: _toggleFavorite,
                  ),
                ],
              ),
            ),

            // Image
            Expanded(
              child: urlAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator(color: Colors.white)),
                error: (_, __) => Center(
                  child: Text(cat.emoji, style: const TextStyle(fontSize: 80)),
                ),
                data: (url) => url != null
                    ? CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.contain,
                        width: double.infinity,
                      )
                    : Center(
                        child: Text(cat.emoji, style: const TextStyle(fontSize: 80)),
                      ),
              ),
            ),

            // Bottom info panel
            Container(
              padding: const EdgeInsets.all(AppSpacing.base),
              color: Colors.black,
              child: Column(
                children: [
                  // Tags row
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      if (widget.item.color != null)
                        _InfoChip(widget.item.color!),
                      if (widget.item.season != null)
                        _InfoChip(WardrobeSeason.values
                            .firstWhere((s) => s.value == widget.item.season,
                                orElse: () => WardrobeSeason.all)
                            .labelTr),
                      if (widget.item.occasion != null)
                        _InfoChip(WardrobeOccasion.values
                            .firstWhere((o) => o.value == widget.item.occasion,
                                orElse: () => WardrobeOccasion.all)
                            .labelTr),
                      if (widget.item.brand != null)
                        _InfoChip(widget.item.brand!),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.base),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.push(
                            AppRoutes.stylist,
                            extra: {
                              'initialMessage':
                                  '"${widget.item.name ?? cat.labelTr}" ile ne giyebilirim?',
                              'contextItemId': widget.item.id,
                            },
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                                borderRadius: AppSpacing.borderRadiusMd),
                          ),
                          icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                          label: const Text('Stilist\'e Sor'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _DarkIconButton(
                        icon: Icons.delete_outline_rounded,
                        iconColor: Colors.red.shade300,
                        onTap: () => _confirmDelete(context),
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
    await ref
        .read(wardrobeRepositoryProvider)
        .toggleFavorite(widget.item.id, _isFavorite);
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
        title: const Text('Kıyafeti Sil'),
        content: const Text('Bu kıyafeti gardırobundan silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final deleted = await ref
                  .read(wardrobeDeleteProvider.notifier)
                  .delete(widget.item);
              if (deleted && context.mounted) context.pop();
            },
            child: const Text('Sil', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _DarkIconButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;

  const _DarkIconButton(
      {required this.icon, this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        child: Icon(icon, color: iconColor ?? Colors.white, size: 20),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: AppSpacing.borderRadiusFull,
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: Colors.white),
      ),
    );
  }
}
