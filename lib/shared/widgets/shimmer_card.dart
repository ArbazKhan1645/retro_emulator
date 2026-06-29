import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';

/// Shimmer loading placeholder for game cards
class ShimmerGameCard extends StatelessWidget {
  const ShimmerGameCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.card,
      highlightColor: AppColors.cardHover,
      child: Container(
        width: AppConstants.cardWidth,
        height: AppConstants.cardHeight,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        ),
      ),
    );
  }
}

/// Shimmer row of cards
class ShimmerRow extends StatelessWidget {
  const ShimmerRow({super.key, this.count = 4});
  final int count;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppConstants.cardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => const ShimmerGameCard(),
      ),
    );
  }
}

/// Shimmer for detail page hero
class ShimmerHero extends StatelessWidget {
  const ShimmerHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.card,
      highlightColor: AppColors.cardHover,
      child: Container(
        height: AppConstants.heroHeight,
        color: AppColors.card,
      ),
    );
  }
}

/// Shimmer grid item
class ShimmerGridItem extends StatelessWidget {
  const ShimmerGridItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.card,
      highlightColor: AppColors.cardHover,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        ),
      ),
    );
  }
}
