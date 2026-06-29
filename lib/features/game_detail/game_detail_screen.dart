import 'dart:io';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../save_states/providers/save_states_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/extensions/string_extensions.dart';
import '../../shared/models/game_model.dart';
import '../../shared/widgets/console_badge_widget.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/game_artwork.dart';
import '../../shared/widgets/retro_button.dart';
import '../library/providers/explore_games_provider.dart';
import '../library/providers/library_provider.dart';

class GameDetailScreen extends ConsumerWidget {
  const GameDetailScreen({super.key, required this.gameId});
  final String gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryProvider);
    GameModel? game;
    try {
      game = library.games.firstWhere((g) => g.id == gameId);
    } catch (_) {}

    // Fallback to bundled explore catalog if not in library
    ExploreGameModel? exploreGame;
    if (game == null) {
      final exploreCatalog = ref.watch(exploreGamesProvider).valueOrNull ?? [];
      try {
        exploreGame = exploreCatalog.firstWhere((g) => g.id == gameId);
        game = GameModel(
          id: exploreGame.id,
          title: exploreGame.title,
          romPath: '',
          coverUrl: exploreGame.coverUrl ?? exploreGame.coverAssetPath,
          isInstalled: false,
          fileSizeBytes: exploreGame.fileSizeBytes,
          fileExtension: exploreGame.fileExtension,
          addedAt: DateTime.now(),
        );
      } catch (_) {}
    } else {
      final exploreCatalog = ref.watch(exploreGamesProvider).valueOrNull ?? [];
      try {
        exploreGame = exploreCatalog.firstWhere((g) => g.id == gameId);
      } catch (_) {}
    }

    if (game == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(color: AppColors.textPrimary),
        ),
        body: const Center(
          child: Text('Game not found',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    return _GameDetailContent(game: game, exploreGame: exploreGame);
  }
}

class _GameDetailContent extends ConsumerWidget {
  const _GameDetailContent({required this.game, this.exploreGame});
  final GameModel game;
  final ExploreGameModel? exploreGame;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, ref),
          SliverToBoxAdapter(
            child: _buildBody(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      expandedHeight: 420,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.background,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GlassContainer(
          borderRadius: BorderRadius.circular(40),
          blurStrength: 10,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary, size: 18),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: GlassContainer(
            borderRadius: BorderRadius.circular(40),
            blurStrength: 10,
            child: IconButton(
              icon: Icon(
                game.isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color:
                    game.isFavorite ? AppColors.hotPink : AppColors.textPrimary,
                size: 20,
              ),
              onPressed: () =>
                  ref.read(libraryProvider.notifier).toggleFavorite(game.id),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
          child: GlassContainer(
            borderRadius: BorderRadius.circular(40),
            blurStrength: 10,
            child: PopupMenuButton(
              color: AppColors.card,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              icon: const Icon(Icons.more_vert_rounded,
                  color: AppColors.textPrimary, size: 20),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'metadata',
                  child: const _MenuItem(
                      icon: Icons.download_rounded, label: 'Fetch Metadata'),
                ),
                PopupMenuItem(
                  value: 'states',
                  child: const _MenuItem(
                      icon: Icons.save_alt_rounded,
                      label: 'Save States',
                      color: AppColors.neonCyan),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: const _MenuItem(
                      icon: Icons.delete_outline_rounded,
                      label: 'Remove from Library',
                      color: AppColors.error),
                ),
              ],
              onSelected: (value) {
                if (value == 'metadata') {
                  ref.read(libraryProvider.notifier).fetchMetadata(game.id);
                } else if (value == 'states') {
                  context.push('/save-states/${game.id}');
                } else if (value == 'delete') {
                  ref.read(libraryProvider.notifier).deleteGame(game.id);
                  context.pop();
                }
              },
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _buildHeroBackground(),
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
      ),
    );
  }

  Widget _buildHeroBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        GameArtwork(
          title: game.title,
          imageUrl: exploreGame?.coverUrl ??
              (game.coverUrl?.startsWith('http') == true ? game.coverUrl : null),
          assetPath: exploreGame?.coverAssetPath ??
              (game.coverUrl != null && !game.coverUrl!.startsWith('http')
                  ? game.coverUrl
                  : null),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.background.withValues(alpha: 0.15),
                AppColors.background.withValues(alpha: 0.55),
                AppColors.background,
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    return Transform.translate(
      offset: const Offset(0, -28),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Hero(
                  tag: 'cover_${game.id}',
                  child: Container(
                    width: 108,
                    height: 148,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.glassBorder,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.5),
                      child: GameArtwork(
                        title: game.title,
                        imageUrl: exploreGame?.coverUrl ??
                            (game.coverUrl?.startsWith('http') == true
                                ? game.coverUrl
                                : null),
                        assetPath: exploreGame?.coverAssetPath ??
                            (game.coverUrl != null &&
                                    !game.coverUrl!.startsWith('http')
                                ? game.coverUrl
                                : null),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.title,
                        style: AppTextStyles.displaySmall.copyWith(
                          height: 1.15,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ConsoleBadge(consoleName: game.consolePlatform),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _MetaRow(game: game),
            const SizedBox(height: 26),
          if (exploreGame != null && game.romPath.isEmpty) ...[
            _ExplorePlayButton(exploreGame: exploreGame!),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: RetroPlayButton(
                    onPressed: () => context.push('/emulator/${game.id}'),
                    label: 'Play now',
                    height: 56,
                  ),
                ),
                const SizedBox(width: 12),
                RetroIconButton(
                  icon: Icons.save_alt_rounded,
                  onPressed: () => context.push('/save-states/${game.id}'),
                  size: 56,
                  tooltip: 'Save States',
                  color: AppColors.neonCyan,
                ),
                const SizedBox(width: 8),
                RetroIconButton(
                  icon: game.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  onPressed: () => ref
                      .read(libraryProvider.notifier)
                      .toggleFavorite(game.id),
                  size: 56,
                  color: AppColors.hotPink,
                  isActive: game.isFavorite,
                  tooltip: 'Favorite',
                ),
              ],
            ),
          ],
          const SizedBox(height: 28),
          _SaveStatesRow(gameId: game.id),
          if (game.description != null && game.description!.isNotEmpty) ...[
            _SectionLabel('About'),
            const SizedBox(height: 10),
            Text(
              game.description!,
              style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
            ),
            const SizedBox(height: 24),
          ],
          if (game.screenshotUrls.isNotEmpty) ...[
            _SectionLabel('Screenshots'),
            const SizedBox(height: 12),
            _ScreenshotsRow(urls: game.screenshotUrls),
            const SizedBox(height: 24),
          ],
          _SectionLabel('Details'),
          const SizedBox(height: 12),
          _InfoGrid(game: game),
          const SizedBox(height: 32),
          _MoreToExploreRow(currentGameId: game.id),
          const SizedBox(height: 40),
        ],
      ),
    ),
    );
  }
}

class _ExplorePlayButton extends ConsumerStatefulWidget {
  const _ExplorePlayButton({required this.exploreGame});
  final ExploreGameModel exploreGame;

  @override
  ConsumerState<_ExplorePlayButton> createState() => _ExplorePlayButtonState();
}

class _ExplorePlayButtonState extends ConsumerState<_ExplorePlayButton> {
  bool _loading = false;

  Future<void> _play() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final game =
          await ref.read(exploreGameInstallerProvider).install(widget.exploreGame);
      if (!mounted) return;
      context.push('/emulator/${game.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not prepare game: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 56,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return RetroPlayButton(
      onPressed: _play,
      label: 'Play now',
      icon: Icons.play_arrow_rounded,
      height: 56,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: AppColors.primaryGradient,
          ),
        ),
        const SizedBox(width: 10),
        Text(text, style: AppTextStyles.headlineSmall),
      ],
    );
  }
}

class _MoreToExploreRow extends ConsumerWidget {
  const _MoreToExploreRow({required this.currentGameId});
  final String currentGameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(exploreGamesProvider).valueOrNull;
    if (catalog == null || catalog.length <= 1) return const SizedBox.shrink();

    final others =
        catalog.where((g) => g.id != currentGameId).toList();
    final random = Random(currentGameId.hashCode);
    others.shuffle(random);
    final picks = others.take(min(6, others.length)).toList();
    if (picks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('More to explore'),
        const SizedBox(height: 14),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: picks.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = picks[index];
              return GestureDetector(
                onTap: () => context.push('/game/${item.id}'),
                child: SizedBox(
                  width: 118,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: GameArtwork(
                              title: item.title,
                              imageUrl: item.coverUrl,
                              assetPath: item.coverAssetPath,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.title,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sega Genesis',
                        style: AppTextStyles.labelSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Row(
      children: [
        Icon(icon, color: c, size: 18),
        const SizedBox(width: 10),
        Text(label,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textPrimary)),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.game});
  final GameModel game;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    if (game.releaseYear != null) {
      items.add(_MetaChip(
          icon: Icons.calendar_today_rounded, label: '${game.releaseYear}'));
    }
    if (game.genre != null) {
      items.add(_MetaChip(icon: Icons.category_rounded, label: game.genre!));
    }
    if (game.rating > 0) {
      items.add(_MetaChip(
        icon: Icons.star_rounded,
        label: game.rating.toStringAsFixed(1),
        iconColor: AppColors.goldenYellow,
      ));
    }
    if (game.playTimeSeconds > 0) {
      items.add(_MetaChip(
        icon: Icons.access_time_rounded,
        label: game.playTimeSeconds.toPlayTime,
        iconColor: AppColors.neonCyan,
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items,
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label, this.iconColor});
  final IconData icon;
  final String label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor ?? AppColors.textMuted),
          const SizedBox(width: 5),
          Text(label, style: AppTextStyles.labelMedium),
        ],
      ),
    );
  }
}

// ============================================================
// Horizontal Save States Carousel Widget
// ============================================================
class _SaveStatesRow extends ConsumerWidget {
  const _SaveStatesRow({required this.gameId});
  final String gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saveStatesState = ref.watch(saveStatesProvider(gameId));
    final states = saveStatesState.states;

    if (states.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Saved states'),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: states.length,
            itemBuilder: (context, index) {
              final save = states[index];
              final file =
                  save.thumbnailPath != null ? File(save.thumbnailPath!) : null;
              final hasThumb = file != null && file.existsSync();

              return GestureDetector(
                onTap: () {
                  // Direct launch into save state
                  context.push(
                      '/emulator/$gameId?saveStatePath=${Uri.encodeComponent(save.statePath)}');
                },
                child: Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Thumbnail Image or fallback
                        hasThumb
                            ? Image.file(file, fit: BoxFit.cover)
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary.withOpacity(0.2),
                                      AppColors.surface
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(Icons.videogame_asset_outlined,
                                      color: Colors.white24, size: 28),
                                ),
                              ),
                        // Dark overlay gradient
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black87],
                            ),
                          ),
                        ),
                        // Info (Slot & Time)
                        Positioned(
                          bottom: 8,
                          left: 8,
                          right: 8,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                save.displayName,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDateTime(save.timestamp),
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 8),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _ScreenshotsRow extends StatelessWidget {
  const _ScreenshotsRow({required this.urls});
  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _showFullScreen(context, index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: urls[index],
                width: 200,
                height: 130,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(width: 200, color: AppColors.card),
                errorWidget: (_, __, ___) =>
                    Container(width: 200, color: AppColors.card),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFullScreen(BuildContext context, int initialIndex) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: urls.length,
            itemBuilder: (_, i) => InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: urls[i],
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.game});
  final GameModel game;

  @override
  Widget build(BuildContext context) {
    final infos = {
      'Console': game.consolePlatform,
      if (game.developer != null) 'Developer': game.developer!,
      if (game.publisher != null) 'Publisher': game.publisher!,
      if (game.releaseYear != null) 'Released': '${game.releaseYear}',
      'File Size': game.fileSizeBytes.toReadableBytes,
      'Extension': game.fileExtension.toUpperCase(),
      if (game.playTimeSeconds > 0)
        'Play Time': game.playTimeSeconds.toPlayTime,
    };

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: infos.entries.map((e) {
        return GlassContainer(
          borderRadius: BorderRadius.circular(10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(e.key, style: AppTextStyles.labelSmall),
              const SizedBox(height: 2),
              Text(e.value,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        );
      }).toList(),
    );
  }
}
