import 'package:url_launcher/url_launcher_string.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/explore_games_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/models/game_model.dart';
import '../../shared/widgets/game_card_widget.dart';
import '../../shared/widgets/game_artwork.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/app_brand_logo.dart';
import '../../shared/widgets/shimmer_card.dart';
import '../library/providers/library_provider.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showScanDialog() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _ScanBottomSheet(
        onScan: (folders) {
          Navigator.pop(ctx);
          ref.read(libraryProvider.notifier).scanFolders(folders);
        },
        onImportFiles: (files) {
          Navigator.pop(ctx);
          ref.read(libraryProvider.notifier).importRomFiles(files);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final libState = ref.watch(libraryProvider);
    final filteredGames = libState.filteredGames;
    final exploreAsync = ref.watch(exploreGamesProvider);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0C1118), AppColors.background],
            stops: [0, 0.35],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(context, libState, exploreAsync),
              const SizedBox(height: 8),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMyLibraryTab(libState, filteredGames),
                    _buildExploreTab(exploreAsync),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(
      BuildContext context, LibraryState libState, AsyncValue<List<ExploreGameModel>> exploreAsync) {
    final gameCount = libState.games.length;
    final exploreCount = exploreAsync.maybeWhen(
      data: (games) => games.length,
      orElse: () => 0,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppBrandLogo(fontSize: 20, size: 36),
                const SizedBox(height: 6),
                Text(
                  gameCount == 0
                      ? '$exploreCount classics ready to explore'
                      : '$gameCount in your collection · $exploreCount to discover',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          _HeaderIconButton(
            icon: Icons.add_rounded,
            tooltip: 'Add games',
            onPressed: _showScanDialog,
            filled: true,
          ),
          const SizedBox(width: 6),
          _HeaderIconButton(
            icon: Icons.tune_rounded,
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.22),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: const Color(0xFF1A1408),
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: AppTextStyles.labelLarge.copyWith(fontSize: 13),
          unselectedLabelStyle: AppTextStyles.labelLarge.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
          tabs: const [
            Tab(text: 'My Library'),
            Tab(text: 'Explore'),
          ],
        ),
      ),
    );
  }

  Widget _buildMyLibraryTab(LibraryState libState, List<GameModel> games) {
    return Column(
      children: [
        _buildHeader(libState),
        _buildFilterChips(libState),
        if (libState.isScanning) _buildScanProgress(libState),
        Expanded(
          child: libState.isLoading
              ? _buildLoadingGrid()
              : games.isEmpty
                  ? _buildEmptyState(libState.games.isEmpty)
                  : _buildGameGrid(games, libState.isGridView),
        ),
      ],
    );
  }

  Widget _buildExploreTab(AsyncValue<List<ExploreGameModel>> exploreAsync) {
    return exploreAsync.when(
      loading: () => _buildLoadingGrid(),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.folder_off_outlined,
                  size: 48, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text('Could not load bundled games',
                  style: AppTextStyles.headlineSmall),
              const SizedBox(height: 8),
              Text('$error',
                  style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
      data: (catalog) {
        if (catalog.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined,
                      size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text('No bundled games yet',
                      style: AppTextStyles.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Add ROM files to assets/roms/\nand rebuild the app.',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            crossAxisSpacing: 14,
            mainAxisSpacing: 16,
            childAspectRatio: AppConstants.cardWidth / AppConstants.cardHeight,
          ),
          itemCount: catalog.length,
          itemBuilder: (context, index) {
            final game = catalog[index];
            return _ExploreGameCard(
              game: game,
              index: index,
              onTap: () => context.push('/game/${game.id}'),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(LibraryState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.card.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: TextField(
                controller: _searchController,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search your collection…',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textMuted,
                            size: 18,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(libraryProvider.notifier)
                                .setSearchQuery('');
                            setState(() {});
                          },
                        )
                      : null,
                ),
                onChanged: (q) {
                  ref.read(libraryProvider.notifier).setSearchQuery(q);
                  setState(() {});
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildSortButton(state),
          const SizedBox(width: 2),
          IconButton(
            icon: Icon(
              state.isGridView
                  ? Icons.view_list_rounded
                  : Icons.grid_view_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
            onPressed: () =>
                ref.read(libraryProvider.notifier).toggleViewMode(),
          ),
        ],
      ),
    );
  }

  Widget _buildSortButton(LibraryState state) {
    return PopupMenuButton<LibrarySortBy>(
      color: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      icon: const Icon(Icons.sort_rounded, color: AppColors.textSecondary),
      onSelected: (sort) => ref.read(libraryProvider.notifier).setSortBy(sort),
      itemBuilder: (_) => LibrarySortBy.values
          .map(
            (s) => PopupMenuItem(
              value: s,
              child: Row(
                children: [
                  if (state.sortBy == s)
                    const Icon(Icons.check_rounded,
                        color: AppColors.primary, size: 16)
                  else
                    const SizedBox(width: 16),
                  const SizedBox(width: 8),
                  Text(
                    s.name.replaceAllMapped(
                        RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}'),
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildFilterChips(LibraryState state) {
    const filters = LibraryFilter.values;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final filter = filters[i];
          final isSelected = state.filter == filter;
          final label = filter.name
              .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}')
              .trim();
          return FilterChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) =>
                ref.read(libraryProvider.notifier).setFilter(filter),
            backgroundColor: AppColors.card.withValues(alpha: 0.6),
            selectedColor: AppColors.primary.withValues(alpha: 0.16),
            checkmarkColor: AppColors.primary,
            side: BorderSide(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.glassBorder,
            ),
            labelStyle: AppTextStyles.labelMedium.copyWith(
              color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScanProgress(LibraryState state) {
    final progress = state.scanProgress;
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 14, 22, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                  value: progress != null && progress.total > 0
                      ? progress.scanned / progress.total
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Scanning ROMs…',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textPrimary),
              ),
              const Spacer(),
              if (progress != null && progress.total > 0)
                Text(
                  '${progress.scanned}/${progress.total}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.primary),
                ),
            ],
          ),
          if (progress != null && progress.total > 0) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress.scanned / progress.total,
                backgroundColor: AppColors.glassBorder,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                minHeight: 3,
              ),
            ),
            if (progress.currentFile.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                progress.currentFile,
                style: AppTextStyles.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildGameGrid(List<GameModel> games, bool isGridView) {
    if (!isGridView) return _buildListView(games);

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        crossAxisSpacing: 14,
        mainAxisSpacing: 16,
        childAspectRatio: AppConstants.cardWidth / AppConstants.cardHeight,
      ),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        return GameCardWidget(
          game: game,
          onTap: () => context.push('/game/${game.id}'),
          onFavoriteTap: () =>
              ref.read(libraryProvider.notifier).toggleFavorite(game.id),
          animationDelay: Duration(milliseconds: index * 35),
        );
      },
    );
  }

  Widget _buildListView(List<GameModel> games) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
      itemCount: games.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final game = games[index];
        return GlassContainer(
          borderRadius: BorderRadius.circular(14),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: game.coverUrl != null
                  ? Image.network(
                      game.coverUrl!,
                      width: 52,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildListPlaceholder(),
                    )
                  : _buildListPlaceholder(),
            ),
            title: Text(
              game.title,
              style: AppTextStyles.gameTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(game.consolePlatform, style: AppTextStyles.bodySmall),
                if (game.developer != null)
                  Text(
                    game.developer!,
                    style: AppTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (game.rating > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 13, color: AppColors.goldenYellow),
                      const SizedBox(width: 2),
                      Text(
                        game.rating.toStringAsFixed(1),
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.goldenYellow),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                IconButton(
                  icon: Icon(
                    game.isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: game.isFavorite
                        ? AppColors.hotPink
                        : AppColors.textMuted,
                    size: 20,
                  ),
                  onPressed: () => ref
                      .read(libraryProvider.notifier)
                      .toggleFavorite(game.id),
                ),
              ],
            ),
            onTap: () => context.push('/game/${game.id}'),
          ),
        );
      },
    );
  }

  Widget _buildListPlaceholder() {
    return Container(
      width: 52,
      height: 72,
      color: AppColors.card,
      child: const Icon(
        Icons.sports_esports_rounded,
        color: AppColors.textMuted,
        size: 24,
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        crossAxisSpacing: 14,
        mainAxisSpacing: 16,
        childAspectRatio: AppConstants.cardWidth / AppConstants.cardHeight,
      ),
      itemCount: 8,
      itemBuilder: (_, __) => const ShimmerGridItem(),
    );
  }

  Widget _buildEmptyState(bool noGamesAtAll) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Icon(
                noGamesAtAll
                    ? Icons.library_add_outlined
                    : Icons.search_off_rounded,
                size: 40,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              noGamesAtAll ? 'Your library awaits' : 'No matches found',
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(
              noGamesAtAll
                  ? 'Import ROMs or browse Explore\nto start your collection.'
                  : 'Try a different search or clear your filters.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (noGamesAtAll) ...[
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _showScanDialog,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Add games'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled
            ? AppColors.primary.withValues(alpha: 0.14)
            : AppColors.card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: filled
                    ? AppColors.primary.withValues(alpha: 0.35)
                    : AppColors.glassBorder,
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: filled ? AppColors.primaryLight : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExploreGameCard extends StatelessWidget {
  const _ExploreGameCard({
    required this.game,
    required this.index,
    required this.onTap,
  });

  final ExploreGameModel game;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + index * 40),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      ),
      child: RepaintBoundary(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.glassBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              fit: StackFit.expand,
              children: [
                RepaintBoundary(
                  child: GameArtwork(
                    key: ValueKey('explore_${game.id}_${game.coverUrl ?? ''}'),
                    title: game.title,
                    imageUrl: game.coverUrl,
                    assetPath: game.coverAssetPath,
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.35),
                        Colors.black.withValues(alpha: 0.88),
                      ],
                      stops: const [0.35, 0.7, 1],
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.offline_bolt_rounded,
                            color: AppColors.primaryLight, size: 11),
                        SizedBox(width: 3),
                        Text(
                          'Ready',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        game.title,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sega Genesis',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}

class _ScanBottomSheet extends ConsumerStatefulWidget {
  const _ScanBottomSheet({required this.onScan, required this.onImportFiles});
  final void Function(List<String>) onScan;
  final void Function(List<String>) onImportFiles;

  @override
  ConsumerState<_ScanBottomSheet> createState() => _ScanBottomSheetState();
}

class _ScanBottomSheetState extends ConsumerState<_ScanBottomSheet> {
  final _selectedFolders = <String>[];

  Future<void> _pickFolder() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select ROM Folder',
    );
    if (result != null && !_selectedFolders.contains(result)) {
      setState(() => _selectedFolders.add(result));
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['bin', 'md', 'gen', 'smd', '32x'],
      allowMultiple: true,
      dialogTitle: 'Select ROM Files',
    );
    if (result != null && result.paths.isNotEmpty) {
      final paths = result.paths.whereType<String>().toList();
      if (paths.isNotEmpty) widget.onImportFiles(paths);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Add games', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 6),
            Text(
              'Scan a folder or import individual ROM files into your library.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 22),
            if (_selectedFolders.isNotEmpty)
              ..._selectedFolders.map(
                (f) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.folder_rounded,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          f,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.textMuted, size: 18),
                        onPressed: () =>
                            setState(() => _selectedFolders.remove(f)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFolder,
                    icon: const Icon(Icons.folder_open_rounded, size: 18),
                    label: const Text('Folder'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFiles,
                    icon: const Icon(Icons.file_open_rounded, size: 18),
                    label: const Text('ROM files'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.glassBorder),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () async {
                  const url = 'https://romsfun.com/roms/sega-genesis/';
                  try {
                    await launchUrlString(url,
                        mode: LaunchMode.externalApplication);
                  } catch (e) {
                    debugPrint('Error launching RomsFun url: $e');
                  }
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Find ROMs online'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textMuted,
                ),
              ),
            ),
            if (_selectedFolders.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => widget.onScan(_selectedFolders),
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: const Text('Scan folder'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
