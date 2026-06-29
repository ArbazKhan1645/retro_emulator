import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/game_model.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../save_states/providers/save_states_provider.dart';
import '../providers/emulator_provider.dart';

class QuickMenuOverlay extends ConsumerWidget {
  const QuickMenuOverlay({
    super.key,
    this.game,
    required this.status,
    required this.isFastForwarding,
    required this.currentSlot,
    required this.onResume,
    required this.onSave,
    required this.onLoad,
    required this.onFastForward,
    required this.onToggleControls,
    required this.onExit,
    required this.onSlotChanged,
  });

  final GameModel? game;
  final EmulatorStatus status;
  final bool isFastForwarding;
  final int currentSlot;
  final VoidCallback onResume;
  final VoidCallback onSave;
  final VoidCallback onLoad;
  final void Function(bool) onFastForward;
  final VoidCallback onToggleControls;
  final VoidCallback onExit;
  final void Function(int) onSlotChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: SafeArea(
          child: Center(
            child: GlassContainer(
              width: 320,
              borderRadius: BorderRadius.circular(24),
              padding: const EdgeInsets.all(24),
              blurStrength: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (game != null)
                    Text(
                      game!.title,
                      style: AppTextStyles.headlineSmall,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Text('Quick menu', style: AppTextStyles.labelMedium),
                  const SizedBox(height: 20),
                  _SlotSelector(
                    currentSlot: currentSlot,
                    onChanged: onSlotChanged,
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.5,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _MenuButton(
                        icon: Icons.play_arrow_rounded,
                        label: 'Resume',
                        color: AppColors.neonGreen,
                        onTap: onResume,
                      ),
                      _MenuButton(
                        icon: Icons.save_rounded,
                        label: 'Save State',
                        color: AppColors.neonCyan,
                        onTap: onSave,
                      ),
                      _MenuButton(
                        icon: Icons.restore_rounded,
                        label: 'Load State',
                        color: AppColors.electricBlue,
                        onTap: () => _showRecoveryDialog(
                            context, ref, game?.id ?? '', onResume),
                      ),
                      _MenuButton(
                        icon: Icons.fast_forward_rounded,
                        label: isFastForwarding ? 'Normal' : 'Fast Fwd',
                        color: AppColors.goldenYellow,
                        onTap: () => onFastForward(!isFastForwarding),
                        isActive: isFastForwarding,
                      ),
                      _MenuButton(
                        icon: Icons.gamepad_outlined,
                        label: 'Controls',
                        color: AppColors.primary,
                        onTap: () {
                          onToggleControls();
                          onResume();
                        },
                      ),
                      _MenuButton(
                        icon: Icons.edit_location_alt_rounded,
                        label: 'Edit Layout',
                        color: AppColors.neonCyan,
                        onTap: () {
                          onResume();
                          context.push('/settings/controller/layout-editor');
                        },
                      ),
                      _MenuButton(
                        icon: Icons.restart_alt_rounded,
                        label: 'Reset Game',
                        color: AppColors.hotPink,
                        onTap: () {
                          ref.read(emulatorProvider.notifier).reset();
                          onResume();
                        },
                      ),
                      _MenuButton(
                        icon: Icons.exit_to_app_rounded,
                        label: 'Exit Game',
                        color: AppColors.error,
                        onTap: onExit,
                      ),
                    ],
                  ).animate().fadeIn(duration: 300.ms),
                ],
              ),
            ).animate().scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1, 1),
                  duration: 200.ms,
                  curve: Curves.easeOut,
                ),
          ),
        ),
      ),
    );
  }

  void _showRecoveryDialog(
    BuildContext context,
    WidgetRef ref,
    String gameId,
    VoidCallback onResume,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Consumer(
          builder: (context, ref, child) {
            final savesState = ref.watch(saveStatesProvider(gameId));
            final states = savesState.states;

            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text('Recovery saves'),
              content: states.isEmpty
                  ? SizedBox(
                      width: 280,
                      height: 120,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.history_toggle_off_rounded,
                              color: Colors.white24, size: 40),
                          const SizedBox(height: 12),
                          Text(
                            'No save states found.\nSave a state during gameplay to create recovery points.',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: Colors.white54),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : SizedBox(
                      width: 320,
                      height: 280,
                      child: ListView.builder(
                        itemCount: states.length,
                        itemBuilder: (context, index) {
                          final save = states[index];
                          final file = save.thumbnailPath != null
                              ? File(save.thumbnailPath!)
                              : null;
                          final hasThumb = file != null && file.existsSync();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 72,
                                  height: 48,
                                  child: hasThumb
                                      ? Image.file(file, fit: BoxFit.cover)
                                      : Container(
                                          color: Colors.black26,
                                          child: const Icon(
                                              Icons.videogame_asset_outlined,
                                              color: Colors.white24,
                                              size: 20),
                                        ),
                                ),
                              ),
                              title: Text(
                                save.displayName,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                _formatDateTime(save.timestamp),
                                style: const TextStyle(
                                    color: Colors.white30, fontSize: 8),
                              ),
                              onTap: () async {
                                Navigator.pop(dialogCtx);
                                final success = await ref
                                    .read(emulatorProvider.notifier)
                                    .loadStateFromFile(save.statePath);
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '${save.displayName} Restored Successfully!'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                  onResume();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Failed to load state!'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Close',
                      style: TextStyle(color: Colors.white70)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _SlotSelector extends StatelessWidget {
  const _SlotSelector({required this.currentSlot, required this.onChanged});
  final int currentSlot;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.bookmark_rounded,
              color: AppColors.primary, size: 16),
          const SizedBox(width: 8),
          Text('Save Slot:', style: AppTextStyles.bodySmall),
          const Spacer(),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_rounded,
                    size: 16, color: AppColors.textSecondary),
                onPressed:
                    currentSlot > 0 ? () => onChanged(currentSlot - 1) : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '$currentSlot',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.primary),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_rounded,
                    size: 16, color: AppColors.textSecondary),
                onPressed:
                    currentSlot < 98 ? () => onChanged(currentSlot + 1) : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isActive = false,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.25) : AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? color : AppColors.glassBorder,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
