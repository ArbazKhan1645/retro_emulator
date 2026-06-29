# RetroVerse Emulator

Play Classic Sega Genesis Games Beautifully. Built with Flutter + Libretro (Genesis Plus GX).

## Key Features

- **Premium UI/UX**: Netflix-inspired landing page, glassmorphism card layouts, fluid parallax hero banner, and smooth animations powered by `flutter_animate`.
- **ROM Scanner**: Background isolate scanning of local storage/directories for Sega Genesis ROM files (`.bin`, `.md`, `.gen`, `.smd`).
- **Rich Metadata**: Automatically fetches cover arts, game descriptions, publishers, screenshots, and release years using IGDB (via Twitch API).
- **Save States**: Interactive save state management with slot selector, slot thumbnail preview, metadata, and timestamps.
- **Custom Touch Controls**: Built-in floating transparent retro controller overlay layout supporting D-pad + action buttons (A, B, C) + Start/Mode.
- **Stats Dashboard**: Beautiful statistics overview tracking total play hours, favorite games, storage usage, and active play counts.
- **RetroAchievements support**: Fully ready integration architecture for RetroAchievements achievements logging.

## Tech Stack

- **Framework**: Flutter (Material 3)
- **State Management**: Riverpod (StateNotifier architecture)
- **Routing**: GoRouter (including StatefulShellRoute nested tab navigation)
- **Animations**: flutter_animate & Shimmer placeholders
- **Networking**: Dio
- **Storage**: SharedPreferences & local JSON-based file persistence
- **Native Bridge**: dynamic FFI library lookup (`dart:ffi`) bindings mapping to standard Libretro core interfaces.

## Project Structure

```
lib/
├── main.dart                      # App entry point (System UI & orientation locks)
├── app.dart                       # Root App Widget (MaterialApp.router + GoRouter)
├── router/
│   └── app_router.dart            # GoRouter definition with index shell navigation
├── core/
│   ├── constants/                 # App Constants, storage keys & APIs
│   ├── theme/                     # AppTheme configuration supporting 7 modes
│   ├── errors/                    # Sealed Failure classes
│   └── extensions/                # Context & String formatting helpers
├── shared/
│   ├── models/                    # Serialized models (Game, SaveState, PlayHistory)
│   ├── widgets/                   # Custom UI (GlassContainer, RetroPlayButton, NeonText, GameCard)
│   └── services/                  # Business logic (Storage, RomScanner, Metadata)
└── features/
    ├── splash/                    # Animated splash boot-up screen
    ├── home/                      # Netflix-style hero banner & horizontal categories
    ├── library/                   # Grid view, list view & ROM scanner bottom sheet
    ├── game_detail/               # Game preview page with screenshot carousel
    ├── emulator/                  # Active emulator layout & Quick Pause Menu overlay
    ├── search/                    # Global library query search + filters
    ├── settings/                  # Settings screens, themes picker, & controls config
    ├── dashboard/                 # Stats dashboard & play tracking
    └── achievements/              # Achievements tracking placeholder
```

## Setup & Running

1. Run `flutter pub get` to download dependencies:
   ```bash
   flutter pub get
   ```
2. Run on a connected emulator/device:
   ```bash
   flutter run
   ```

## Native Compilation (Genesis Plus GX)

The dynamic bridge library configuration is scaffolded under `android/app/src/main/cpp`.
To compile the Libretro `genesis_plus_gx` core:
1. Clone Genesis Plus GX core source from [Libretro Github](https://github.com/libretro/Genesis-Plus-GX).
2. Configure Android NDK paths in your project's local properties.
3. Build the core dynamic library `.so` files using the provided CMake project configuration, or download compiled prebuilts directly from the Libretro Buildbot distribution directory.
4. Place compiled `.so` files into the standard Android native lib directories under `android/app/src/main/jniLibs/` to enable runtime dynamic loading via `dart:ffi`.
