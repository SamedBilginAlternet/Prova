import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../features/auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          children: [
            // Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _initials(user),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.base),

            Text(
              user?.email ?? '',
              style: AppTextStyles.body.copyWith(color: AppColors.onSurfaceMuted),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Settings list
            _SettingsTile(
              icon: Icons.camera_alt_outlined,
              label: 'Fotoğrafımı Değiştir',
              onTap: () => context.push(AppRoutes.uploadPhoto),
            ),
            _SettingsTile(
              icon: Icons.favorite_outline_rounded,
              label: 'Favorilerim',
              onTap: () => context.go(AppRoutes.history),
            ),
            _SettingsTile(
              icon: Icons.language_rounded,
              label: 'Dil',
              trailing: const Text('Türkçe', style: AppTextStyles.bodySmall),
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.privacy_tip_outlined,
              label: 'Gizlilik Politikası',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.info_outline_rounded,
              label: 'Hakkında',
              trailing: const Text('v1.0.0', style: AppTextStyles.bodySmall),
              onTap: () {},
            ),

            const SizedBox(height: AppSpacing.xxl),
            const Divider(),
            const SizedBox(height: AppSpacing.base),

            // Sign out
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: Text(
                'Çıkış Yap',
                style: AppTextStyles.body.copyWith(color: AppColors.error),
              ),
              onTap: () => _signOut(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(User? user) {
    if (user == null) return 'U';
    final email = user.email ?? '';
    if (email.isNotEmpty) return email[0].toUpperCase();
    return 'U';
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabınızdan çıkmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Çıkış Yap',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authRepositoryProvider).signOut();
      if (context.mounted) context.go(AppRoutes.login);
    }
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.onSurface, size: 22),
      title: Text(label, style: AppTextStyles.body),
      trailing: trailing ??
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.onSurfaceMuted, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
    );
  }
}
