import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/prova_button.dart';
import '../models/tryon_job.dart';
import '../providers/tryon_provider.dart';

class TryonLoadingScreen extends ConsumerStatefulWidget {
  final String jobId;

  const TryonLoadingScreen({super.key, required this.jobId});

  @override
  ConsumerState<TryonLoadingScreen> createState() => _TryonLoadingScreenState();
}

class _TryonLoadingScreenState extends ConsumerState<TryonLoadingScreen> {
  static const _messages = [
    'Fotoğrafın analiz ediliyor...',
    'Kıyafet yerleştiriliyor...',
    'Detaylar iyileştiriliyor...',
    'Neredeyse hazır...',
    'Son rötuşlar yapılıyor...',
  ];

  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();
    _startMessageCycle();
  }

  void _startMessageCycle() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() {
        _messageIndex = (_messageIndex + 1) % _messages.length;
      });
      _startMessageCycle();
    });
  }

  @override
  Widget build(BuildContext context) {
    final jobStream = ref.watch(tryonJobStreamProvider(widget.jobId));

    jobStream.whenData((job) {
      if (job.status == TryonJobStatus.completed) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          // Fetch the result ID then navigate
          final result = await ref.read(
            tryonResultByJobProvider(widget.jobId).future,
          );
          if (result != null && mounted) {
            context.go(AppRoutes.tryonResult, extra: {'resultId': result.id});
          }
        });
      } else if (job.status == TryonJobStatus.failed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _showErrorDialog(job.errorMsg ?? 'Bilinmeyen hata');
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pageInsets,
          child: Column(
            children: [
              // Cancel button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.home),
                  child: Text(
                    'İptal',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.onSurfaceMuted,
                    ),
                  ),
                ),
              ),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated brand icon
                    _PulsingLogo()
                        .animate(onPlay: (c) => c.repeat())
                        .scale(
                          begin: const Offset(0.95, 0.95),
                          end: const Offset(1.05, 1.05),
                          duration: 1200.ms,
                          curve: Curves.easeInOut,
                        )
                        .then()
                        .scale(
                          begin: const Offset(1.05, 1.05),
                          end: const Offset(0.95, 0.95),
                          duration: 1200.ms,
                          curve: Curves.easeInOut,
                        ),

                    const SizedBox(height: AppSpacing.xxxl),

                    Text(
                      'Giydiriliyor...',
                      style: AppTextStyles.headline,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.base),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      child: Text(
                        _messages[_messageIndex],
                        key: ValueKey(_messageIndex),
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.onSurfaceMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Shimmer progress bar
                    ClipRRect(
                      borderRadius: AppSpacing.borderRadiusFull,
                      child: const LinearProgressIndicator(
                        backgroundColor: AppColors.divider,
                        valueColor: AlwaysStoppedAnimation(AppColors.accent),
                        minHeight: 3,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Disclaimer
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.accentSurface,
                        borderRadius: AppSpacing.borderRadiusMd,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome_outlined,
                            size: 16,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'AI önizleme üretiyor. Sonuç gerçek kıyafet görünümünden farklılık gösterebilir.',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.accentDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Estimated time note
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                child: Text(
                  'Bu işlem 20-60 saniye sürebilir',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusLg),
        title: const Text('Deneme Başarısız'),
        content: Text('Kıyafet deneme işlemi tamamlanamadı. $message'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go(AppRoutes.garmentBrowser);
            },
            child: const Text('Tekrar Dene'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go(AppRoutes.home);
            },
            child: const Text('Ana Sayfa'),
          ),
        ],
      ),
    );
  }
}

class _PulsingLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.4),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Icon(Icons.checkroom_rounded, color: Colors.white, size: 56),
    );
  }
}
