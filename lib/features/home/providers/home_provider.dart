import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/game_model.dart';
import '../../library/providers/library_provider.dart';

// ============================================================
// HomeState
// ============================================================

/// Aggregated state for the Home screen, derived entirely from
/// the [libraryProvider]. All lists are pre-sorted and limited
/// to keep UI rendering efficient.
class HomeState {
  /// Featured games shown in the hero carousel (top-rated or with artwork).
  final List<GameModel> heroGames;

  /// Recently played games, sorted by most recent session first.
  final List<GameModel> recentlyPlayed;

  /// Games marked as favorites by the user.
  final List<GameModel> favorites;

  /// Games sorted by total play time, descending.
  final List<GameModel> mostPlayed;

  /// Games sorted by date added, newest first.
  final List<GameModel> recentlyAdded;

  /// Full unfiltered game list for quick access.
  final List<GameModel> allGames;

  /// Games grouped by genre string.
  final Map<String, List<GameModel>> byGenre;

  /// Whether the underlying library is still loading.
  final bool isLoading;

  const HomeState({
    this.heroGames = const [],
    this.recentlyPlayed = const [],
    this.favorites = const [],
    this.mostPlayed = const [],
    this.recentlyAdded = const [],
    this.allGames = const [],
    this.byGenre = const {},
    this.isLoading = true,
  });

  // ----------------------------------------------------------------
  // Convenience helpers
  // ----------------------------------------------------------------

  /// True when the library has been loaded but contains no games.
  bool get isEmpty => !isLoading && allGames.isEmpty;

  /// True when the library has at least one game.
  bool get hasGames => allGames.isNotEmpty;

  /// Sorted list of genres that have at least one game.
  List<String> get availableGenres => (byGenre.keys.toList()..sort());
}

// ============================================================
// homeProvider – pure derivation from libraryProvider
// ============================================================

/// Read-only [Provider] that derives home-screen sections from
/// the [libraryProvider] state.
///
/// This provider is intentionally a plain [Provider] (not a [StateNotifier])
/// because it has no independent state — it reacts to library changes
/// automatically via [ref.watch].
///
/// Usage:
/// ```dart
/// final home = ref.watch(homeProvider);
/// ```
final homeProvider = Provider<HomeState>((ref) {
  final libraryState = ref.watch(libraryProvider);
  final games = libraryState.games;

  // ---- Still loading ----
  if (libraryState.isLoading) {
    return const HomeState(isLoading: true);
  }

  // ---- Empty library ----
  if (games.isEmpty) {
    return const HomeState(isLoading: false);
  }

  // ---- Recently played (sorted by lastPlayed desc, has session) ----
  final recentlyPlayed = games.where((g) => g.lastPlayed != null).toList()
    ..sort((a, b) => b.lastPlayed!.compareTo(a.lastPlayed!));

  // ---- Favorites ----
  final favorites = games.where((g) => g.isFavorite).toList();

  // ---- Most played (by total play time) ----
  final mostPlayed = List<GameModel>.from(games)
    ..sort((a, b) => b.playTimeSeconds.compareTo(a.playTimeSeconds));

  // ---- Recently added (by addedAt timestamp) ----
  final recentlyAdded = List<GameModel>.from(games)
    ..sort((a, b) => b.addedAt.compareTo(a.addedAt));

  // ---- Hero games: games with artwork or a positive rating ----
  final heroCandidate =
      games.where((g) => g.rating > 0 || g.coverUrl != null).take(5).toList();

  // Fall back to the five most-recently-added if no artwork is available.
  final heroGames =
      heroCandidate.isEmpty ? games.take(5).toList() : heroCandidate;

  // ---- By genre map ----
  final Map<String, List<GameModel>> byGenre = {};
  for (final game in games) {
    if (game.genre != null && game.genre!.isNotEmpty) {
      byGenre.putIfAbsent(game.genre!, () => []).add(game);
    }
  }

  return HomeState(
    heroGames: heroGames,
    recentlyPlayed: recentlyPlayed.take(20).toList(),
    favorites: favorites.take(20).toList(),
    mostPlayed: mostPlayed.take(20).toList(),
    recentlyAdded: recentlyAdded.take(20).toList(),
    allGames: games,
    byGenre: byGenre,
    isLoading: false,
  );
});
