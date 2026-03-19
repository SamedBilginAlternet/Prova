import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/prova_button.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      if (_isLogin) {
        await repo.signInWithEmail(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
      } else {
        await repo.signUpWithEmail(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
      }
      if (mounted) context.go(AppRoutes.home);
    } on AuthException catch (e) {
      setState(() => _errorMessage = _mapError(e.message));
    } catch (_) {
      setState(() => _errorMessage = 'Bir hata oluştu. Lütfen tekrar deneyin.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'E-posta veya şifre hatalı.';
    }
    if (message.contains('Email not confirmed')) {
      return 'E-posta adresinizi doğrulayın.';
    }
    if (message.contains('User already registered')) {
      return 'Bu e-posta zaten kayıtlı. Giriş yapın.';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
            vertical: AppSpacing.xl,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xxl),

                // Brand
                const _BrandHeader(),
                const SizedBox(height: AppSpacing.xxxl),

                // Tab switcher
                _AuthTabSwitcher(
                  isLogin: _isLogin,
                  onSwitch: (v) => setState(() {
                    _isLogin = v;
                    _errorMessage = null;
                  }),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'E-posta adresiniz',
                    prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'E-posta gerekli';
                    if (!v.contains('@')) return 'Geçerli bir e-posta girin';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Password
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: 'Şifreniz',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: AppColors.onSurfaceMuted,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Şifre gerekli';
                    if (!_isLogin && v.length < 6) {
                      return 'En az 6 karakter olmalı';
                    }
                    return null;
                  },
                ),

                // Forgot password (login only)
                if (_isLogin) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _showForgotPasswordDialog(),
                      child: Text(
                        'Şifremi Unuttum',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                ] else
                  const SizedBox(height: AppSpacing.base),

                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.errorSurface,
                      borderRadius: AppSpacing.borderRadiusMd,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.base),
                ],

                // Submit button
                ProvaButton(
                  label: _isLogin ? 'Giriş Yap' : 'Hesap Oluştur',
                  onPressed: _submit,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: AppSpacing.base),

                // Divider
                const _OrDivider(),
                const SizedBox(height: AppSpacing.base),

                // Google sign in
                ProvaButton.outlined(
                  label: 'Google ile Devam Et',
                  onPressed: () async {
                    try {
                      await ref.read(authRepositoryProvider).signInWithGoogle();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Google girişi başarısız')),
                        );
                      }
                    }
                  },
                  icon: Icons.g_mobiledata_rounded,
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Terms (for register)
                if (!_isLogin)
                  Text(
                    'Hesap oluşturarak Kullanım Koşulları ve Gizlilik Politikası\'nı kabul etmiş olursunuz.',
                    style: AppTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailCtrl = TextEditingController(text: _emailCtrl.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
        title: const Text('Şifre Sıfırla'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('E-posta adresinize şifre sıfırlama bağlantısı göndereceğiz.'),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(hintText: 'E-posta adresiniz'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(authRepositoryProvider)
                  .resetPassword(emailCtrl.text.trim());
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sıfırlama bağlantısı gönderildi'),
                  ),
                );
              }
            },
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.checkroom_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(height: AppSpacing.base),
        const Text('PROVA', style: AppTextStyles.display),
        Text(
          'Giymeden önce gör.',
          style: AppTextStyles.body.copyWith(color: AppColors.onSurfaceMuted),
        ),
      ],
    );
  }
}

class _AuthTabSwitcher extends StatelessWidget {
  final bool isLogin;
  final ValueChanged<bool> onSwitch;

  const _AuthTabSwitcher({required this.isLogin, required this.onSwitch});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Row(
        children: [
          _Tab(label: 'Giriş', isSelected: isLogin, onTap: () => onSwitch(true)),
          _Tab(label: 'Kayıt Ol', isSelected: !isLogin, onTap: () => onSwitch(false)),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Tab({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent,
            borderRadius: AppSpacing.borderRadiusSm,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.titleMedium.copyWith(
                color: isSelected ? AppColors.onSurface : AppColors.onSurfaceMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'veya',
            style: AppTextStyles.caption,
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
