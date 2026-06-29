import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/game_model.dart';
import '../../../shared/models/save_state_model.dart';
import '../../../shared/services/storage_service.dart';
import '../../../native_bridge/emulator_bridge.dart';
import '../../../core/constants/app_constants.dart';

// ============================================================
// EmulatorStatus
// ============================================================

/// Represents the lifecycle state of the emulator core.
enum EmulatorStatus {
  /// No game is loaded; core is idle.
  idle,

  /// A ROM is currently being loaded into the core.
  loading,

  /// The core is actively running and rendering frames.
  running,

  /// The core is suspended; no frames are being produced.
  paused,

  /// An unrecoverable error has occurred.
  error,
}

// ============================================================
// EmulatorState
// ============================================================

/// Immutable state snapshot for the active emulation session.
class EmulatorState {
  /// The [GameModel] currently loaded, or null if idle.
  final GameModel? currentGame;

  /// Current lifecycle status of the emulator core.
  final EmulatorStatus status;

  /// Human-readable error message, set when [status] is [EmulatorStatus.error].
  final String? error;

  /// Whether audio output is muted.
  final bool isMuted;

  /// Whether the emulator UI is displayed in fullscreen mode.
  final bool isFullscreen;

  /// Whether the on-screen touch controls overlay is visible.
  final bool showControls;

  /// Whether the in-game quick menu is open.
  final bool showQuickMenu;

  /// Current measured frames per second.
  final int fps;

  /// Whether fast-forward mode is currently active.
  final bool isFastForwarding;

  /// Whether rewind playback is currently active.
  final bool isRewinding;

  /// Currently selected save-state slot index (0-based).
  final int currentSaveSlot;

  /// Master audio volume level (0.0 – 1.0).
  final double volume;

  const EmulatorState({
    this.currentGame,
    this.status = EmulatorStatus.idle,
    this.error,
    this.isMuted = false,
    this.isFullscreen = false,
    this.showControls = true,
    this.showQuickMenu = false,
    this.fps = 0,
    this.isFastForwarding = false,
    this.isRewinding = false,
    this.currentSaveSlot = 0,
    this.volume = 0.8,
  });

  /// Returns a new [EmulatorState] with the specified fields replaced.
  EmulatorState copyWith({
    GameModel? currentGame,
    EmulatorStatus? status,
    String? error,
    bool? isMuted,
    bool? isFullscreen,
    bool? showControls,
    bool? showQuickMenu,
    int? fps,
    bool? isFastForwarding,
    bool? isRewinding,
    int? currentSaveSlot,
    double? volume,
  }) {
    return EmulatorState(
      currentGame: currentGame ?? this.currentGame,
      status: status ?? this.status,
      error: error ?? this.error,
      isMuted: isMuted ?? this.isMuted,
      isFullscreen: isFullscreen ?? this.isFullscreen,
      showControls: showControls ?? this.showControls,
      showQuickMenu: showQuickMenu ?? this.showQuickMenu,
      fps: fps ?? this.fps,
      isFastForwarding: isFastForwarding ?? this.isFastForwarding,
      isRewinding: isRewinding ?? this.isRewinding,
      currentSaveSlot: currentSaveSlot ?? this.currentSaveSlot,
      volume: volume ?? this.volume,
    );
  }

  // ----------------------------------------------------------------
  // Convenience helpers
  // ----------------------------------------------------------------

  /// True while a game is loaded and the core is not in an error state.
  bool get isActive =>
      status == EmulatorStatus.running || status == EmulatorStatus.paused;

  /// True if the core is actively producing frames.
  bool get isRunning => status == EmulatorStatus.running;

  /// True if the session is suspended.
  bool get isPaused => status == EmulatorStatus.paused;
}

// ============================================================
// EmulatorNotifier
// ============================================================

/// [StateNotifier] that controls the emulator core lifecycle.
///
/// Wraps [EmulatorBridge] (the native FFI/platform-channel façade) and
/// [StorageService] (for persisting play-time statistics) to provide a
/// clean Riverpod interface to the rest of the application.
class EmulatorNotifier extends StateNotifier<EmulatorState> {
  EmulatorNotifier(this._storage) : super(const EmulatorState());

  final StorageService _storage;
  final EmulatorBridge _bridge = EmulatorBridge.instance;

  /// Tracks when the current play session started, for duration accounting.
  DateTime? _sessionStart;

  // ----------------------------------------------------------------
  // Core lifecycle
  // ----------------------------------------------------------------

  /// Loads the Genesis core and the ROM at [game.romPath], then starts emulation.
  ///
  /// Transitions: idle → loading → running (or error on failure).
  Future<void> loadGame(GameModel game, {String? initialSaveStatePath}) async {
    state = state.copyWith(
      status: EmulatorStatus.loading,
      currentGame: game,
      error: null,
    );

    try {
      await _bridge.loadCore(AppConstants.genesisCoreName);
      await _bridge.loadROM(game.romPath);
      state = state.copyWith(status: EmulatorStatus.running);
      _startPlaySession(game.id);

      if (initialSaveStatePath != null) {
        // Yield to core initialization loop
        await Future.delayed(const Duration(milliseconds: 150));
        await _bridge.loadStateFromFile(initialSaveStatePath);
        debugPrint('Loaded initial save state: $initialSaveStatePath');
      }
    } catch (e) {
      state = state.copyWith(
        status: EmulatorStatus.error,
        error: 'Failed to load game: $e',
      );
    }
  }

  /// Suspends the emulator core.
  void pause() {
    _bridge.pause();
    state = state.copyWith(status: EmulatorStatus.paused);
  }

  /// Resumes the emulator core from a paused state.
  void resume() {
    _bridge.resume();
    state = state.copyWith(status: EmulatorStatus.running);
  }

  /// Resets the active emulation session.
  void reset() {
    _bridge.reset();
  }

  /// Toggles between paused and running states.
  void togglePause() {
    if (state.status == EmulatorStatus.running) {
      pause();
    } else if (state.status == EmulatorStatus.paused) {
      resume();
    }
  }

  /// Stops the emulator, persists play-time statistics, and resets state.
  Future<void> stop() async {
    await _bridge.stop();
    await _endPlaySession();
    state = const EmulatorState();
  }

  // ----------------------------------------------------------------
  // Save / load states
  // ----------------------------------------------------------------

  /// Saves emulator state to [state.currentSaveSlot], persisting file and database metadata.
  Future<void> quickSave() async {
    final game = state.currentGame;
    if (game == null) return;

    final slot = state.currentSaveSlot;
    final timestamp = DateTime.now();
    final stateId =
        '${game.id}_slot_${slot}_${timestamp.millisecondsSinceEpoch}';

    // File paths
    final statePath = p.join(_storage.saveStatesDir, '$stateId.state');
    final thumbPath = p.join(_storage.thumbnailsDir, '$stateId.png');

    // Trigger FFI save
    final success = await _bridge.saveStateToFile(statePath);
    if (success) {
      // Save metadata to storage database
      final saveModel = SaveStateModel(
        id: stateId,
        gameId: game.id,
        slotNumber: slot,
        name:
            'Slot $slot (${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')})',
        thumbnailPath: thumbPath,
        timestamp: timestamp,
        statePath: statePath,
      );

      await _storage.addSaveState(saveModel);

      // Also write to default slot shortcut file for quick load
      final slotPath =
          p.join(_storage.saveStatesDir, '${game.id}_slot_$slot.state');
      final slotFile = File(statePath);
      if (await slotFile.exists()) {
        await slotFile.copy(slotPath);
      }
      debugPrint('Quick save successful for slot $slot.');
    }
  }

  /// Loads emulator state from [state.currentSaveSlot].
  Future<void> quickLoad() async {
    final game = state.currentGame;
    if (game == null) return;

    final slot = state.currentSaveSlot;
    final slotPath =
        p.join(_storage.saveStatesDir, '${game.id}_slot_$slot.state');

    final success = await _bridge.loadStateFromFile(slotPath);
    if (success) {
      debugPrint('Quick load successful for slot $slot.');
    } else {
      debugPrint('Quick load failed: slot file does not exist.');
    }
  }

  /// Loads a specific state file path.
  Future<bool> loadStateFromFile(String filePath) async {
    if (state.currentGame == null) return false;
    return await _bridge.loadStateFromFile(filePath);
  }

  /// Changes the active save-state slot.
  void setSaveSlot(int slot) =>
      state = state.copyWith(currentSaveSlot: slot.clamp(0, 9));

  // ----------------------------------------------------------------
  // Playback control
  // ----------------------------------------------------------------

  /// Enables or disables fast-forward mode.
  void setFastForward(bool enabled) {
    _bridge.setFastForward(enabled);
    state = state.copyWith(isFastForwarding: enabled);
  }

  /// Enables or disables rewind playback.
  void setRewind(bool enabled) {
    _bridge.setRewind(enabled);
    state = state.copyWith(isRewinding: enabled);
  }

  // ----------------------------------------------------------------
  // Audio
  // ----------------------------------------------------------------

  /// Toggles audio mute; restores last volume when un-muting.
  void toggleMute() {
    final muted = !state.isMuted;
    _bridge.setVolume(muted ? 0.0 : state.volume);
    state = state.copyWith(isMuted: muted);
  }

  /// Sets the master volume (clamped 0.0 – 1.0) and un-mutes if needed.
  void setVolume(double volume) {
    final clamped = volume.clamp(0.0, 1.0);
    _bridge.setVolume(clamped);
    state = state.copyWith(volume: clamped, isMuted: clamped == 0.0);
  }

  // ----------------------------------------------------------------
  // UI toggles
  // ----------------------------------------------------------------

  /// Toggles fullscreen display mode.
  void toggleFullscreen() =>
      state = state.copyWith(isFullscreen: !state.isFullscreen);

  /// Shows or hides the on-screen touch controls overlay.
  void toggleControls() =>
      state = state.copyWith(showControls: !state.showControls);

  /// Shows or hides the in-game quick menu.
  void toggleQuickMenu() =>
      state = state.copyWith(showQuickMenu: !state.showQuickMenu);

  // ----------------------------------------------------------------
  // FPS telemetry
  // ----------------------------------------------------------------

  /// Updates the displayed FPS counter from a periodic ticker.
  void updateFps(int fps) => state = state.copyWith(fps: fps);

  // ----------------------------------------------------------------
  // Play-session tracking (private)
  // ----------------------------------------------------------------

  void _startPlaySession(String gameId) {
    _sessionStart = DateTime.now();
  }

  Future<void> _endPlaySession() async {
    if (_sessionStart == null || state.currentGame == null) return;

    final duration = DateTime.now().difference(_sessionStart!).inSeconds;
    _sessionStart = null;

    try {
      await _storage.init();
      final game = state.currentGame!;
      final updated = game.copyWith(
        playTimeSeconds: game.playTimeSeconds + duration,
        lastPlayed: DateTime.now(),
      );
      await _storage.updateGame(updated);
    } catch (_) {
      // Best-effort; do not let stat persistence crash the emulator.
    }
  }
}

// ============================================================
// Provider
// ============================================================

/// Global [StateNotifierProvider] for the emulator session.
///
/// There is at most one active emulator session in the app at any time,
/// so a singleton (non-family) provider is appropriate here.
///
/// Usage:
/// ```dart
/// final emu = ref.watch(emulatorProvider);
/// ref.read(emulatorProvider.notifier).loadGame(game);
/// ```
final emulatorProvider =
    StateNotifierProvider<EmulatorNotifier, EmulatorState>((ref) {
  final storage = ref.read(storageServiceProvider);
  return EmulatorNotifier(storage);
});
