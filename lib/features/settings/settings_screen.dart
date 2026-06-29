import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/glass_container.dart';
import '../settings/providers/settings_provider.dart';
import '../../shared/services/storage_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B111A), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 26, 20, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            onPressed: () => context.pop(),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                size: 20),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.card,
                              foregroundColor: AppColors.textSecondary,
                            ),
                            padding: const EdgeInsets.all(10),
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('Settings', style: AppTextStyles.displayMedium),
                          const SizedBox(height: 5),
                          Text(
                            'Fine-tune how ${AppConstants.appName} looks, sounds, and plays.',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _buildSection(
                'Appearance',
                Icons.palette_outlined,
                AppColors.primary,
                [
                  _SettingsTile(
                    icon: Icons.color_lens_outlined,
                    title: 'Theme',
                    subtitle: _themeName(settings.themeMode),
                    onTap: () => context.push('/settings/themes'),
                    trailing: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: settings.accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
                delay: 0,
              ),
              _buildSection(
                'Emulator',
                Icons.sports_esports_outlined,
                AppColors.neonCyan,
                [
                  _SettingsTile(
                    icon: Icons.speed_rounded,
                    title: 'Fast Forward Speed',
                    subtitle: '${settings.fastForwardSpeed}x',
                    onTap: () {},
                    trailing: SizedBox(
                      width: 120,
                      child: Slider(
                        value: settings.fastForwardSpeed.toDouble(),
                        min: 2,
                        max: 6,
                        divisions: 4,
                        onChanged: (v) =>
                            notifier.setFastForwardSpeed(v.toInt()),
                      ),
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.save_outlined,
                    title: 'Auto Save',
                    subtitle: 'Automatically save on exit',
                    trailing: Switch(
                      value: settings.autoSave,
                      onChanged: notifier.setAutoSave,
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.aspect_ratio_rounded,
                    title: 'Aspect Ratio',
                    subtitle: settings.aspectRatio,
                    onTap: () => _showAspectRatioDialog(context, ref),
                  ),
                  _SettingsTile(
                    icon: Icons.filter_b_and_w_rounded,
                    title: 'Shader Filter',
                    subtitle: settings.shaderFilter
                        .replaceAll('_', ' ')
                        .toUpperCase(),
                    onTap: () => _showShaderDialog(context, ref),
                  ),
                ],
                delay: 100,
              ),
              _buildSection(
                'Audio',
                Icons.volume_up_outlined,
                AppColors.goldenYellow,
                [
                  _SettingsTile(
                    icon: Icons.volume_up_rounded,
                    title: 'Volume',
                    subtitle: '${(settings.audioVolume * 100).toInt()}%',
                    trailing: SizedBox(
                      width: 120,
                      child: Slider(
                        value: settings.audioVolume,
                        min: 0,
                        max: 1,
                        onChanged: notifier.setAudioVolume,
                      ),
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.music_note_rounded,
                    title: 'Audio Enabled',
                    subtitle: 'Enable game audio output',
                    trailing: Switch(
                      value: settings.audioEnabled,
                      onChanged: notifier.setAudioEnabled,
                    ),
                  ),
                ],
                delay: 200,
              ),
              _buildSection(
                'Controls',
                Icons.gamepad_outlined,
                AppColors.hotPink,
                [
                  _SettingsTile(
                    icon: Icons.touch_app_outlined,
                    title: 'Touch Controls',
                    subtitle: 'On-screen controller',
                    onTap: () => context.push('/settings/controller'),
                  ),
                  _SettingsTile(
                    icon: Icons.vibration_rounded,
                    title: 'Haptic Feedback',
                    subtitle: 'Vibrate on button press',
                    trailing: Switch(
                      value: settings.hapticFeedback,
                      onChanged: notifier.setHapticFeedback,
                    ),
                  ),
                ],
                delay: 300,
              ),
              _buildSection(
                'Storage',
                Icons.folder_outlined,
                AppColors.neonGreen,
                [
                  _SettingsTile(
                    icon: Icons.folder_open_rounded,
                    title: 'ROM Scan Folders',
                    subtitle: '${settings.scanFolders.length} folder(s)',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.memory_rounded,
                    title: 'BIOS Files',
                    subtitle: 'Manage BIOS for Genesis Plus GX',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.delete_sweep_rounded,
                    title: 'Clear Save States',
                    subtitle: 'Delete all locally saved gameplay slots',
                    onTap: () => _confirmClearSaves(context, ref),
                  ),
                ],
                delay: 400,
              ),
              _buildSection(
                'RetroAchievements',
                Icons.emoji_events_outlined,
                AppColors.goldenYellow,
                [
                  _SettingsTile(
                    icon: Icons.account_circle_outlined,
                    title: 'Username',
                    subtitle: settings.raUsername.isEmpty
                        ? 'Not configured'
                        : settings.raUsername,
                    onTap: () => _showRaDialog(context, ref, settings),
                  ),
                ],
                delay: 500,
              ),
              _buildSection(
                'About',
                Icons.info_outline_rounded,
                AppColors.textMuted,
                [
                  const _SettingsTile(
                    icon: Icons.sports_esports_rounded,
                    title: AppConstants.appName,
                    subtitle: 'Version 1.0.0 • Genesis Plus GX',
                  ),
                  const _SettingsTile(
                    icon: Icons.code_rounded,
                    title: 'Open Source',
                    subtitle: 'Built with Flutter + Libretro',
                  ),
                ],
                delay: 600,
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
      String title, IconData icon, Color color, List<Widget> children,
      {int delay = 0}) {
    return SliverToBoxAdapter(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 16),
                    const SizedBox(width: 8),
                    Text(title, style: AppTextStyles.labelLarge),
                  ],
                ),
                const SizedBox(height: 10),
                GlassContainer(
                  borderRadius: BorderRadius.circular(18),
                  child: Column(
                    children: children,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAspectRatioDialog(BuildContext context, WidgetRef ref) {
    final options = ['4:3', '16:9', 'Stretch', 'Original'];
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Aspect Ratio'),
        children: options
            .map((o) => SimpleDialogOption(
                  onPressed: () {
                    ref.read(settingsProvider.notifier).setAspectRatio(o);
                    Navigator.pop(context);
                  },
                  child: Text(o),
                ))
            .toList(),
      ),
    );
  }

  String _themeName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.dark:
        return 'Midnight';
      case AppThemeMode.oledBlack:
        return 'Pure black';
      case AppThemeMode.blueNeon:
        return 'Navy';
      case AppThemeMode.purple:
        return 'Plum';
      case AppThemeMode.retroCRT:
        return 'Forest';
      case AppThemeMode.cyberpunk:
        return 'Sand';
      case AppThemeMode.synthwave:
        return 'Rose';
    }
  }

  void _showShaderDialog(BuildContext context, WidgetRef ref) {
    final options = ['pixel_perfect', 'crt', 'lcd', 'bilinear'];
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Shader Filter'),
        children: options
            .map((o) => SimpleDialogOption(
                  onPressed: () {
                    ref.read(settingsProvider.notifier).setShaderFilter(o);
                    Navigator.pop(context);
                  },
                  child: Text(o.replaceAll('_', ' ').toUpperCase()),
                ))
            .toList(),
      ),
    );
  }

  void _confirmClearSaves(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Clear Save States?'),
        content: const Text(
          'This will permanently delete all local game save files and screenshot thumbnails. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await ref.read(storageServiceProvider).clearAllSaveStates();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All save states cleared!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _showRaDialog(
      BuildContext context, WidgetRef ref, AppSettings settings) {
    final usernameCtrl = TextEditingController(text: settings.raUsername);
    final keyCtrl = TextEditingController(text: settings.raApiKey);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('RetroAchievements'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Username', hintText: 'Your RA username'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: keyCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'API Key', hintText: 'Your RA API key'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).setRaCredentials(
                    usernameCtrl.text,
                    keyCtrl.text,
                  );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.bodyLarge),
                    if (subtitle != null)
                      Text(subtitle!,
                          style: AppTextStyles.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (onTap != null)
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
