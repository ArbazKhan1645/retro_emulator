import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/glass_container.dart';
import '../settings/providers/settings_provider.dart';

class ControllerSettingsScreen extends ConsumerWidget {
  const ControllerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Controller'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GlassContainer(
            borderRadius: BorderRadius.circular(16),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Touch Controls', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Enable', style: AppTextStyles.bodyMedium),
                    const Spacer(),
                    Switch(
                      value: settings.touchControlsEnabled,
                      onChanged: notifier.setTouchControlsEnabled,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                    'Opacity: ${(settings.touchControlsOpacity * 100).toInt()}%',
                    style: AppTextStyles.bodySmall),
                Slider(
                  value: settings.touchControlsOpacity,
                  min: 0.2,
                  max: 1.0,
                  onChanged: settings.touchControlsEnabled
                      ? notifier.setTouchControlsOpacity
                      : null,
                ),
                Text('Size: ${(settings.touchControlsSize * 100).toInt()}%',
                    style: AppTextStyles.bodySmall),
                Slider(
                  value: settings.touchControlsSize,
                  min: 0.6,
                  max: 1.4,
                  onChanged: settings.touchControlsEnabled
                      ? notifier.setTouchControlsSize
                      : null,
                ),
                if (settings.touchControlsEnabled) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.push('/settings/controller/layout-editor'),
                    icon: const Icon(Icons.edit_location_alt_rounded, size: 18),
                    label: const Text('Customize button layout'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          GlassContainer(
            borderRadius: BorderRadius.circular(16),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Button Layout', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 12),
                Text(
                  'Sega Genesis 3-button layout\nD-Pad  •  A  •  B  •  C  •  Start  •  Mode',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 16),
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const _MiniButton(label: '▲'),
                          Row(
                            children: const [
                              _MiniButton(label: '◄'),
                              SizedBox(width: 4),
                              _MiniButton(label: '►'),
                            ],
                          ),
                          const _MiniButton(label: '▼'),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          _MiniButton(label: 'MODE', small: true),
                          SizedBox(height: 4),
                          _MiniButton(label: 'START', small: true),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const _MiniButton(
                              label: 'C', color: Color(0xFF1A3FA4)),
                          const SizedBox(height: 4),
                          Row(
                            children: const [
                              _MiniButton(label: 'B', color: Color(0xFFCC0000)),
                              SizedBox(width: 4),
                              _MiniButton(label: 'A', color: Color(0xFF006600)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GlassContainer(
            borderRadius: BorderRadius.circular(16),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.vibration_rounded,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Haptic Feedback', style: AppTextStyles.bodyLarge),
                      Text('Vibrate on button press',
                          style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                Switch(
                  value: settings.hapticFeedback,
                  onChanged: notifier.setHapticFeedback,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({required this.label, this.color, this.small = false});
  final String label;
  final Color? color;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: small ? 32 : 24,
      height: small ? 14 : 24,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(small ? 3 : 4),
        border: Border.all(
          color: color?.withOpacity(0.8) ?? Colors.white24,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: small ? 7 : 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
