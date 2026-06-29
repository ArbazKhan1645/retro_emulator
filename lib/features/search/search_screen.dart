import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/models/game_model.dart';
import '../../shared/widgets/game_card_widget.dart';
import '../library/providers/library_provider.dart';
import '../search/providers/search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final libraryState = ref.watch(libraryProvider);

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
          child: Column(
            children: [
              _buildSearchBar(context),
              _buildFilterRow(searchState, libraryState),
              Expanded(
                child: searchState.query.isEmpty
                    ? _buildSuggestions(libraryState)
                    : _buildResults(searchState.results),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 840;
    return Padding(
      padding: EdgeInsets.fromLTRB(wide ? 30 : 20, 24, wide ? 30 : 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Find your next game', style: AppTextStyles.displayMedium),
          const SizedBox(height: 5),
          Text(
            'Search your library by title, genre, or developer.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 20),
          Container(
            constraints: const BoxConstraints(maxWidth: 720),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: _focusNode.hasFocus
                    ? AppColors.primary
                    : AppColors.glassBorder,
                width: _focusNode.hasFocus ? 1.5 : 0.8,
              ),
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: AppTextStyles.bodyLarge
                  .copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search games, developers...',
                hintStyle: AppTextStyles.bodyMedium,
                border: InputBorder.none,
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textMuted,
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: AppColors.textMuted),
                        onPressed: () {
                          _controller.clear();
                          ref.read(searchProvider.notifier).search('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (q) => ref.read(searchProvider.notifier).search(q),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(SearchState searchState, LibraryState libraryState) {
    final genres = libraryState.availableGenres;

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.sizeOf(context).width >= 840 ? 30 : 20,
        ),
        children: [
          FilterChip(
            label: const Text('Favorites'),
            selected: searchState.favoritesOnly,
            onSelected: (v) =>
                ref.read(searchProvider.notifier).setFavoritesOnly(v),
            avatar: const Icon(Icons.favorite_rounded, size: 14),
          ),
          const SizedBox(width: 8),
          ...genres.map(
            (g) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(g),
                selected: searchState.selectedGenre == g,
                onSelected: (_) => ref.read(searchProvider.notifier).setGenre(
                      searchState.selectedGenre == g ? null : g,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions(LibraryState libraryState) {
    final recentlyPlayed =
        libraryState.games.where((g) => g.lastPlayed != null).take(6).toList();
    final favorites =
        libraryState.games.where((g) => g.isFavorite).take(6).toList();

    if (libraryState.games.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_rounded,
                size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('Start typing to search your library',
                style: AppTextStyles.bodyMedium),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        if (recentlyPlayed.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child:
                  Text('Recently Played', style: AppTextStyles.headlineSmall),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 230,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: recentlyPlayed.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => GameCardWidget(
                  game: recentlyPlayed[i],
                  onTap: () => context.push('/game/${recentlyPlayed[i].id}'),
                  onFavoriteTap: () {},
                  width: 158,
                  height: 230,
                  animationDelay: Duration(milliseconds: i * 40),
                ),
              ),
            ),
          ),
        ],
        if (favorites.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text('Favorites', style: AppTextStyles.headlineSmall),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 230,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: favorites.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => GameCardWidget(
                  game: favorites[i],
                  onTap: () => context.push('/game/${favorites[i].id}'),
                  onFavoriteTap: () {},
                  width: 158,
                  height: 230,
                  animationDelay: Duration(milliseconds: i * 40),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResults(List<GameModel> results) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('No results', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            Text('Try different keywords', style: AppTextStyles.bodyMedium),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
        childAspectRatio: 150 / 210,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final game = results[index];
        return GameCardWidget(
          game: game,
          onTap: () => context.push('/game/${game.id}'),
          onFavoriteTap: () {},
          animationDelay: Duration(milliseconds: index * 40),
        );
      },
    );
  }
}
