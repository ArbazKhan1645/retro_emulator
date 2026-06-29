import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/save_state_model.dart';
import '../../../shared/services/storage_service.dart';

// ============================================================
// SaveStatesState
// ============================================================

/// Immutable state for the save-states feature for a single game.
class SaveStatesState {
  /// All save states for the current game, sorted newest-first.
  final List<SaveStateModel> states;

  /// Whether the initial load is in progress.
  final bool isLoading;

  /// Human-readable error message, or null if there is no error.
  final String? error;

  const SaveStatesState({
    this.states = const [],
    this.isLoading = false,
    this.error,
  });

  /// Returns a new [SaveStatesState] with the specified fields replaced.
  SaveStatesState copyWith({
    List<SaveStateModel>? states,
    bool? isLoading,
    String? error,
  }) {
    return SaveStatesState(
      states: states ?? this.states,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  // ----------------------------------------------------------------
  // Convenience helpers
  // ----------------------------------------------------------------

  /// True when there are no save states and loading is complete.
  bool get isEmpty => !isLoading && states.isEmpty;

  /// The most-recent save state, or null if there are none.
  SaveStateModel? get latestState => states.isEmpty ? null : states.first;
}

// ============================================================
// SaveStatesNotifier
// ============================================================

/// [StateNotifier] that manages save-state persistence for a single game.
///
/// Parameterised by [_gameId] so each game gets its own independent
/// provider instance via the [saveStatesProvider] family.
class SaveStatesNotifier extends StateNotifier<SaveStatesState> {
  SaveStatesNotifier(this._storage, this._gameId)
      : super(const SaveStatesState()) {
    loadStates();
  }

  final StorageService _storage;
  final String _gameId;

  // ----------------------------------------------------------------
  // Loading
  // ----------------------------------------------------------------

  /// Loads all save states for [_gameId] from storage, sorted newest-first.
  Future<void> loadStates() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _storage.init();
      final states = await _storage.loadSaveStates(gameId: _gameId);
      // Always display the newest state at the top.
      states.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      state = state.copyWith(states: states, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load saves: $e',
      );
    }
  }

  // ----------------------------------------------------------------
  // Mutations
  // ----------------------------------------------------------------

  /// Permanently deletes the save state with [stateId].
  Future<void> deleteSaveState(String stateId) async {
    try {
      await _storage.init();
      await _storage.deleteSaveState(stateId);
      final updated = state.states.where((s) => s.id != stateId).toList();
      state = state.copyWith(states: updated);
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete save: $e');
    }
  }

  /// Renames the save state with [stateId] to [newName].
  ///
  /// Updates both the in-memory list and the persisted record.
  Future<void> renameSaveState(String stateId, String newName) async {
    final idx = state.states.indexWhere((s) => s.id == stateId);
    if (idx < 0) return;

    try {
      await _storage.init();
      final updated = state.states[idx].copyWith(name: newName);
      await _storage.addSaveState(updated);
      final states = List<SaveStateModel>.from(state.states);
      states[idx] = updated;
      state = state.copyWith(states: states);
    } catch (e) {
      state = state.copyWith(error: 'Failed to rename save: $e');
    }
  }

  /// Clears any error message from the state.
  void clearError() => state = state.copyWith(error: null);
}

// ============================================================
// Provider (family)
// ============================================================

/// Family [StateNotifierProvider] scoped to a specific game ID.
///
/// Each game gets an independent [SaveStatesNotifier] instance so that
/// save-state data is lazily loaded only when the user views a game.
///
/// Usage:
/// ```dart
/// final saves = ref.watch(saveStatesProvider('game-id-123'));
/// ref.read(saveStatesProvider('game-id-123').notifier)
///    .deleteSaveState(stateId);
/// ```
final saveStatesProvider =
    StateNotifierProvider.family<SaveStatesNotifier, SaveStatesState, String>(
  (ref, gameId) {
    final storage = ref.read(storageServiceProvider);
    return SaveStatesNotifier(storage, gameId);
  },
);
