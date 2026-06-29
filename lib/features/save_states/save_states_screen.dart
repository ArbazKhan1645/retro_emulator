import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/extensions/string_extensions.dart';
import '../../shared/models/save_state_model.dart';
import '../../shared/widgets/glass_container.dart';
import '../save_states/providers/save_states_provider.dart';
import '../library/providers/library_provider.dart';

class SaveStatesScreen extends ConsumerWidget {
  const SaveStatesScreen({super.key, required this.gameId});
  final String gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saveStates = ref.watch(saveStatesProvider(gameId));
    final library = ref.watch(libraryProvider);
    String? gameTitle;
    try {
      gameTitle = library.games.firstWhere((g) => g.id == gameId).title;
    } catch (_) {}

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Save states'),
            if (gameTitle != null)
              Text(gameTitle, style: AppTextStyles.bodySmall, maxLines: 1),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: saveStates.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : saveStates.states.isEmpty
              ? _buildEmpty()
              : _buildStatesList(context, ref, saveStates.states),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: const Icon(Icons.save_outlined,
                size: 30, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          Text('No save states', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Press Save State in the quick menu\nwhile playing to create saves',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatesList(
      BuildContext context, WidgetRef ref, List<SaveStateModel> states) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: states.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final state = states[index];
        return GlassContainer(
          borderRadius: BorderRadius.circular(14),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.card,
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: state.thumbnailPath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.file(
                        File(state.thumbnailPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _slotIcon(state.slotNumber),
                      ),
                    )
                  : _slotIcon(state.slotNumber),
            ),
            title: Text(
              state.displayName,
              style: AppTextStyles.bodyLarge,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(state.timestamp),
                  style: AppTextStyles.bodySmall,
                ),
                if (state.playTimeSeconds > 0)
                  Text(
                    state.playTimeSeconds.toPlayTime,
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.neonCyan),
                  ),
              ],
            ),
            trailing: PopupMenuButton(
              color: AppColors.card,
              icon: const Icon(Icons.more_vert_rounded,
                  color: AppColors.textMuted),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'rename',
                  child: Row(
                    children: [
                      const Icon(Icons.edit_rounded,
                          size: 16, color: AppColors.neonCyan),
                      const SizedBox(width: 8),
                      Text('Rename',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textPrimary)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline_rounded,
                          size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      Text('Delete',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'rename') {
                  _showRenameDialog(context, ref, state);
                } else if (value == 'delete') {
                  ref
                      .read(saveStatesProvider(gameId).notifier)
                      .deleteSaveState(state.id);
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _slotIcon(int slot) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bookmark_rounded,
              color: AppColors.primary, size: 20),
          Text(
            '$slot',
            style: AppTextStyles.labelLarge
                .copyWith(color: AppColors.primary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showRenameDialog(
      BuildContext context, WidgetRef ref, SaveStateModel state) {
    final ctrl = TextEditingController(text: state.name ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename Save State'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Save name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(saveStatesProvider(gameId).notifier)
                  .renameSaveState(state.id, ctrl.text);
              Navigator.pop(context);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }
}
