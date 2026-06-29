import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AnimatedGradientBackground extends StatelessWidget {
  const AnimatedGradientBackground({
    super.key,
    this.child,
    this.primaryColor,
    this.showParticles = false,
  });

  final Widget? child;
  final Color? primaryColor;
  final bool showParticles;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF101722), AppColors.background],
              ),
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class NeonDot extends StatelessWidget {
  const NeonDot({super.key, this.color});
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
          shape: BoxShape.circle, color: color ?? AppColors.textMuted),
    );
  }
}
