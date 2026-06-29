import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/game_model.dart';
import '../../../shared/services/storage_service.dart';
import '../../../shared/services/rom_scanner_service.dart';
import '../../../shared/services/cover_art_service.dart';

// ============================================================
// Enumerations
// ============================================================

/// Available sort orders for the game library.
enum LibrarySortBy {
  title,
  lastPlayed,
  playTime,
  rating,
  addedDate,
}

/// Available filter modes for the game library.
enum LibraryFilter {
  all,
  favorites,
  installed,
  recentlyPlayed,
}

// ============================================================
// LibraryState
// ============================================================

/// Immutable state object for the game library feature.
///
/// Exposes [filteredGames] which applies the active search, filter,
/// genre and sort configuration on the full [games] list.
class LibraryState {
  /// Full unfiltered list of games in the library.
  final List<GameModel> games;

  /// Whether the initial library load is in progress.
  final bool isLoading;

  /// Whether a ROM folder scan is currently running.
  final bool isScanning;

  /// Progress information for the active scan, or null if not scanning.
  final ScanProgress? scanProgress;

  /// Human-readable error message, or null if no error.
  final String? error;

  /// Active text search query.
  final String searchQuery;

  /// Active sort order applied to [filteredGames].
  final LibrarySortBy sortBy;

  /// Active collection filter applied to [filteredGames].
  final LibraryFilter filter;

  /// Optional genre filter; null means all genres shown.
  final String? selectedGenre;

  /// Optional platform filter; null means all platforms shown.
  final String? selectedPlatform;

  /// Whether the UI is in grid mode (true) or list mode (false).
  final bool isGridView;

  const LibraryState({
    this.games = const [],
    this.isLoading = false,
    this.isScanning = false,
    this.scanProgress,
    this.error,
    this.searchQuery = '',
    this.sortBy = LibrarySortBy.title,
    this.filter = LibraryFilter.all,
    this.selectedGenre,
    this.selectedPlatform,
    this.isGridView = true,
  });

  /// Returns a new [LibraryState] with the given fields replaced.
  LibraryState copyWith({
    List<GameModel>? games,
    bool? isLoading,
    bool? isScanning,
    ScanProgress? scanProgress,
    String? error,
    String? searchQuery,
    LibrarySortBy? sortBy,
    LibraryFilter? filter,
    String? selectedGenre,
    String? selectedPlatform,
    bool? isGridView,
  }) {
    return LibraryState(
      games: games ?? this.games,
      isLoading: isLoading ?? this.isLoading,
      isScanning: isScanning ?? this.isScanning,
      scanProgress: scanProgress ?? this.scanProgress,
      error: error ?? this.error,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      filter: filter ?? this.filter,
      selectedGenre: selectedGenre ?? this.selectedGenre,
      selectedPlatform: selectedPlatform ?? this.selectedPlatform,
      isGridView: isGridView ?? this.isGridView,
    );
  }

  // ----------------------------------------------------------------
  // Derived data
  // ----------------------------------------------------------------

  /// Returns [games] with search, filter, genre selection, and sort applied.
  List<GameModel> get filteredGames {
    var result = List<GameModel>.from(games);

    // ---- Text search ----
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result
          .where((g) =>
              g.title.toLowerCase().contains(q) ||
              (g.developer ?? '').toLowerCase().contains(q))
          .toList();
    }

    // ---- Collection filter ----
    switch (filter) {
      case LibraryFilter.favorites:
        result = result.where((g) => g.isFavorite).toList();
        break;
      case LibraryFilter.installed:
        result = result.where((g) => g.isInstalled).toList();
        break;
      case LibraryFilter.recentlyPlayed:
        result = result.where((g) => g.lastPlayed != null).toList();
        break;
      case LibraryFilter.all:
        break;
    }

    // ---- Genre filter ----
    if (selectedGenre != null) {
      result = result.where((g) => g.genre == selectedGenre).toList();
    }

    // ---- Platform filter ----
    if (selectedPlatform != null) {
      result =
          result.where((g) => g.consolePlatform == selectedPlatform).toList();
    }

    // ---- Sort ----
    switch (sortBy) {
      case LibrarySortBy.title:
        result.sort((a, b) => a.title.compareTo(b.title));
        break;
      case LibrarySortBy.lastPlayed:
        result.sort((a, b) {
          if (a.lastPlayed == null) return 1;
          if (b.lastPlayed == null) return -1;
          return b.lastPlayed!.compareTo(a.lastPlayed!);
        });
        break;
      case LibrarySortBy.playTime:
        result.sort((a, b) => b.playTimeSeconds.compareTo(a.playTimeSeconds));
        break;
      case LibrarySortBy.rating:
        result.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case LibrarySortBy.addedDate:
        result.sort((a, b) => b.addedAt.compareTo(a.addedAt));
        break;
    }

    return result;
  }

  /// Sorted list of unique genre strings present in [games].
  List<String> get availableGenres {
    return games
        .where((g) => g.genre != null)
        .map((g) => g.genre!)
        .toSet()
        .toList()
      ..sort();
  }

  /// Sorted list of unique platform strings present in [games].
  List<String> get availablePlatforms {
    return games.map((g) => g.consolePlatform).toSet().toList()..sort();
  }
}

// ============================================================
// LibraryNotifier
// ============================================================

/// [StateNotifier] that manages the game library state.
///
/// Responsible for loading games from persistent storage, triggering
/// ROM folder scans, toggling favorites, and fetching online metadata.
class LibraryNotifier extends StateNotifier<LibraryState> {
  LibraryNotifier(this._storage, this._scanner, this._coverArt)
      : super(const LibraryState()) {
    loadGames();
  }

  final StorageService _storage;
  final RomScannerService _scanner;
  final CoverArtService _coverArt;

  // ----------------------------------------------------------------
  // Loading
  // ----------------------------------------------------------------

  /// Loads all persisted games from storage into [state.games].
  Future<void> loadGames() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _storage.init();
      final games = await _storage.loadGames();
      state = state.copyWith(games: games, isLoading: false);
      _enrichMissingCoversInBackground();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load games: $e',
      );
    }
  }

  /// Fetches cover art for games that don't have one yet.
  Future<void> _enrichMissingCoversInBackground([List<GameModel>? games]) async {
    final targets = games ??
        state.games
            .where((g) => g.coverUrl == null || g.coverUrl!.isEmpty)
            .toList();
    if (targets.isEmpty) return;

    for (final game in targets) {
      try {
        final enriched = await _coverArt.resolve(game);
        final changed = enriched.coverUrl != game.coverUrl ||
            enriched.description != game.description ||
            enriched.genre != game.genre ||
            enriched.developer != game.developer ||
            enriched.rating != game.rating ||
            enriched.releaseYear != game.releaseYear;
        if (!changed) continue;

        await _storage.init();
        await _storage.updateGame(enriched);
        state = state.copyWith(
          games: state.games
              .map((g) => g.id == enriched.id ? enriched : g)
              .toList(),
        );
      } catch (_) {}
    }
  }

  // ----------------------------------------------------------------
  // Scanning
  // ----------------------------------------------------------------

  /// Scans the given [folders] for ROMs and adds new entries to storage.
  ///
  /// Emits [ScanProgress] updates while the scan is in progress.
  /// Already-tracked ROMs (by path) are skipped to avoid duplicates.
  Future<void> scanFolders(List<String> folders) async {
    if (state.isScanning) return;
    state = state.copyWith(isScanning: true, error: null);
    try {
      await _storage.init();
      final existingPaths = state.games.map((g) => g.romPath).toSet();

      await for (final progress in _scanner.scan(folders)) {
        state = state.copyWith(scanProgress: progress);
        if (progress.isDone && progress.foundGames.isNotEmpty) {
          // Only persist games that are not already in the library.
          final newGames = progress.foundGames
              .where((g) => !existingPaths.contains(g.romPath))
              .toList();
          for (final game in newGames) {
            await _storage.addGame(game);
          }
        }
      }

      await loadGames();
      state = state.copyWith(isScanning: false, scanProgress: null);
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        error: 'Scan failed: $e',
      );
    }
  }

  /// Imports ROM files from the picked file paths, copying them to local persistent storage.
  Future<void> importRomFiles(List<String> filePaths) async {
    if (state.isScanning) return;
    state = state.copyWith(isScanning: true, error: null);
    try {
      await _storage.init();
      final docsDir = await getApplicationDocumentsDirectory();
      final romsDir = Directory(p.join(docsDir.path, 'retroverse', 'roms'));
      await romsDir.create(recursive: true);

      final existingPaths = state.games.map((g) => g.romPath).toSet();
      final List<GameModel> importedGames = [];

      for (int i = 0; i < filePaths.length; i++) {
        final sourcePath = filePaths[i];
        final file = File(sourcePath);
        if (!await file.exists()) continue;

        final fileName = p.basename(sourcePath);
        final destPath = p.join(romsDir.path, fileName);

        // Copy file to persistent app storage
        final destFile = File(destPath);
        if (!await destFile.exists()) {
          await file.copy(destPath);
        }

        final size = await destFile.length();
        final ext = p.extension(destPath).toLowerCase();
        final name = p.basenameWithoutExtension(destPath);

        final game = GameModel(
          id: 'game_${destPath.hashCode.abs()}_${DateTime.now().millisecondsSinceEpoch}',
          title: name
              .replaceAll(RegExp(r'\(.*?\)'), '')
              .replaceAll(RegExp(r'\[.*?\]'), '')
              .replaceAll(RegExp(r'  +'), ' ')
              .trim(),
          romPath: destPath,
          consolePlatform:
              AppConstants.extensionToConsole[ext] ?? 'Sega Genesis',
          fileSizeBytes: size,
          fileExtension: ext,
          addedAt: DateTime.now(),
        );

        if (!existingPaths.contains(destPath)) {
          await _storage.addGame(game);
          importedGames.add(game);
        }

        // Emit progress updates
        state = state.copyWith(
          scanProgress: ScanProgress(
            scanned: i + 1,
            total: filePaths.length,
            currentFile: fileName,
            isDone: i == filePaths.length - 1,
            foundGames: i == filePaths.length - 1 ? importedGames : [],
          ),
        );
      }

      await loadGames();
      state = state.copyWith(isScanning: false, scanProgress: null);
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        error: 'Import failed: $e',
      );
    }
  }

  // ----------------------------------------------------------------
  // CRUD operations
  // ----------------------------------------------------------------

  /// Toggles the favorite status of the game with [gameId].
  Future<void> toggleFavorite(String gameId) async {
    await _storage.init();
    final game = state.games.firstWhere((g) => g.id == gameId);
    final updated = game.copyWith(isFavorite: !game.isFavorite);
    await _storage.updateGame(updated);
    final games = state.games.map((g) => g.id == gameId ? updated : g).toList();
    state = state.copyWith(games: games);
  }

  /// Removes the game with [gameId] from storage and the library.
  Future<void> deleteGame(String gameId) async {
    await _storage.init();
    await _storage.deleteGame(gameId);
    final games = state.games.where((g) => g.id != gameId).toList();
    state = state.copyWith(games: games);
  }

  /// Fetches and applies online metadata for the game with [gameId].
  Future<void> fetchMetadata(String gameId) async {
    final game = state.games.firstWhere((g) => g.id == gameId);
    try {
      final enriched = await _coverArt.resolve(game);
      await _storage.init();
      await _storage.updateGame(enriched);
      final games =
          state.games.map((g) => g.id == gameId ? enriched : g).toList();
      state = state.copyWith(games: games);
    } catch (_) {
      // Metadata fetch is best-effort; silently ignore failures.
    }
  }

  /// Manually adds a [GameModel] to storage and appends it to [state.games].
  Future<void> addGame(GameModel game) async {
    await _storage.init();
    await _storage.addGame(game);
    final games = [...state.games, game];
    state = state.copyWith(games: games);
  }

  // ----------------------------------------------------------------
  // UI state mutations
  // ----------------------------------------------------------------

  /// Updates the active text search query.
  void setSearchQuery(String query) =>
      state = state.copyWith(searchQuery: query);

  /// Changes the active sort order.
  void setSortBy(LibrarySortBy sortBy) =>
      state = state.copyWith(sortBy: sortBy);

  /// Changes the active collection filter.
  void setFilter(LibraryFilter filter) =>
      state = state.copyWith(filter: filter);

  /// Restricts the view to a specific genre, or clears it if [genre] is null.
  void setGenre(String? genre) => state = state.copyWith(selectedGenre: genre);

  /// Restricts the view to a specific platform, or clears it if null.
  void setPlatform(String? platform) =>
      state = state.copyWith(selectedPlatform: platform);

  /// Toggles between grid and list display modes.
  void toggleViewMode() =>
      state = state.copyWith(isGridView: !state.isGridView);
}

// ============================================================
// Provider
// ============================================================

/// Global [StateNotifierProvider] for the game library.
///
/// Usage:
/// ```dart
/// final library = ref.watch(libraryProvider);
/// ref.read(libraryProvider.notifier).toggleFavorite(game.id);
/// ```
final libraryProvider =
    StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  final storage = ref.read(storageServiceProvider);
  final scanner = ref.read(romScannerProvider);
  final coverArt = ref.read(coverArtServiceProvider);
  return LibraryNotifier(storage, scanner, coverArt);
});
