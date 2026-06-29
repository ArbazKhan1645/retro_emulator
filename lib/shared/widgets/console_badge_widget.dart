import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/console_info.dart';

class ConsoleBadge extends StatelessWidget {
  const ConsoleBadge(
      {super.key, required this.consoleName, this.compact = false});

  final String consoleName;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    ConsoleInfo info;
    try {
      info = ConsoleInfo.supported.firstWhere(
        (c) => c.name == consoleName || c.shortName == consoleName,
      );
    } catch (_) {
      info = ConsoleInfo.genesis;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Text(
        info.shortName,
        style: AppTextStyles.consoleBadge.copyWith(
          fontSize: compact ? 8 : 9,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
