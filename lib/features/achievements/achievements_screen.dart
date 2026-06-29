import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: context.pop,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.goldenYellow.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.emoji_events_outlined,
                      color: AppColors.goldenYellow),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RetroAchievements',
                          style: AppTextStyles.headlineSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Connect your account to sync progress, badges, and points.',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: () => context.push('/settings'),
                        child: const Text('Open settings'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Overview', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                  child: _Stat(
                      value: '0',
                      label: 'Unlocked',
                      icon: Icons.emoji_events_outlined)),
              SizedBox(width: 10),
              Expanded(
                  child: _Stat(
                      value: '0',
                      label: 'Locked',
                      icon: Icons.lock_outline_rounded)),
              SizedBox(width: 10),
              Expanded(
                  child: _Stat(
                      value: '0',
                      label: 'Points',
                      icon: Icons.star_outline_rounded)),
            ],
          ),
          const SizedBox(height: 28),
          Text('What you can track', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 10),
          const _Feature(
              icon: Icons.check_circle_outline_rounded,
              text: 'Achievements for supported games'),
          const _Feature(
              icon: Icons.leaderboard_outlined,
              text: 'Leaderboards and challenge progress'),
          const _Feature(
              icon: Icons.workspace_premium_outlined,
              text: 'Badges, points, and completion status'),
          const _Feature(
              icon: Icons.sync_rounded,
              text: 'Progress synchronized with your account'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.icon});
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 20),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.displaySmall),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.labelSmall),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}
