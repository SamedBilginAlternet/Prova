import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

/// Shimmer placeholder for loading images / cards.
class ImageShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ImageShimmer({
    super.key,
    this.width = double.infinity,
    this.height = 200,
    this.borderRadius = AppSpacing.radiusLg,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.shimmerBase,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Shimmer placeholder for garment cards in the grid
class GarmentCardShimmer extends StatelessWidget {
  const GarmentCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.shimmerBase,
                borderRadius: AppSpacing.borderRadiusLg,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 14,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.shimmerBase,
              borderRadius: AppSpacing.borderRadiusSm,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 12,
            width: 80,
            decoration: BoxDecoration(
              color: AppColors.shimmerBase,
              borderRadius: AppSpacing.borderRadiusSm,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer for result history items
class ResultCardShimmer extends StatelessWidget {
  const ResultCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.shimmerBase,
          borderRadius: AppSpacing.borderRadiusLg,
        ),
      ),
    );
  }
}
