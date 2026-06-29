import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/extensions/string_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/models/game_model.dart';
import '../../shared/widgets/game_artwork.dart';
import '../library/providers/library_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final games = ref.watch(libraryProvider).games;
    final totalPlayTime =
        games.fold<int>(0, (sum, game) => sum + game.playTimeSeconds);
    final favorites = games.where((game) => game.isFavorite).length;
    final played = games.where((game) => game.lastPlayed != null).length;
    final ranked = List<GameModel>.from(games)
      ..sort((a, b) => b.playTimeSeconds.compareTo(a.playTimeSeconds));
    final mostPlayed = ranked.isEmpty ? null : ranked.first;

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
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              MediaQuery.sizeOf(context).width >= 840 ? 32 : 20,
              24,
              MediaQuery.sizeOf(context).width >= 840 ? 32 : 20,
              100,
            ),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your activity',
                            style: AppTextStyles.displayMedium),
                        const SizedBox(height: 5),
                        Text(
                          'A snapshot of your time in RetroVerse.',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Settings',
                    onPressed: () => context.push('/settings'),
                    icon: const Icon(Icons.tune_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 760;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: wide ? 4 : 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: wide ? 1.45 : 1.55,
                    children: [
                      _ActivityStat(
                          icon: Icons.grid_view_rounded,
                          label: 'Games',
                          value: '${games.length}'),
                      _ActivityStat(
                          icon: Icons.schedule_rounded,
                          label: 'Play time',
                          value: _formatTime(totalPlayTime)),
                      _ActivityStat(
                          icon: Icons.favorite_border_rounded,
                          label: 'Favorites',
                          value: '$favorites'),
                      _ActivityStat(
                          icon: Icons.history_rounded,
                          label: 'Played',
                          value: '$played'),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),
              Text('Highlights', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 12),
              if (mostPlayed == null)
                const _EmptyHighlight()
              else
                _MostPlayedCard(game: mostPlayed),
              const SizedBox(height: 28),
              Text('System', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration(context),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.memory_rounded,
                          color: AppColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sega Genesis',
                              style: AppTextStyles.headlineSmall),
                          const SizedBox(height: 2),
                          Text('Genesis Plus GX • ${games.length} games',
                              style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                    const _StatusPill(label: 'Ready'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTime(int seconds) {
    if (seconds == 0) return '0m';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }
}

class _ActivityStat extends StatelessWidget {
  const _ActivityStat(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: AppColors.textMuted, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTextStyles.displaySmall),
              const SizedBox(height: 2),
              Text(label, style: AppTextStyles.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _MostPlayedCard extends StatelessWidget {
  const _MostPlayedCard({required this.game});
  final GameModel game;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/game/${game.id}'),
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(context),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: SizedBox(
                width: 58,
                height: 76,
                child: GameArtwork(
                  title: game.title,
                  imageUrl: game.coverUrl,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(game.title,
                      style: AppTextStyles.headlineSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(
                    game.playTimeSeconds.toPlayTime,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.primary),
                  ),
                  if (game.genre != null) ...[
                    const SizedBox(height: 2),
                    Text(game.genre!, style: AppTextStyles.bodySmall),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _EmptyHighlight extends StatelessWidget {
  const _EmptyHighlight();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(context),
      child: Row(
        children: [
          const Icon(Icons.bar_chart_rounded, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
              child: Text('Play a game to see activity highlights here.',
                  style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.success)),
    );
  }
}

BoxDecoration _cardDecoration(BuildContext context) => BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.glassBorder),
    );
