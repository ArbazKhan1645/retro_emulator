import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Compatibility wrapper now rendered as a solid, bordered product surface.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blurStrength = 0,
    this.opacity = 0,
    this.borderOpacity = 0,
    this.gradient,
    this.border,
    this.boxShadow,
  });

  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double blurStrength;
  final double opacity;
  final double borderOpacity;
  final Gradient? gradient;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(14);
    return Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: gradient == null ? Theme.of(context).cardColor : null,
        gradient: gradient,
        borderRadius: radius,
        border: border ?? Border.all(color: AppColors.glassBorder),
        boxShadow: boxShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class NeonGlowContainer extends StatelessWidget {
  const NeonGlowContainer({
    super.key,
    required this.child,
    this.glowColor,
    this.borderRadius,
    this.padding,
    this.glowIntensity = 0,
  });

  final Widget child;
  final Color? glowColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double glowIntensity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: borderRadius ?? BorderRadius.circular(14),
        border: Border.all(color: glowColor ?? AppColors.glassBorder),
      ),
      child: child,
    );
  }
}
