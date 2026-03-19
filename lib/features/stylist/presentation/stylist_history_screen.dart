import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../models/stylist_models.dart';
import '../providers/stylist_provider.dart';

class StylistHistoryScreen extends ConsumerWidget {
  const StylistHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(stylistSessionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Stilist Geçmişi')),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Yüklenemedi')),
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded,
                      size: 48, color: AppColors.onSurfaceMuted),
                  const SizedBox(height: AppSpacing.base),
                  const Text('Henüz konuşma yok'),
                  const SizedBox(height: AppSpacing.base),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Stiliste Sor'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: AppSpacing.pageInsetsWithBottom,
            itemCount: sessions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) => _SessionTile(session: sessions[i]),
          );
        },
      ),
    );
  }
}

class _SessionTile extends ConsumerWidget {
  final StylistSession session;

  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.accentSurface,
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        child: const Icon(Icons.chat_rounded, color: AppColors.accent, size: 22),
      ),
      title: Text(
        session.title ?? 'Konuşma',
        style: AppTextStyles.titleMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _formatDate(session.updatedAt),
        style: AppTextStyles.caption,
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.onSurfaceMuted),
      onTap: () => context.push(
        AppRoutes.stylist,
        extra: {'existingSessionId': session.id},
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Bugün';
    if (diff.inDays == 1) return 'Dün';
    return '${dt.day}.${dt.month}.${dt.year}';
  }
}
