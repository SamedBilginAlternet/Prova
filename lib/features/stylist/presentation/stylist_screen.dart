import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../models/stylist_models.dart';
import '../providers/stylist_provider.dart';
import 'widgets/assistant_message_bubble.dart';
import 'widgets/user_message_bubble.dart';

class StylistScreen extends ConsumerStatefulWidget {
  final String? existingSessionId;
  final String? initialMessage;

  const StylistScreen({
    super.key,
    this.existingSessionId,
    this.initialMessage,
  });

  @override
  ConsumerState<StylistScreen> createState() => _StylistScreenState();
}

class _StylistScreenState extends ConsumerState<StylistScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _initialized = false;

  static const _quickPrompts = [
    'Bugün ne giysem?',
    'Gardırobumu analiz et',
    'Casual kombin öner',
    'İş toplantısı için kombin',
    'Eksik kıyafetlerimi söyle',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;
    await ref.read(stylistChatProvider.notifier).initSession(
          existingSessionId: widget.existingSessionId,
          initialMessage: widget.initialMessage,
        );
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _inputCtrl.clear();
    ref.read(stylistChatProvider.notifier).sendMessage(trimmed);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(stylistChatProvider);
    final user = ref.watch(currentUserProvider);

    final messages = switch (chatState) {
      StylistChatIdle s => s.messages,
      StylistChatSending s => s.messages,
      StylistChatError s => s.messages,
      _ => <StylistMessage>[],
    };

    final isSending = chatState is StylistChatSending;
    final hasError = chatState is StylistChatError;

    // Auto-scroll when messages change
    ref.listen(stylistChatProvider, (_, __) => _scrollToBottom());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Stilist'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => context.push(AppRoutes.stylistHistory),
          ),
        ],
      ),
      body: Column(
        children: [
          // Message list
          Expanded(
            child: messages.isEmpty && !isSending
                ? _EmptyState(
                    onPromptTap: _sendMessage,
                    quickPrompts: _quickPrompts,
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pagePadding,
                      AppSpacing.base,
                      AppSpacing.pagePadding,
                      AppSpacing.base,
                    ),
                    itemCount: messages.length + (isSending ? 1 : 0),
                    itemBuilder: (context, i) {
                      // Typing indicator
                      if (i == messages.length && isSending) {
                        return const _TypingIndicator();
                      }

                      final msg = messages[i];
                      if (msg.role == 'user') {
                        return UserMessageBubble(message: msg);
                      } else {
                        return AssistantMessageBubble(
                          message: msg,
                          onSaveOutfit: user == null
                              ? null
                              : (suggestion) async {
                                  final chatNotifier = ref.read(
                                    stylistChatProvider.notifier,
                                  );
                                  final sessionId =
                                      (chatState as StylistChatIdle).sessionId;
                                  final saved = await chatNotifier.saveOutfit(
                                    suggestion: suggestion,
                                    userId: user.id,
                                    sessionId: sessionId,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          saved
                                              ? '"${suggestion.name}" kaydedildi!'
                                              : 'Kaydedilemedi',
                                        ),
                                      ),
                                    );
                                  }
                                },
                          onTryOn: (itemId) => context.push(
                            AppRoutes.garmentBrowser,
                          ),
                        );
                      }
                    },
                  ),
          ),

          // Error banner
          if (hasError)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.errorSurface,
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      (chatState as StylistChatError).error,
                      style: AppTextStyles.caption.copyWith(color: AppColors.error),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _sendMessage(_inputCtrl.text),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            ),

          if (hasError) const SizedBox(height: AppSpacing.sm),

          // Quick prompts (show when no messages yet)
          if (messages.isEmpty && !isSending)
            _QuickPrompts(
              prompts: _quickPrompts,
              onTap: _sendMessage,
            ),

          // Input bar
          _ChatInputBar(
            controller: _inputCtrl,
            isSending: isSending,
            onSend: () => _sendMessage(_inputCtrl.text),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final List<String> quickPrompts;
  final ValueChanged<String> onPromptTap;

  const _EmptyState({required this.quickPrompts, required this.onPromptTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.pageInsets,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text('Stilistine Sor', style: AppTextStyles.headline),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Gardırobuna bakarak sana özel kombin önerileri hazırlarım.',
              style: AppTextStyles.body.copyWith(color: AppColors.onSurfaceMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickPrompts extends StatelessWidget {
  final List<String> prompts;
  final ValueChanged<String> onTap;

  const _QuickPrompts({required this.prompts, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.pageInsets,
        itemCount: prompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => onTap(prompts[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.accentSurface,
              borderRadius: AppSpacing.borderRadiusFull,
              border: Border.all(color: AppColors.accentLight),
            ),
            child: Text(
              prompts[i],
              style: AppTextStyles.caption.copyWith(color: AppColors.accentDark),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _ChatInputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.sm,
        AppSpacing.pagePadding,
        AppSpacing.pagePadding +
            MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isSending,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              maxLines: 4,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Stilistine bir şey sor...',
                filled: true,
                fillColor: AppColors.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base,
                  vertical: AppSpacing.md,
                ),
                border: OutlineInputBorder(
                  borderRadius: AppSpacing.borderRadiusLg,
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppSpacing.borderRadiusLg,
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: isSending ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSending ? AppColors.divider : AppColors.accent,
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.base),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: AppSpacing.borderRadiusFull,
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(AppSpacing.radiusLg),
                bottomLeft: Radius.circular(AppSpacing.radiusLg),
                bottomRight: Radius.circular(AppSpacing.radiusLg),
              ),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(delay: 0.ms),
                const SizedBox(width: 4),
                _Dot(delay: 150.ms),
                const SizedBox(width: 4),
                _Dot(delay: 300.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Duration delay;
  const _Dot({required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true), delay: delay)
        .scaleXY(end: 0.5, duration: 600.ms, curve: Curves.easeInOut);
  }
}
