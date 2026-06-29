import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_text_styles.dart';

/// Shared brand mark used in splash, headers, and settings.
class AppBrandLogo extends StatelessWidget {
  const AppBrandLogo({
    super.key,
    this.size = 44,
    this.fontSize = 20,
    this.showWordmark = true,
    this.showShadow = false,
  });

  final double size;
  final double fontSize;
  final bool showWordmark;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: showShadow
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(size * 0.26),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.24),
                      blurRadius: size * 0.45,
                      offset: Offset(0, size * 0.14),
                    ),
                  ],
                )
              : const BoxDecoration(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.26),
            child: Image.asset(
              AppConstants.appIconAsset,
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (showWordmark) ...[
          SizedBox(width: size * 0.42),
          Text(
            AppConstants.appName,
            style: AppTextStyles.displaySmall.copyWith(
              fontSize: fontSize,
              letterSpacing: -.65,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }
}

/// Large splash hero logo.
class AppBrandHeroLogo extends StatelessWidget {
  const AppBrandHeroLogo({super.key, this.size = 108});

  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.28),
            blurRadius: size * 0.42,
            offset: Offset(0, size * 0.14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.24),
        child: Image.asset(
          AppConstants.appIconAsset,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
