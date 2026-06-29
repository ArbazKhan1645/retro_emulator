/// RetroVerse — Application-wide constants
class AppConstants {
  AppConstants._();

  // === APP INFO ===
  static const String appName = 'Retro Metro';
  static const String appTagline = 'Classic games, beautifully collected.';
  static const String appVersion = '1.0.0';
  static const String bundleId = 'com.arbaz.retrometro';
  static const String appIconAsset = 'assets/images/app_icon.png';

  // === SUPPORTED CONSOLES ===
  static const String consoleGenesis = 'Sega Genesis';
  static const String consoleMegaDrive = 'Sega Mega Drive';

  // === SUPPORTED ROM EXTENSIONS ===
  static const List<String> genesisExtensions = [
    '.bin',
    '.md',
    '.gen',
    '.smd',
    '.32x'
  ];
  static const List<String> allSupportedExtensions = [
    '.bin',
    '.md',
    '.gen',
    '.smd',
    '.32x'
  ];

  // === FILE TYPES ===
  static const Map<String, String> extensionToConsole = {
    '.bin': 'Sega Genesis',
    '.md': 'Sega Genesis',
    '.gen': 'Sega Genesis',
    '.smd': 'Sega Genesis',
    '.32x': 'Sega 32X',
  };

  // === EMULATOR ===
  static const String genesisCoreName = 'genesis_plus_gx';
  static const String genesisCoreLibName = 'libgenesis_plus_gx';
  static const int targetFps = 60;
  static const int screenWidth = 320;
  static const int screenHeight = 224;
  static const int sampleRate = 44100;

  // === METADATA ===
  static const String igdbBaseUrl = 'https://api.igdb.com/v4';
  static const String screenscrapeBaseUrl = 'https://www.screenscraper.fr/api2';
  static const String retroAchievementsBaseUrl =
      'https://retroachievements.org/API';

  // === STORAGE KEYS ===
  static const String keyThemeMode = 'theme_mode';
  static const String keyAccentColor = 'accent_color';
  static const String keyTargetFps = 'target_fps';
  static const String keyAudioVolume = 'audio_volume';
  static const String keyAudioEnabled = 'audio_enabled';
  static const String keyScanFolders = 'scan_folders';
  static const String keyBiosPath = 'bios_path';
  static const String keyTouchControlsOpacity = 'touch_controls_opacity';
  static const String keyTouchControlsSize = 'touch_controls_size';
  static const String keyTouchControlsEnabled = 'touch_controls_enabled';
  static const String keyShaderFilter = 'shader_filter';
  static const String keyAspectRatio = 'aspect_ratio';
  static const String keyFastForwardSpeed = 'fast_forward_speed';
  static const String keyAutoSave = 'auto_save';
  static const String keyHapticFeedback = 'haptic_feedback';
  static const String keyGamesJsonPath = 'games_json';
  static const String keySaveStatesJsonPath = 'save_states_json';
  static const String keyPlayHistoryJsonPath = 'play_history_json';
  static const String keyRaUsername = 'ra_username';
  static const String keyRaApiKey = 'ra_api_key';

  // === UI ===
  static const double cardBorderRadius = 18.0;
  static const double pagePadding = 20.0;
  static const double sectionSpacing = 28.0;
  static const double cardWidth = 164.0;
  static const double cardHeight = 238.0;
  static const double heroHeight = 500.0;
  static const Duration animDuration = Duration(milliseconds: 300);
  static const Duration longAnimDuration = Duration(milliseconds: 600);
  static const Duration splashDuration = Duration(milliseconds: 3500);

  // === EMULATOR DEFAULTS ===
  static const double defaultVolume = 0.8;
  static const int defaultFastForwardSpeed = 3;
  static const String defaultShaderFilter = 'pixel_perfect';
  static const String defaultAspectRatio = '4:3';

  // === SAVE STATES ===
  static const int maxSaveSlots = 99;
  static const String saveStateExtension = '.state';
  static const String saveStateThumbnailExtension = '.png';
}
