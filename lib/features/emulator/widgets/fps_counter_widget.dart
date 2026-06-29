import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class FpsCounterWidget extends StatelessWidget {
  const FpsCounterWidget({super.key, required this.fps});
  final int fps;

  Color get _fpsColor {
    if (fps >= 58) return AppColors.neonGreen;
    if (fps >= 45) return AppColors.goldenYellow;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    if (fps == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _fpsColor.withOpacity(0.5)),
      ),
      child: Text(
        '$fps FPS',
        style: TextStyle(
          color: _fpsColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
