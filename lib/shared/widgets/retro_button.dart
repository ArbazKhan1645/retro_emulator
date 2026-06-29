import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';


class RetroPlayButton extends StatelessWidget {
  const RetroPlayButton({
    super.key,
    required this.onPressed,
    this.label = 'Play',
    this.icon = Icons.play_arrow_rounded,
    this.color,
    this.width,
    this.height = 48,
  });

  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final Color? color;
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(_sentenceCase(label)),
        style: FilledButton.styleFrom(
          backgroundColor: color ?? Theme.of(context).colorScheme.primary,
          foregroundColor: AppColors.overlay,
        ),
      ),
    );
  }
}

class RetroIconButton extends StatelessWidget {
  const RetroIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 44,
    this.color,
    this.tooltip,
    this.isActive = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final Color? color;
  final String? tooltip;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: isActive ? accent.withOpacity(0.14) : AppColors.card,
          foregroundColor: isActive ? accent : AppColors.textSecondary,
          side: BorderSide(
              color:
                  isActive ? accent.withOpacity(0.55) : AppColors.glassBorder),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        ),
        icon: Icon(icon, size: size * 0.45),
      ),
    );
  }
}

class RetroOutlineButton extends StatelessWidget {
  const RetroOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.width,
    this.height = 48,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? color;
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? AppColors.textPrimary;
    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
        label: Text(_sentenceCase(label)),
        style: OutlinedButton.styleFrom(foregroundColor: foreground),
      ),
    );
  }
}

String _sentenceCase(String value) {
  if (value.isEmpty || value != value.toUpperCase()) return value;
  final lower = value.toLowerCase();
  return '${lower[0].toUpperCase()}${lower.substring(1)}';
}
