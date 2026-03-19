import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../models/stylist_models.dart';

/// Renders an AI assistant message.
/// For structured responses (outfit suggestions, ratings), renders rich UI cards.
/// Falls back to plain text for general messages.
class AssistantMessageBubble extends StatelessWidget {
  final StylistMessage message;
  final void Function(OutfitSuggestion)? onSaveOutfit;
  final void Function(String itemId)? onTryOn;

  const AssistantMessageBubble({
    super.key,
    required this.message,
    this.onSaveOutfit,
    this.onTryOn,
  });

  @override
  Widget build(BuildContext context) {
    final parsed = message.parsedResponse;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.base),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stylist avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),

          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text bubble
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
                  child: Text(
                    message.content,
                    style: AppTextStyles.body,
                  ),
                ),

                // Structured content cards
                if (parsed != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _StructuredContent(
                    response: parsed,
                    onSaveOutfit: onSaveOutfit,
                    onTryOn: onTryOn,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.05, duration: 300.ms, curve: Curves.easeOut);
  }
}

class _StructuredContent extends StatelessWidget {
  final StylistResponse response;
  final void Function(OutfitSuggestion)? onSaveOutfit;
  final void Function(String)? onTryOn;

  const _StructuredContent({
    required this.response,
    this.onSaveOutfit,
    this.onTryOn,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Outfit suggestion cards
        if (response.outfitSuggestions.isNotEmpty)
          ...response.outfitSuggestions
              .map((s) => OutfitSuggestionCard(
                    suggestion: s,
                    onSave: onSaveOutfit != null ? () => onSaveOutfit!(s) : null,
                    onTryOn: onTryOn,
                  ))
              .toList(),

        // Style tips
        if (response.styleTips.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _StyleTipsCard(tips: response.styleTips),
        ],

        // Outfit rating
        if (response.rating != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _RatingCard(rating: response.rating!),
        ],

        // Missing items
        if (response.missingItems.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _MissingItemsCard(items: response.missingItems),
        ],

        // Follow-up questions
        if (response.followUpQuestions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _FollowUpChips(questions: response.followUpQuestions),
        ],
      ],
    );
  }
}

class OutfitSuggestionCard extends StatefulWidget {
  final OutfitSuggestion suggestion;
  final VoidCallback? onSave;
  final void Function(String)? onTryOn;

  const OutfitSuggestionCard({
    super.key,
    required this.suggestion,
    this.onSave,
    this.onTryOn,
  });

  @override
  State<OutfitSuggestionCard> createState() => _OutfitSuggestionCardState();
}

class _OutfitSuggestionCardState extends State<OutfitSuggestionCard> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.accentSurface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.accentLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.checkroom_outlined,
                  size: 16, color: AppColors.accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(widget.suggestion.name,
                    style: AppTextStyles.title.copyWith(color: AppColors.accentDark)),
              ),
              // Confidence badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: AppSpacing.borderRadiusFull,
                ),
                child: Text(
                  '${(widget.suggestion.confidence * 100).round()}% uyum',
                  style: AppTextStyles.caption.copyWith(color: AppColors.accent),
                ),
              ),
            ],
          ),

          // Reasoning
          if (widget.suggestion.reasoning != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.suggestion.reasoning!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.accentDark),
            ),
          ],

          // Items used (show count)
          if (widget.suggestion.itemIds.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined,
                    size: 14, color: AppColors.onSurfaceMuted),
                const SizedBox(width: 4),
                Text(
                  '${widget.suggestion.itemIds.length} gardırop parçası kullanıldı',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ],

          // Missing items
          if (widget.suggestion.missingItems.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.add_shopping_cart_outlined,
                    size: 14, color: AppColors.warning),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Eksik: ${widget.suggestion.missingItems.join(", ")}',
                    style: AppTextStyles.caption.copyWith(color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          // Action buttons
          Row(
            children: [
              if (widget.onSave != null)
                Expanded(
                  child: GestureDetector(
                    onTap: _saved
                        ? null
                        : () {
                            setState(() => _saved = true);
                            widget.onSave!();
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _saved ? AppColors.success : AppColors.accent,
                        borderRadius: AppSpacing.borderRadiusMd,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _saved ? Icons.check_rounded : Icons.bookmark_add_outlined,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _saved ? 'Kaydedildi' : 'Kombini Kaydet',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StyleTipsCard extends StatelessWidget {
  final List<String> tips;

  const _StyleTipsCard({required this.tips});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tips_and_updates_outlined,
                  size: 16, color: AppColors.accent),
              const SizedBox(width: AppSpacing.sm),
              Text('Stil Önerileri',
                  style: AppTextStyles.titleMedium.copyWith(color: AppColors.accent)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ',
                      style: TextStyle(color: AppColors.accent, fontSize: 14)),
                  Expanded(child: Text(tip, style: AppTextStyles.bodySmall)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  final OutfitRating rating;

  const _RatingCard({required this.rating});

  @override
  Widget build(BuildContext context) {
    final color = rating.score >= 8
        ? AppColors.success
        : rating.score >= 5
            ? AppColors.warning
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
              const SizedBox(width: AppSpacing.sm),
              Text('Kombin Değerlendirmesi',
                  style: AppTextStyles.titleMedium),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: AppSpacing.borderRadiusFull,
                ),
                child: Text(
                  '${rating.score}/10',
                  style: AppTextStyles.label.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          if (rating.summary != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(rating.summary!, style: AppTextStyles.bodySmall),
          ],
          if (rating.improvements.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('Geliştirebilirsin:',
                style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
            ...rating.improvements.map(
              (i) => Text('• $i',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.onSurfaceMuted)),
            ),
          ],
        ],
      ),
    );
  }
}

class _MissingItemsCard extends StatelessWidget {
  final List<String> items;

  const _MissingItemsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppSpacing.borderRadiusLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.add_shopping_cart_outlined,
                  size: 16, color: AppColors.onSurfaceMuted),
              const SizedBox(width: AppSpacing.sm),
              Text('Gardırobuna Ekleyebilirsin',
                  style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: items
                .map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppSpacing.borderRadiusFull,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(item, style: AppTextStyles.caption),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _FollowUpChips extends StatelessWidget {
  final List<String> questions;

  const _FollowUpChips({required this.questions});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: questions
          .map(
            (q) => GestureDetector(
              onTap: () {
                // TODO: wire back to chat input
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppSpacing.borderRadiusFull,
                  border: Border.all(color: AppColors.accent.withOpacity(0.4)),
                ),
                child: Text(
                  q,
                  style: AppTextStyles.caption.copyWith(color: AppColors.accent),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
