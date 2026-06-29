import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_model.dart';
import '../models/save_state_model.dart';
import '../models/play_history_model.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService._();
});

final sharedPrefsProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

/// Handles all local data persistence for RetroVerse.
///
/// Call [init] once at app startup before using any other methods.
/// Data is stored under the app documents directory:
///   - games.json
///   - save_states.json
///   - play_history.json
///   - save_states/ (binary state files)
///   - thumbnails/  (screenshot thumbnails)
///   - bios/        (BIOS files)
class StorageService {
  StorageService._();

  SharedPreferences? _prefs;
  String? _docsPath;

  /// Initializes the service: sets up SharedPreferences and ensures
  /// required directories exist on disk.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final dir = await getApplicationDocumentsDirectory();
    _docsPath = dir.path;
    await _ensureDirs();
  }

  Future<void> _ensureDirs() async {
    final dirs = [
      '$_docsPath/retroverse',
      '$_docsPath/retroverse/save_states',
      '$_docsPath/retroverse/thumbnails',
      '$_docsPath/retroverse/bios',
    ];
    for (final d in dirs) {
      await Directory(d).create(recursive: true);
    }
  }

  String get _retroversePath => '$_docsPath/retroverse';
  String get _gamesJsonPath => '$_retroversePath/games.json';
  String get _saveStatesJsonPath => '$_retroversePath/save_states.json';
  String get _historyJsonPath => '$_retroversePath/play_history.json';

  /// Directory where binary save state files are stored.
  String get saveStatesDir => '$_retroversePath/save_states';

  /// Directory where save-state thumbnail images are stored.
  String get thumbnailsDir => '$_retroversePath/thumbnails';

  /// Directory where console BIOS files should be placed.
  String get biosDir => '$_retroversePath/bios';

  // ========== GAMES ==========

  /// Loads all games from disk. Returns an empty list on failure.
  Future<List<GameModel>> loadGames() async {
    try {
      final file = File(_gamesJsonPath);
      if (!await file.exists()) return [];
      final contents = await file.readAsString();
      final list = jsonDecode(contents) as List<dynamic>;
      return list
          .map((e) => GameModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Persists the full games list to disk.
  Future<void> saveGames(List<GameModel> games) async {
    final file = File(_gamesJsonPath);
    await file.writeAsString(
      jsonEncode(games.map((g) => g.toJson()).toList()),
    );
  }

  /// Adds a new game or updates an existing one (matched by [GameModel.id]).
  Future<void> addGame(GameModel game) async {
    final games = await loadGames();
    final idx = games.indexWhere((g) => g.id == game.id);
    if (idx >= 0) {
      games[idx] = game;
    } else {
      games.add(game);
    }
    await saveGames(games);
  }

  /// Updates an existing game record. Delegates to [addGame].
  Future<void> updateGame(GameModel game) async => addGame(game);

  /// Removes a game with the given [gameId] from storage.
  Future<void> deleteGame(String gameId) async {
    final games = await loadGames();
    games.removeWhere((g) => g.id == gameId);
    await saveGames(games);
  }

  /// Returns a single game by [gameId], or null if not found.
  Future<GameModel?> getGame(String gameId) async {
    final games = await loadGames();
    try {
      return games.firstWhere((g) => g.id == gameId);
    } catch (_) {
      return null;
    }
  }

  // ========== SAVE STATES ==========

  /// Loads all save states. Optionally filter by [gameId].
  Future<List<SaveStateModel>> loadSaveStates({String? gameId}) async {
    try {
      final file = File(_saveStatesJsonPath);
      if (!await file.exists()) return [];
      final contents = await file.readAsString();
      final list = jsonDecode(contents) as List<dynamic>;
      final states = list
          .map((e) => SaveStateModel.fromJson(e as Map<String, dynamic>))
          .toList();
      if (gameId != null) {
        return states.where((s) => s.gameId == gameId).toList();
      }
      return states;
    } catch (e) {
      return [];
    }
  }

  /// Persists the full save states list to disk.
  Future<void> saveSaveStates(List<SaveStateModel> states) async {
    final file = File(_saveStatesJsonPath);
    await file.writeAsString(
      jsonEncode(states.map((s) => s.toJson()).toList()),
    );
  }

  /// Adds a new save state or updates an existing one.
  Future<void> addSaveState(SaveStateModel state) async {
    final states = await loadSaveStates();
    final idx = states.indexWhere((s) => s.id == state.id);
    if (idx >= 0) {
      states[idx] = state;
    } else {
      states.add(state);
    }
    await saveSaveStates(states);
  }

  /// Removes a save state with the given [stateId].
  Future<void> deleteSaveState(String stateId) async {
    final states = await loadSaveStates();
    states.removeWhere((s) => s.id == stateId);
    await saveSaveStates(states);
  }

  /// Deletes all save states and their corresponding screenshot thumbnails.
  Future<void> clearAllSaveStates() async {
    try {
      final sDir = Directory(saveStatesDir);
      if (await sDir.exists()) {
        await for (final entity in sDir.list()) {
          if (entity is File) await entity.delete();
        }
      }
      final tDir = Directory(thumbnailsDir);
      if (await tDir.exists()) {
        await for (final entity in tDir.list()) {
          if (entity is File) await entity.delete();
        }
      }
      await saveSaveStates([]);
      debugPrint('All save states and thumbnails cleared from storage.');
    } catch (e) {
      debugPrint('Error clearing save states: $e');
    }
  }

  // ========== PLAY HISTORY ==========

  /// Loads the full play history from disk.
  Future<List<PlayHistoryModel>> loadPlayHistory() async {
    try {
      final file = File(_historyJsonPath);
      if (!await file.exists()) return [];
      final contents = await file.readAsString();
      final list = jsonDecode(contents) as List<dynamic>;
      return list
          .map((e) => PlayHistoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Appends a play session to history. Keeps at most 1,000 recent entries.
  Future<void> addPlaySession(PlayHistoryModel session) async {
    final history = await loadPlayHistory();
    history.add(session);
    // Keep last 1000 sessions
    if (history.length > 1000) history.removeAt(0);
    final file = File(_historyJsonPath);
    await file.writeAsString(
      jsonEncode(history.map((h) => h.toJson()).toList()),
    );
  }

  // ========== SHARED PREFERENCES ==========

  /// Gets a setting value typed as [T] from SharedPreferences.
  /// Returns null if the key does not exist or the type does not match.
  T? getSetting<T>(String key) {
    if (_prefs == null) return null;
    final value = _prefs!.get(key);
    if (value is T) return value;
    return null;
  }

  /// Persists a setting value to SharedPreferences.
  /// Supports [String], [int], [double], [bool], and [List<String>].
  Future<bool> setSetting<T>(String key, T value) async {
    if (_prefs == null) return false;
    if (value is String) return _prefs!.setString(key, value);
    if (value is int) return _prefs!.setInt(key, value);
    if (value is double) return _prefs!.setDouble(key, value);
    if (value is bool) return _prefs!.setBool(key, value);
    if (value is List<String>) return _prefs!.setStringList(key, value);
    return false;
  }

  /// Removes a setting key from SharedPreferences.
  Future<bool> removeSetting(String key) async {
    return _prefs?.remove(key) ?? Future.value(false);
  }
}
