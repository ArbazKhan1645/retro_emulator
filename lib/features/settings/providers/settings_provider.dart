import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

// ============================================================
// AppSettings data class
// ============================================================

/// Immutable data class holding all user-configurable application settings.
/// Persisted to SharedPreferences via [SettingsNotifier].
class AppSettings {
  /// Controls light/dark/system theme selection.
  final AppThemeMode themeMode;

  /// Primary accent color used across the UI.
  final Color accentColor;

  /// Master audio volume level (0.0 – 1.0).
  final double audioVolume;

  /// Whether audio output is enabled.
  final bool audioEnabled;

  /// Opacity of the on-screen touch controls overlay (0.0 – 1.0).
  final double touchControlsOpacity;

  /// Scale multiplier for touch controls (0.5 – 2.0).
  final double touchControlsSize;

  /// Whether touch controls are visible during gameplay.
  final bool touchControlsEnabled;

  /// Active shader/post-processing filter identifier.
  final String shaderFilter;

  /// Display aspect ratio string (e.g. '4:3', '16:9', 'stretch').
  final String aspectRatio;

  /// Speed multiplier when fast-forward is active.
  final int fastForwardSpeed;

  /// Whether the emulator automatically saves state periodically.
  final bool autoSave;

  /// Whether haptic feedback is triggered on button presses.
  final bool hapticFeedback;

  /// Target frames per second for emulation.
  final int targetFps;

  /// List of filesystem paths to scan for ROM files.
  final List<String> scanFolders;

  /// RetroAchievements account username.
  final String raUsername;

  /// RetroAchievements API key.
  final String raApiKey;

  // === CUSTOM TOUCH CONTROLLER LAYOUT ===
  final double dpadOffsetX;
  final double dpadOffsetY;
  final double dpadScale;

  final double actionPadOffsetX;
  final double actionPadOffsetY;
  final double actionPadScale;

  final double lShoulderOffsetX;
  final double lShoulderOffsetY;
  final double lShoulderScale;

  final double rShoulderOffsetX;
  final double rShoulderOffsetY;
  final double rShoulderScale;

  final double centerOffsetX;
  final double centerOffsetY;
  final double centerScale;

  const AppSettings({
    this.themeMode = AppThemeMode.dark,
    this.accentColor = const Color(0xFF7C3AED),
    this.audioVolume = 0.8,
    this.audioEnabled = true,
    this.touchControlsOpacity = 0.7,
    this.touchControlsSize = 1.0,
    this.touchControlsEnabled = true,
    this.shaderFilter = 'pixel_perfect',
    this.aspectRatio = '4:3',
    this.fastForwardSpeed = 3,
    this.autoSave = true,
    this.hapticFeedback = true,
    this.targetFps = 60,
    this.scanFolders = const [],
    this.raUsername = '',
    this.raApiKey = '',
    this.dpadOffsetX = 0.0,
    this.dpadOffsetY = 0.0,
    this.dpadScale = 1.0,
    this.actionPadOffsetX = 0.0,
    this.actionPadOffsetY = 0.0,
    this.actionPadScale = 1.0,
    this.lShoulderOffsetX = 0.0,
    this.lShoulderOffsetY = 0.0,
    this.lShoulderScale = 1.0,
    this.rShoulderOffsetX = 0.0,
    this.rShoulderOffsetY = 0.0,
    this.rShoulderScale = 1.0,
    this.centerOffsetX = 0.0,
    this.centerOffsetY = 0.0,
    this.centerScale = 1.0,
  });

  /// Returns a new [AppSettings] with optionally overridden fields.
  AppSettings copyWith({
    AppThemeMode? themeMode,
    Color? accentColor,
    double? audioVolume,
    bool? audioEnabled,
    double? touchControlsOpacity,
    double? touchControlsSize,
    bool? touchControlsEnabled,
    String? shaderFilter,
    String? aspectRatio,
    int? fastForwardSpeed,
    bool? autoSave,
    bool? hapticFeedback,
    int? targetFps,
    List<String>? scanFolders,
    String? raUsername,
    String? raApiKey,
    double? dpadOffsetX,
    double? dpadOffsetY,
    double? dpadScale,
    double? actionPadOffsetX,
    double? actionPadOffsetY,
    double? actionPadScale,
    double? lShoulderOffsetX,
    double? lShoulderOffsetY,
    double? lShoulderScale,
    double? rShoulderOffsetX,
    double? rShoulderOffsetY,
    double? rShoulderScale,
    double? centerOffsetX,
    double? centerOffsetY,
    double? centerScale,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      audioVolume: audioVolume ?? this.audioVolume,
      audioEnabled: audioEnabled ?? this.audioEnabled,
      touchControlsOpacity: touchControlsOpacity ?? this.touchControlsOpacity,
      touchControlsSize: touchControlsSize ?? this.touchControlsSize,
      touchControlsEnabled: touchControlsEnabled ?? this.touchControlsEnabled,
      shaderFilter: shaderFilter ?? this.shaderFilter,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      fastForwardSpeed: fastForwardSpeed ?? this.fastForwardSpeed,
      autoSave: autoSave ?? this.autoSave,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      targetFps: targetFps ?? this.targetFps,
      scanFolders: scanFolders ?? this.scanFolders,
      raUsername: raUsername ?? this.raUsername,
      raApiKey: raApiKey ?? this.raApiKey,
      dpadOffsetX: dpadOffsetX ?? this.dpadOffsetX,
      dpadOffsetY: dpadOffsetY ?? this.dpadOffsetY,
      dpadScale: dpadScale ?? this.dpadScale,
      actionPadOffsetX: actionPadOffsetX ?? this.actionPadOffsetX,
      actionPadOffsetY: actionPadOffsetY ?? this.actionPadOffsetY,
      actionPadScale: actionPadScale ?? this.actionPadScale,
      lShoulderOffsetX: lShoulderOffsetX ?? this.lShoulderOffsetX,
      lShoulderOffsetY: lShoulderOffsetY ?? this.lShoulderOffsetY,
      lShoulderScale: lShoulderScale ?? this.lShoulderScale,
      rShoulderOffsetX: rShoulderOffsetX ?? this.rShoulderOffsetX,
      rShoulderOffsetY: rShoulderOffsetY ?? this.rShoulderOffsetY,
      rShoulderScale: rShoulderScale ?? this.rShoulderScale,
      centerOffsetX: centerOffsetX ?? this.centerOffsetX,
      centerOffsetY: centerOffsetY ?? this.centerOffsetY,
      centerScale: centerScale ?? this.centerScale,
    );
  }
}

// ============================================================
// SettingsNotifier
// ============================================================

/// [StateNotifier] that manages [AppSettings] persistence.
///
/// On construction, immediately reads from [SharedPreferences].
/// Each setter method updates the in-memory state and writes through
/// to the preference store atomically.
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _loadFromPrefs();
  }

  SharedPreferences? _prefs;

  // ----------------------------------------------------------------
  // Hydration
  // ----------------------------------------------------------------

  /// Reads all settings from [SharedPreferences] and hydrates [state].
  Future<void> _loadFromPrefs() async {
    _prefs = await SharedPreferences.getInstance();

    final themeModeIndex = _prefs!.getInt(AppConstants.keyThemeMode) ?? 0;
    final accentColorValue =
        _prefs!.getInt(AppConstants.keyAccentColor) ?? 0xFF7C3AED;
    final audioVolume = _prefs!.getDouble(AppConstants.keyAudioVolume) ?? 0.8;
    final audioEnabled = _prefs!.getBool(AppConstants.keyAudioEnabled) ?? true;
    final touchOpacity =
        _prefs!.getDouble(AppConstants.keyTouchControlsOpacity) ?? 0.7;
    final touchSize =
        _prefs!.getDouble(AppConstants.keyTouchControlsSize) ?? 1.0;
    final touchEnabled =
        _prefs!.getBool(AppConstants.keyTouchControlsEnabled) ?? true;
    final shaderFilter = _prefs!.getString(AppConstants.keyShaderFilter) ??
        AppConstants.defaultShaderFilter;
    final aspectRatio = _prefs!.getString(AppConstants.keyAspectRatio) ??
        AppConstants.defaultAspectRatio;
    final ffSpeed = _prefs!.getInt(AppConstants.keyFastForwardSpeed) ??
        AppConstants.defaultFastForwardSpeed;
    final autoSave = _prefs!.getBool(AppConstants.keyAutoSave) ?? true;
    final haptic = _prefs!.getBool(AppConstants.keyHapticFeedback) ?? true;
    final fps = _prefs!.getInt(AppConstants.keyTargetFps) ?? 60;
    final foldersJson =
        _prefs!.getStringList(AppConstants.keyScanFolders) ?? [];
    final raUser = _prefs!.getString(AppConstants.keyRaUsername) ?? '';
    final raKey = _prefs!.getString(AppConstants.keyRaApiKey) ?? '';

    // Load custom layout coordinates and scales
    final dpadX = _prefs!.getDouble('layout_dpad_x') ?? 0.0;
    final dpadY = _prefs!.getDouble('layout_dpad_y') ?? 0.0;
    final dpadS = _prefs!.getDouble('layout_dpad_s') ?? 1.0;

    final actionX = _prefs!.getDouble('layout_action_x') ?? 0.0;
    final actionY = _prefs!.getDouble('layout_action_y') ?? 0.0;
    final actionS = _prefs!.getDouble('layout_action_s') ?? 1.0;

    final lShX = _prefs!.getDouble('layout_lsh_x') ?? 0.0;
    final lShY = _prefs!.getDouble('layout_lsh_y') ?? 0.0;
    final lShS = _prefs!.getDouble('layout_lsh_s') ?? 1.0;

    final rShX = _prefs!.getDouble('layout_rsh_x') ?? 0.0;
    final rShY = _prefs!.getDouble('layout_rsh_y') ?? 0.0;
    final rShS = _prefs!.getDouble('layout_rsh_s') ?? 1.0;

    final centX = _prefs!.getDouble('layout_cent_x') ?? 0.0;
    final centY = _prefs!.getDouble('layout_cent_y') ?? 0.0;
    final centS = _prefs!.getDouble('layout_cent_s') ?? 1.0;

    state = AppSettings(
      themeMode: AppThemeMode
          .values[themeModeIndex.clamp(0, AppThemeMode.values.length - 1)],
      accentColor: Color(accentColorValue),
      audioVolume: audioVolume,
      audioEnabled: audioEnabled,
      touchControlsOpacity: touchOpacity,
      touchControlsSize: touchSize,
      touchControlsEnabled: touchEnabled,
      shaderFilter: shaderFilter,
      aspectRatio: aspectRatio,
      fastForwardSpeed: ffSpeed,
      autoSave: autoSave,
      hapticFeedback: haptic,
      targetFps: fps,
      scanFolders: foldersJson,
      raUsername: raUser,
      raApiKey: raKey,
      dpadOffsetX: dpadX,
      dpadOffsetY: dpadY,
      dpadScale: dpadS,
      actionPadOffsetX: actionX,
      actionPadOffsetY: actionY,
      actionPadScale: actionS,
      lShoulderOffsetX: lShX,
      lShoulderOffsetY: lShY,
      lShoulderScale: lShS,
      rShoulderOffsetX: rShX,
      rShoulderOffsetY: rShY,
      rShoulderScale: rShS,
      centerOffsetX: centX,
      centerOffsetY: centY,
      centerScale: centS,
    );
  }

  // ----------------------------------------------------------------
  // Setters
  // ----------------------------------------------------------------

  /// Updates [AppThemeMode] and persists to preferences.
  Future<void> setThemeMode(AppThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs?.setInt(AppConstants.keyThemeMode, mode.index);
  }

  /// Updates the accent [Color] and persists its ARGB integer value.
  Future<void> setAccentColor(Color color) async {
    state = state.copyWith(accentColor: color);
    await _prefs?.setInt(AppConstants.keyAccentColor, color.value);
  }

  /// Updates the master audio volume (clamped to 0.0 – 1.0).
  Future<void> setAudioVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    state = state.copyWith(audioVolume: clamped);
    await _prefs?.setDouble(AppConstants.keyAudioVolume, clamped);
  }

  /// Enables or disables audio output.
  Future<void> setAudioEnabled(bool enabled) async {
    state = state.copyWith(audioEnabled: enabled);
    await _prefs?.setBool(AppConstants.keyAudioEnabled, enabled);
  }

  /// Sets the touch controls overlay opacity.
  Future<void> setTouchControlsOpacity(double opacity) async {
    final clamped = opacity.clamp(0.0, 1.0);
    state = state.copyWith(touchControlsOpacity: clamped);
    await _prefs?.setDouble(AppConstants.keyTouchControlsOpacity, clamped);
  }

  /// Sets the touch controls scale multiplier.
  Future<void> setTouchControlsSize(double size) async {
    final clamped = size.clamp(0.5, 2.0);
    state = state.copyWith(touchControlsSize: clamped);
    await _prefs?.setDouble(AppConstants.keyTouchControlsSize, clamped);
  }

  /// Shows or hides the touch controls overlay.
  Future<void> setTouchControlsEnabled(bool enabled) async {
    state = state.copyWith(touchControlsEnabled: enabled);
    await _prefs?.setBool(AppConstants.keyTouchControlsEnabled, enabled);
  }

  /// Changes the active shader / post-processing filter.
  Future<void> setShaderFilter(String filter) async {
    state = state.copyWith(shaderFilter: filter);
    await _prefs?.setString(AppConstants.keyShaderFilter, filter);
  }

  /// Changes the display aspect ratio.
  Future<void> setAspectRatio(String ratio) async {
    state = state.copyWith(aspectRatio: ratio);
    await _prefs?.setString(AppConstants.keyAspectRatio, ratio);
  }

  /// Sets the fast-forward speed multiplier.
  Future<void> setFastForwardSpeed(int speed) async {
    state = state.copyWith(fastForwardSpeed: speed);
    await _prefs?.setInt(AppConstants.keyFastForwardSpeed, speed);
  }

  /// Enables or disables the auto-save feature.
  Future<void> setAutoSave(bool enabled) async {
    state = state.copyWith(autoSave: enabled);
    await _prefs?.setBool(AppConstants.keyAutoSave, enabled);
  }

  /// Enables or disables haptic feedback on button presses.
  Future<void> setHapticFeedback(bool enabled) async {
    state = state.copyWith(hapticFeedback: enabled);
    await _prefs?.setBool(AppConstants.keyHapticFeedback, enabled);
  }

  /// Sets the target emulation frame rate.
  Future<void> setTargetFps(int fps) async {
    state = state.copyWith(targetFps: fps);
    await _prefs?.setInt(AppConstants.keyTargetFps, fps);
  }

  /// Appends a directory path to the ROM scan folders list.
  Future<void> addScanFolder(String path) async {
    if (state.scanFolders.contains(path)) return;
    final folders = [...state.scanFolders, path];
    state = state.copyWith(scanFolders: folders);
    await _prefs?.setStringList(AppConstants.keyScanFolders, folders);
  }

  /// Removes a directory path from the ROM scan folders list.
  Future<void> removeScanFolder(String path) async {
    final folders = state.scanFolders.where((f) => f != path).toList();
    state = state.copyWith(scanFolders: folders);
    await _prefs?.setStringList(AppConstants.keyScanFolders, folders);
  }

  /// Persists RetroAchievements credentials (username + API key).
  Future<void> setRaCredentials(String username, String apiKey) async {
    state = state.copyWith(raUsername: username, raApiKey: apiKey);
    await _prefs?.setString(AppConstants.keyRaUsername, username);
    await _prefs?.setString(AppConstants.keyRaApiKey, apiKey);
  }

  // === CUSTOM TOUCH CONTROLLER SETTERS ===

  /// Updates D-pad layout offsets and scale
  Future<void> updateDpadLayout(double x, double y, double scale) async {
    state = state.copyWith(dpadOffsetX: x, dpadOffsetY: y, dpadScale: scale);
    await _prefs?.setDouble('layout_dpad_x', x);
    await _prefs?.setDouble('layout_dpad_y', y);
    await _prefs?.setDouble('layout_dpad_s', scale);
  }

  /// Updates Action Pad layout offsets and scale
  Future<void> updateActionPadLayout(double x, double y, double scale) async {
    state = state.copyWith(
        actionPadOffsetX: x, actionPadOffsetY: y, actionPadScale: scale);
    await _prefs?.setDouble('layout_action_x', x);
    await _prefs?.setDouble('layout_action_y', y);
    await _prefs?.setDouble('layout_action_s', scale);
  }

  /// Updates Left Shoulder layout offsets and scale
  Future<void> updateLShoulderLayout(double x, double y, double scale) async {
    state = state.copyWith(
        lShoulderOffsetX: x, lShoulderOffsetY: y, lShoulderScale: scale);
    await _prefs?.setDouble('layout_lsh_x', x);
    await _prefs?.setDouble('layout_lsh_y', y);
    await _prefs?.setDouble('layout_lsh_s', scale);
  }

  /// Updates Right Shoulder layout offsets and scale
  Future<void> updateRShoulderLayout(double x, double y, double scale) async {
    state = state.copyWith(
        rShoulderOffsetX: x, rShoulderOffsetY: y, rShoulderScale: scale);
    await _prefs?.setDouble('layout_rsh_x', x);
    await _prefs?.setDouble('layout_rsh_y', y);
    await _prefs?.setDouble('layout_rsh_s', scale);
  }

  /// Updates Center Buttons layout offsets and scale
  Future<void> updateCenterLayout(double x, double y, double scale) async {
    state =
        state.copyWith(centerOffsetX: x, centerOffsetY: y, centerScale: scale);
    await _prefs?.setDouble('layout_cent_x', x);
    await _prefs?.setDouble('layout_cent_y', y);
    await _prefs?.setDouble('layout_cent_s', scale);
  }

  /// Reset touch controller layout offsets and scales to default values
  Future<void> resetControllerLayout() async {
    state = state.copyWith(
      dpadOffsetX: 0.0,
      dpadOffsetY: 0.0,
      dpadScale: 1.0,
      actionPadOffsetX: 0.0,
      actionPadOffsetY: 0.0,
      actionPadScale: 1.0,
      lShoulderOffsetX: 0.0,
      lShoulderOffsetY: 0.0,
      lShoulderScale: 1.0,
      rShoulderOffsetX: 0.0,
      rShoulderOffsetY: 0.0,
      rShoulderScale: 1.0,
      centerOffsetX: 0.0,
      centerOffsetY: 0.0,
      centerScale: 1.0,
    );
    await _prefs?.remove('layout_dpad_x');
    await _prefs?.remove('layout_dpad_y');
    await _prefs?.remove('layout_dpad_s');
    await _prefs?.remove('layout_action_x');
    await _prefs?.remove('layout_action_y');
    await _prefs?.remove('layout_action_s');
    await _prefs?.remove('layout_lsh_x');
    await _prefs?.remove('layout_lsh_y');
    await _prefs?.remove('layout_lsh_s');
    await _prefs?.remove('layout_rsh_x');
    await _prefs?.remove('layout_rsh_y');
    await _prefs?.remove('layout_rsh_s');
    await _prefs?.remove('layout_cent_x');
    await _prefs?.remove('layout_cent_y');
    await _prefs?.remove('layout_cent_s');
  }

  /// Resets all settings to their factory defaults and clears prefs.
  Future<void> resetToDefaults() async {
    state = const AppSettings();
    await _prefs?.clear();
  }
}

// ============================================================
// Provider
// ============================================================

/// Global [StateNotifierProvider] for [AppSettings].
///
/// Usage:
/// ```dart
/// final settings = ref.watch(settingsProvider);
/// ref.read(settingsProvider.notifier).setAudioVolume(0.5);
/// ```
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(
  (ref) => SettingsNotifier(),
);
