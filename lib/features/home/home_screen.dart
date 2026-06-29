import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/models/game_model.dart';
import '../../shared/widgets/neon_text.dart';
import '../../shared/widgets/section_header.dart';
import '../library/providers/library_provider.dart';
import 'providers/home_provider.dart';
import 'widgets/game_row_widget.dart';
import 'widgets/hero_banner_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeProvider);
    final wide = MediaQuery.sizeOf(context).width >= 840;

    return Scaffold(
      extendBodyBehindAppBar: !wide,
      appBar: wide
          ? null
          : AppBar(
              backgroundColor:
                  Theme.of(context).scaffoldBackgroundColor.withOpacity(.88),
              surfaceTintColor: Colors.transparent,
              title: const RetroVerseLogo(fontSize: 21),
              actions: [
                IconButton(
                  tooltip: 'Search',
                  onPressed: () => context.push('/search'),
                  icon: const Icon(Icons.search_rounded),
                ),
                const SizedBox(width: 8),
              ],
            ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B111A), AppColors.background],
          ),
        ),
        child: home.isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : home.allGames.isEmpty
                ? _EmptyLibrary(onOpenLibrary: () => context.go('/library'))
                : _content(context, ref, home),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    WidgetRef ref,
    HomeState home,
  ) {
    void open(GameModel game) => context.push('/game/${game.id}');
    void play(GameModel game) => context.push('/emulator/${game.id}');
    void favorite(GameModel game) =>
        ref.read(libraryProvider.notifier).toggleFavorite(game.id);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: HeroBannerWidget(
            games: home.heroGames,
            onPlay: play,
            onDetails: open,
          ),
        ),
        if (home.recentlyPlayed.isNotEmpty)
          ..._section(
            title: 'Continue playing',
            icon: Icons.play_circle_outline_rounded,
            games: home.recentlyPlayed,
            onOpen: open,
            onFavorite: favorite,
            showRecent: true,
          ),
        if (home.favorites.isNotEmpty)
          ..._section(
            title: 'Favorites',
            icon: Icons.favorite_border_rounded,
            games: home.favorites,
            onOpen: open,
            onFavorite: favorite,
          ),
        if (home.mostPlayed.isNotEmpty)
          ..._section(
            title: 'Most played',
            icon: Icons.insights_outlined,
            games: home.mostPlayed,
            onOpen: open,
            onFavorite: favorite,
          ),
        if (home.recentlyAdded.isNotEmpty)
          ..._section(
            title: 'Recently added',
            icon: Icons.schedule_rounded,
            games: home.recentlyAdded,
            onOpen: open,
            onFavorite: favorite,
          ),
        ...home.byGenre.entries.expand(
          (entry) => _section(
            title: entry.key,
            icon: Icons.category_outlined,
            games: entry.value,
            onOpen: open,
            onFavorite: favorite,
          ),
        ),
        ..._section(
          title: 'All games',
          icon: Icons.grid_view_rounded,
          games: home.allGames,
          onOpen: open,
          onFavorite: favorite,
          bottomSpacing: 100,
        ),
      ],
    );
  }

  List<Widget> _section({
    required String title,
    required IconData icon,
    required List<GameModel> games,
    required void Function(GameModel) onOpen,
    required void Function(GameModel) onFavorite,
    bool showRecent = false,
    double bottomSpacing = 28,
  }) {
    return [
      SliverToBoxAdapter(child: SectionHeader(title: title, icon: icon)),
      SliverToBoxAdapter(
        child: GameRowWidget(
          games: games,
          onGameTap: onOpen,
          onFavoriteTap: onFavorite,
          showRecentBadge: showRecent,
        ),
      ),
      SliverToBoxAdapter(child: SizedBox(height: bottomSpacing)),
    ];
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.onOpenLibrary});
  final VoidCallback onOpenLibrary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const Icon(Icons.library_add_outlined,
                  size: 32, color: AppColors.textMuted),
            ),
            const SizedBox(height: 22),
            Text('Build your game library', style: AppTextStyles.headlineLarge),
            const SizedBox(height: 8),
            Text(
              'Add a ROM folder to organize and play your classic games.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onOpenLibrary,
              icon: const Icon(Icons.folder_open_rounded),
              label: const Text('Open library'),
            ),
          ],
        ),
      ),
    );
  }
}
