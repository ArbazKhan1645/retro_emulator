import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_brand_logo.dart';

/// Compatibility wrapper for older screens. Text is intentionally clean and
/// unembellished; visual hierarchy comes from weight and spacing, not glow.
class NeonText extends StatelessWidget {
  const NeonText({
    super.key,
    required this.text,
    this.color,
    this.fontSize = 24,
    this.fontWeight = FontWeight.w700,
    this.glowRadius = 0,
    this.letterSpacing = -0.3,
  });

  final String text;
  final Color? color;
  final double fontSize;
  final FontWeight fontWeight;
  final double glowRadius;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    return Text(
      _titleCase(text),
      style: AppTextStyles.displaySmall.copyWith(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? AppColors.textPrimary,
        letterSpacing: letterSpacing.clamp(-0.5, 0.2),
      ),
    );
  }

  String _titleCase(String value) {
    if (value != value.toUpperCase()) return value;
    return value
        .toLowerCase()
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}

class RetroVerseLogo extends StatelessWidget {
  const RetroVerseLogo({
    super.key,
    this.fontSize = 22,
    this.showWordmark = true,
  });
  final double fontSize;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    return AppBrandLogo(
      size: fontSize + 10,
      fontSize: fontSize,
      showWordmark: showWordmark,
    );
  }
}
