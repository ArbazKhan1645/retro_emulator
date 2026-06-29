import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../settings/providers/settings_provider.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(settingsProvider).themeMode;
    const themes = [
      _ThemeOption(AppThemeMode.dark, 'Midnight', 'Balanced dark interface',
          AppColors.primary, AppColors.background),
      _ThemeOption(AppThemeMode.oledBlack, 'Pure black',
          'Optimized for OLED displays', AppColors.primary, Colors.black),
      _ThemeOption(AppThemeMode.blueNeon, 'Navy', 'Cool blue-gray surfaces',
          AppColors.neonBluePrimary, AppColors.neonBlueBackground),
      _ThemeOption(AppThemeMode.purple, 'Plum', 'Soft violet accents',
          AppColors.purplePrimary, AppColors.purpleBackground),
      _ThemeOption(AppThemeMode.retroCRT, 'Forest', 'Muted green accents',
          AppColors.crtGreen, AppColors.crtBackground),
      _ThemeOption(AppThemeMode.cyberpunk, 'Sand', 'Warm amber accents',
          AppColors.cyberpunkYellow, AppColors.cyberpunkBackground),
      _ThemeOption(AppThemeMode.synthwave, 'Rose', 'Subtle rose accents',
          AppColors.synthwavePrimary, AppColors.synthwaveBackground),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: context.pop,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text('Color theme', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Choose a palette that is comfortable for your display.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 18),
          ...themes.map((option) {
            final isSelected = option.mode == selected;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isSelected ? option.accent : AppColors.glassBorder,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => ref
                      .read(settingsProvider.notifier)
                      .setThemeMode(option.mode),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 42,
                          decoration: BoxDecoration(
                            color: option.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            width: 22,
                            height: 6,
                            decoration: BoxDecoration(
                              color: option.accent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(option.name,
                                  style: AppTextStyles.bodyLarge
                                      .copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(option.description,
                                  style: AppTextStyles.bodySmall),
                            ],
                          ),
                        ),
                        Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color:
                              isSelected ? option.accent : AppColors.textHint,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ThemeOption {
  const _ThemeOption(
      this.mode, this.name, this.description, this.accent, this.background);
  final AppThemeMode mode;
  final String name;
  final String description;
  final Color accent;
  final Color background;
}
