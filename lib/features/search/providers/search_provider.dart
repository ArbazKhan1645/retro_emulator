import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/game_model.dart';
import '../../library/providers/library_provider.dart';

// ============================================================
// SearchState
// ============================================================

/// Immutable state for the Search feature.
///
/// Holds the active query text, all active filter criteria, and the
/// computed list of matching [GameModel] results.
class SearchState {
  /// Active text search query.
  final String query;

  /// Filtered and sorted search results.
  final List<GameModel> results;

  /// Whether a filter/search computation is in progress.
  final bool isSearching;

  /// Optional genre filter; null means no genre restriction.
  final String? selectedGenre;

  /// Optional platform filter; null means no platform restriction.
  final String? selectedPlatform;

  /// Optional release year filter; null means no year restriction.
  final int? selectedYear;

  /// When true, only favorited games appear in results.
  final bool favoritesOnly;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.isSearching = false,
    this.selectedGenre,
    this.selectedPlatform,
    this.selectedYear,
    this.favoritesOnly = false,
  });

  /// Returns a new [SearchState] with the specified fields replaced.
  SearchState copyWith({
    String? query,
    List<GameModel>? results,
    bool? isSearching,
    String? selectedGenre,
    String? selectedPlatform,
    int? selectedYear,
    bool? favoritesOnly,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isSearching: isSearching ?? this.isSearching,
      selectedGenre: selectedGenre ?? this.selectedGenre,
      selectedPlatform: selectedPlatform ?? this.selectedPlatform,
      selectedYear: selectedYear ?? this.selectedYear,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
    );
  }

  // ----------------------------------------------------------------
  // Convenience helpers
  // ----------------------------------------------------------------

  /// True if at least one filter or a non-empty query is active.
  bool get hasActiveFilters =>
      query.isNotEmpty ||
      selectedGenre != null ||
      selectedPlatform != null ||
      selectedYear != null ||
      favoritesOnly;

  /// Total number of matching results.
  int get resultCount => results.length;
}

// ============================================================
// SearchNotifier
// ============================================================

/// [StateNotifier] that manages search state and filtering logic.
///
/// Accepts the complete game list from [libraryProvider] at construction
/// time. All filtering is performed synchronously in [_applyFilters].
class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier(this._allGames) : super(const SearchState()) {
    // Show all games when the screen first opens (empty query).
    _applyFilters();
  }

  /// Full game list injected from the library provider.
  final List<GameModel> _allGames;

  // ----------------------------------------------------------------
  // Public API
  // ----------------------------------------------------------------

  /// Updates the search query and re-applies all active filters.
  void search(String query) {
    state = state.copyWith(query: query, isSearching: true);
    _applyFilters();
  }

  /// Restricts results to the given [genre], or clears the filter if null.
  void setGenre(String? genre) {
    state = state.copyWith(selectedGenre: genre);
    _applyFilters();
  }

  /// Restricts results to the given [platform], or clears the filter if null.
  void setPlatform(String? platform) {
    state = state.copyWith(selectedPlatform: platform);
    _applyFilters();
  }

  /// Restricts results to games released in [year], or clears if null.
  void setYear(int? year) {
    state = state.copyWith(selectedYear: year);
    _applyFilters();
  }

  /// When [value] is true, only favorited games are included in results.
  void setFavoritesOnly(bool value) {
    state = state.copyWith(favoritesOnly: value);
    _applyFilters();
  }

  /// Resets all filters and the search query, showing all games.
  void clearFilters() {
    state = const SearchState();
    _applyFilters();
  }

  // ----------------------------------------------------------------
  // Internal
  // ----------------------------------------------------------------

  /// Applies all active filters to [_allGames] and updates [state.results].
  void _applyFilters() {
    var results = List<GameModel>.from(_allGames);

    // ---- Text query (title, developer, genre) ----
    if (state.query.isNotEmpty) {
      final q = state.query.toLowerCase();
      results = results
          .where((g) =>
              g.title.toLowerCase().contains(q) ||
              (g.developer ?? '').toLowerCase().contains(q) ||
              (g.genre ?? '').toLowerCase().contains(q))
          .toList();
    }

    // ---- Genre ----
    if (state.selectedGenre != null) {
      results = results.where((g) => g.genre == state.selectedGenre).toList();
    }

    // ---- Platform ----
    if (state.selectedPlatform != null) {
      results = results
          .where((g) => g.consolePlatform == state.selectedPlatform)
          .toList();
    }

    // ---- Release year ----
    if (state.selectedYear != null) {
      results =
          results.where((g) => g.releaseYear == state.selectedYear).toList();
    }

    // ---- Favorites only ----
    if (state.favoritesOnly) {
      results = results.where((g) => g.isFavorite).toList();
    }

    // ---- Default sort: alphabetical ----
    results.sort((a, b) => a.title.compareTo(b.title));

    state = state.copyWith(results: results, isSearching: false);
  }
}

// ============================================================
// Provider
// ============================================================

/// Global [StateNotifierProvider] for search functionality.
///
/// Re-created automatically when the library game list changes,
/// so search results always reflect the current library contents.
///
/// Usage:
/// ```dart
/// final search = ref.watch(searchProvider);
/// ref.read(searchProvider.notifier).search('sonic');
/// ```
final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  // Watch the full game list so the notifier re-creates itself on
  // library changes (e.g. after a scan or deletion).
  final games = ref.watch(libraryProvider).games;
  return SearchNotifier(games);
});
