import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.onSeeAll,
    this.seeAllLabel = 'See all',
    this.color,
  });

  final String title;
  final IconData? icon;
  final VoidCallback? onSeeAll;
  final String seeAllLabel;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 840;
    return Padding(
      padding: EdgeInsets.fromLTRB(wide ? 28 : 20, 0, wide ? 24 : 16, 14),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: color ?? AppColors.textMuted, size: 18),
            const SizedBox(width: 9),
          ],
          Expanded(
            child: Text(
              title,
              style: wide
                  ? AppTextStyles.headlineLarge
                  : AppTextStyles.headlineMedium,
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: Text(seeAllLabel),
            ),
        ],
      ),
    );
  }
}

class NeonDivider extends StatelessWidget {
  const NeonDivider({super.key, this.color});
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Divider(
        height: 1, thickness: 1, color: color ?? AppColors.glassBorder);
  }
}
