import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:ffi/ffi.dart';
import 'package:mp_audio_stream/mp_audio_stream.dart';
import 'libretro_ffi.dart';
import 'dart:ui' as ui;

// ============================================================
// Global Emulation Frame, Input & Audio Buffer
// ============================================================

int latestWidth = 320;
int latestHeight = 224;
int latestPitch = 640;
Uint8List? latestFrameBytes;
int activePixelFormat = 2; // 0 = 0RGB1555, 1 = XRGB8888, 2 = RGB565

// Standard Libretro button map
final Map<int, bool> pressedButtons = {};

// Global Audio Stream and Volume controls
AudioStream? globalAudioStream;
double globalVolume = 0.8;

// ============================================================
// Top-Level Static FFI Callback Functions
// ============================================================

bool environmentCallback(int cmd, ffi.Pointer<ffi.Void> data) {
  // Command 10: RETRO_ENVIRONMENT_SET_PIXEL_FORMAT
  if (cmd == 10) {
    if (data != ffi.Pointer.fromAddress(0)) {
      final format = data.cast<ffi.Uint32>().value;
      debugPrint('Libretro core requested Pixel Format: $format');
      activePixelFormat = format;
      // Return true to negotiate/accept formats:
      // 0 = 0RGB1555, 1 = XRGB8888, 2 = RGB565
      return true;
    }
  }
  return false;
}

void videoRefreshCallback(
    ffi.Pointer<ffi.Void> data, int width, int height, int pitch) {
  if (data == ffi.Pointer.fromAddress(0)) return;
  latestWidth = width;
  latestHeight = height;
  latestPitch = pitch;

  final byteCount = pitch * height;
  final view = data.cast<ffi.Uint8>().asTypedList(byteCount);
  latestFrameBytes = Uint8List.fromList(view);
}

void audioSampleCallback(int left, int right) {
  try {
    final float32 = Float32List(2);
    final vol = globalVolume;
    float32[0] = (left / 32768.0) * vol;
    float32[1] = (right / 32768.0) * vol;
    if (globalAudioStream != null) {
      globalAudioStream!.push(float32);
    }
  } catch (_) {}
}

int audioSampleBatchCallback(ffi.Pointer<ffi.Int16> data, int frames) {
  if (data == ffi.Pointer.fromAddress(0) || frames <= 0) return frames;
  
  try {
    final samplesCount = frames * 2;
    final pcm16 = data.asTypedList(samplesCount);
    final float32 = Float32List(samplesCount);
    final vol = globalVolume;
    
    for (var i = 0; i < samplesCount; i++) {
      float32[i] = (pcm16[i] / 32768.0) * vol;
    }
    
    if (globalAudioStream != null) {
      globalAudioStream!.push(float32);
    }
  } catch (_) {}
  
  return frames;
}

void inputPollCallback() {}

int inputStateCallback(int port, int device, int index, int id) {
  if (port == 0) {
    if (pressedButtons[id] == true) {
      return 1;
    }
  }
  return 0;
}

// ============================================================
// Emulator Bridge Interface
// ============================================================

class EmulatorBridge {
  EmulatorBridge._();
  static final EmulatorBridge instance = EmulatorBridge._();

  LibretroFFI? _ffi;
  bool _isCoreLoaded = false;
  bool _isRomLoaded = false;
  Timer? _loopTimer;
  bool _isPaused = false;
  bool _isNativeInitialized = false;

  ffi.Pointer<RetroGameInfo>? _gameInfoPtr;
  ffi.Pointer<ffi.Uint8>? _romDataPtr;

  /// Loads the Libretro compiled shared library core (.so / .dll / .dylib).
  Future<void> loadCore(String coreName) async {
    if (_isCoreLoaded) return;
    debugPrint('Loading Libretro core: $coreName');

    try {
      String ext;
      if (Platform.isWindows) {
        ext = 'dll';
      } else if (Platform.isMacOS || Platform.isIOS) {
        ext = 'dylib';
      } else {
        ext = 'so';
      }

      final fileName = Platform.isAndroid || Platform.isLinux
          ? 'lib$coreName.$ext'
          : '$coreName.$ext';
      final assetPath = 'assets/cores/$fileName';

      final docsDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory(p.join(docsDir.path, 'retroverse', 'cores'));
      await targetDir.create(recursive: true);
      final targetFile = File(p.join(targetDir.path, fileName));

      debugPrint('Checking asset bundling: $assetPath');
      try {
        final byteData = await rootBundle.load(assetPath);
        final bytes = byteData.buffer
            .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
        await targetFile.writeAsBytes(bytes);
        debugPrint(
            'Dynamic core library bundled and extracted successfully to: ${targetFile.path}');

        final dylib = ffi.DynamicLibrary.open(targetFile.path);
        _ffi = LibretroFFI(dylib);
        _isCoreLoaded = true;
        debugPrint('Libretro core loaded successfully from assets.');
        return;
      } catch (assetErr) {
        debugPrint(
            'Core not found in assets, trying system directory fallback: $assetErr');
      }

      final ffi.DynamicLibrary dylib;
      if (Platform.isAndroid) {
        dylib = ffi.DynamicLibrary.open('lib$coreName.so');
      } else if (Platform.isWindows) {
        dylib = ffi.DynamicLibrary.open('$coreName.dll');
      } else if (Platform.isMacOS || Platform.isIOS) {
        dylib = ffi.DynamicLibrary.open('$coreName.dylib');
      } else {
        dylib = ffi.DynamicLibrary.open('lib$coreName.so');
      }

      _ffi = LibretroFFI(dylib);
      _isCoreLoaded = true;
      debugPrint(
          'Libretro core loaded successfully from system path fallback.');
    } catch (e) {
      debugPrint(
          'Failed to load native dynamic library: $e. Falling back to mock emulation mode.');
      _isCoreLoaded = true;
    }
  }

  /// Initialises system and loads ROM file path.
  Future<void> loadROM(String romPath) async {
    if (!_isCoreLoaded) {
      throw Exception('Load emulator core first.');
    }
    debugPrint('Loading ROM: $romPath');

    final file = File(romPath);
    if (!await file.exists()) {
      throw Exception('ROM file does not exist at path: $romPath');
    }

    _isRomLoaded = true;
    _isPaused = false;

    // Set up real FFI callbacks if dynamic library loaded successfully
    if (_ffi != null) {
      try {
        debugPrint('Setting up Libretro callbacks...');
        _ffi!.retro_set_environment(
            ffi.Pointer.fromFunction<RetroEnvironmentNative>(
                environmentCallback, false));
        _ffi!.retro_set_video_refresh(
            ffi.Pointer.fromFunction<RetroVideoRefreshNative>(
                videoRefreshCallback));
        _ffi!.retro_set_audio_sample(
            ffi.Pointer.fromFunction<RetroAudioSampleNative>(
                audioSampleCallback));
        _ffi!.retro_set_audio_sample_batch(
            ffi.Pointer.fromFunction<RetroAudioSampleBatchNative>(
                audioSampleBatchCallback, 0));
        _ffi!.retro_set_input_poll(
            ffi.Pointer.fromFunction<RetroInputPollNative>(inputPollCallback));
        _ffi!.retro_set_input_state(
            ffi.Pointer.fromFunction<RetroInputStateNative>(
                inputStateCallback, 0));

        debugPrint('Initializing Sega Genesis core...');
        _ffi!.retro_init();

        // Load ROM file into native heap memory
        final romBytes = await file.readAsBytes();
        _romDataPtr = calloc<ffi.Uint8>(romBytes.length);
        final view = _romDataPtr!.asTypedList(romBytes.length);
        view.setAll(0, romBytes);

        _gameInfoPtr = calloc<RetroGameInfo>();
        _gameInfoPtr!.ref.path = romPath.toNativeUtf8();
        _gameInfoPtr!.ref.data = _romDataPtr!.cast<ffi.Void>();
        _gameInfoPtr!.ref.size = romBytes.length;
        _gameInfoPtr!.ref.meta = ffi.Pointer.fromAddress(0).cast<Utf8>();

        debugPrint('Loading game info structure into core...');
        final loaded = _ffi!.retro_load_game(_gameInfoPtr!);
        if (!loaded) {
          throw Exception('Libretro core failed to load game ROM structure.');
        }

        _isNativeInitialized = true;
        debugPrint('Libretro emulation core initialized and running.');
        
        // Initialize the audio stream
        try {
          globalAudioStream?.uninit();
          globalAudioStream = getAudioStream();
          globalAudioStream!.init(
            channels: 2,
            sampleRate: 44100,
            bufferMilliSec: 150,
            waitingBufferMilliSec: 40,
          );
          globalAudioStream!.resume();
          debugPrint('Audio stream initialized successfully.');
        } catch (audioErr) {
          debugPrint('Failed to initialize audio stream: $audioErr');
        }
      } catch (err) {
        debugPrint(
            'Failed to initialize native core FFI sequence: $err. Bypassing to mock surface.');
        _isNativeInitialized = false;
      }
    }

    _startEmulationLoop();
  }

  void _startEmulationLoop() {
    _loopTimer?.cancel();
    _loopTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_isPaused || !_isRomLoaded) return;
      _runFrame();
    });
  }

  void _runFrame() {
    if (_ffi != null && _isNativeInitialized) {
      _ffi!.retro_run();
    }
  }

  /// Pause emulation
  void pause() {
    _isPaused = true;
    debugPrint('Emulation paused.');
  }

  /// Resume emulation
  void resume() {
    _isPaused = false;
    debugPrint('Emulation resumed.');
  }

  /// Resets the emulation core
  void reset() {
    if (_ffi != null && _isNativeInitialized) {
      _ffi!.retro_reset();
      debugPrint('Libretro core reset triggered.');
    }
  }

  /// Stop and unload resources
  Future<void> stop() async {
    _loopTimer?.cancel();
    _loopTimer = null;
    _isRomLoaded = false;

    if (_ffi != null && _isNativeInitialized) {
      _ffi!.retro_unload_game();
      _ffi!.retro_deinit();
      _isNativeInitialized = false;
    }

    // Uninitialize audio stream
    if (globalAudioStream != null) {
      try {
        globalAudioStream!.uninit();
        globalAudioStream = null;
      } catch (e) {
        debugPrint('Error uninitializing audio stream: $e');
      }
    }

    // Clean up FFI allocations
    if (_gameInfoPtr != null) {
      if (_gameInfoPtr!.ref.path != ffi.Pointer.fromAddress(0)) {
        malloc.free(_gameInfoPtr!.ref.path);
      }
      calloc.free(_gameInfoPtr!);
      _gameInfoPtr = null;
    }
    if (_romDataPtr != null) {
      calloc.free(_romDataPtr!);
      _romDataPtr = null;
    }

    latestFrameBytes = null;
    debugPrint('Emulation stopped and native memory freed.');
  }

  /// Saves emulator state to a specific slot (using default path convention).
  Future<void> saveState(int slot) async {
    debugPrint('Saving state to slot $slot');
    final docsDir = await getApplicationDocumentsDirectory();
    final statesDir = p.join(docsDir.path, 'retroverse', 'save_states');
    final filePath = p.join(statesDir, 'slot_$slot.state');
    await saveStateToFile(filePath);
  }

  /// Loads emulator state from a specific slot (using default path convention).
  Future<void> loadState(int slot) async {
    debugPrint('Loading state from slot $slot');
    final docsDir = await getApplicationDocumentsDirectory();
    final statesDir = p.join(docsDir.path, 'retroverse', 'save_states');
    final filePath = p.join(statesDir, 'slot_$slot.state');
    await loadStateFromFile(filePath);
  }

  /// Saves emulator state to a file, along with a PNG thumbnail screenshot.
  Future<bool> saveStateToFile(String filePath) async {
    debugPrint('Saving state to file: $filePath');
    final stateBytes = serializeState();
    if (stateBytes == null) {
      debugPrint('Failed to serialize state.');
      return false;
    }

    try {
      final file = File(filePath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(stateBytes);

      // Capture and save screenshot thumbnail
      final thumbnailBytes = await capturePngThumbnail();
      if (thumbnailBytes != null) {
        final thumbPath = filePath.replaceAll('.state', '.png');
        final thumbFile = File(thumbPath);
        await thumbFile.writeAsBytes(thumbnailBytes);
        debugPrint('Thumbnail saved successfully to: $thumbPath');
      }
      return true;
    } catch (e) {
      debugPrint('Error saving state file: $e');
      return false;
    }
  }

  /// Loads emulator state from a file.
  Future<bool> loadStateFromFile(String filePath) async {
    debugPrint('Loading state from file: $filePath');
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('Save state file does not exist.');
        return false;
      }
      final stateBytes = await file.readAsBytes();
      return unserializeState(stateBytes);
    } catch (e) {
      debugPrint('Error loading state file: $e');
      return false;
    }
  }

  /// Serializes emulator state into raw byte array using Libretro API
  Uint8List? serializeState() {
    if (_ffi == null || !_isNativeInitialized) return null;
    try {
      final size = _ffi!.retro_serialize_size();
      if (size <= 0) return null;

      final ptr = malloc<ffi.Uint8>(size);
      final success = _ffi!.retro_serialize(ptr.cast<ffi.Void>(), size);
      if (success) {
        final view = ptr.asTypedList(size);
        final stateBytes = Uint8List.fromList(view);
        malloc.free(ptr);
        return stateBytes;
      } else {
        malloc.free(ptr);
        debugPrint('retro_serialize failed');
        return null;
      }
    } catch (e) {
      debugPrint('Error during native serialization: $e');
      return null;
    }
  }

  /// Restores emulator state from raw byte array using Libretro API
  bool unserializeState(Uint8List stateBytes) {
    if (_ffi == null || !_isNativeInitialized) return false;
    try {
      final size = stateBytes.length;
      final ptr = malloc<ffi.Uint8>(size);
      ptr.asTypedList(size).setAll(0, stateBytes);

      final success = _ffi!.retro_unserialize(ptr.cast<ffi.Void>(), size);
      malloc.free(ptr);
      return success;
    } catch (e) {
      debugPrint('Error during native unserialization: $e');
      return false;
    }
  }

  /// Captures the current emulator frame buffer and converts it to a PNG byte array natively.
  Future<Uint8List?> capturePngThumbnail() async {
    final frameBytes = latestFrameBytes;
    final width = latestWidth;
    final height = latestHeight;
    final pitch = latestPitch;
    final format = activePixelFormat;

    if (frameBytes == null || width <= 0 || height <= 0) return null;

    try {
      Uint8List rgbaBytes;
      if (format == 2) {
        rgbaBytes = _unpackRGB565toRGBA(frameBytes, width, height, pitch, 2);
      } else if (format == 1) {
        rgbaBytes = _unpackXRGB8888toRGBA(frameBytes, width, height, pitch);
      } else if (format == 0) {
        rgbaBytes = _unpackRGB565toRGBA(frameBytes, width, height, pitch, 2);
      } else {
        rgbaBytes = frameBytes;
      }

      final completer = Completer<ui.Image>();
      ui.decodeImageFromPixels(
        rgbaBytes,
        width,
        height,
        ui.PixelFormat.rgba8888,
        (ui.Image img) {
          completer.complete(img);
        },
      );
      final image = await completer.future;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing PNG thumbnail: $e');
      return null;
    }
  }

  Uint8List _unpackRGB565toRGBA(
      Uint8List rgbBytes, int width, int height, int pitch, int mode) {
    final rgba = Uint8List(width * height * 4);
    var dstIdx = 0;
    for (var y = 0; y < height; y++) {
      final rowStart = y * pitch;
      for (var x = 0; x < width; x++) {
        final srcIdx = rowStart + (x * 2);
        if (srcIdx + 1 >= rgbBytes.length) break;
        final b1 = rgbBytes[srcIdx];
        final b2 = rgbBytes[srcIdx + 1];
        final val = (b2 << 8) | b1;
        int r = 0, g = 0, b = 0;
        switch (mode) {
          case 0:
            r = (val & 0x1F) * 255 ~/ 31;
            g = ((val >> 5) & 0x3F) * 255 ~/ 63;
            b = ((val >> 11) & 0x1F) * 255 ~/ 31;
            break;
          case 1:
            r = ((val >> 11) & 0x1F) * 255 ~/ 31;
            g = ((val >> 5) & 0x3F) * 255 ~/ 63;
            b = (val & 0x1F) * 255 ~/ 31;
            break;
          case 2:
            r = ((val >> 10) & 0x1F) * 255 ~/ 31;
            g = ((val >> 5) & 0x1F) * 255 ~/ 31;
            b = (val & 0x1F) * 255 ~/ 31;
            break;
          case 3:
            r = (val & 0x1F) * 255 ~/ 31;
            g = ((val >> 5) & 0x1F) * 255 ~/ 31;
            b = ((val >> 10) & 0x1F) * 255 ~/ 31;
            break;
        }
        rgba[dstIdx++] = r;
        rgba[dstIdx++] = g;
        rgba[dstIdx++] = b;
        rgba[dstIdx++] = 255;
      }
    }
    return rgba;
  }

  Uint8List _unpackXRGB8888toRGBA(
      Uint8List xrgb, int width, int height, int pitch) {
    final rgba = Uint8List(width * height * 4);
    var dstIdx = 0;
    for (var y = 0; y < height; y++) {
      final rowStart = y * pitch;
      for (var x = 0; x < width; x++) {
        final srcIdx = rowStart + (x * 4);
        if (srcIdx + 3 >= xrgb.length) break;
        final b = xrgb[srcIdx];
        final g = xrgb[srcIdx + 1];
        final r = xrgb[srcIdx + 2];
        rgba[dstIdx++] = r;
        rgba[dstIdx++] = g;
        rgba[dstIdx++] = b;
        rgba[dstIdx++] = 255;
      }
    }
    return rgba;
  }

  /// Sets fast forward mode speed factor multiplier
  void setFastForward(bool enabled) {
    debugPrint('Fast forward: $enabled');
    if (enabled) {
      _loopTimer?.cancel();
      _loopTimer = Timer.periodic(const Duration(milliseconds: 4), (timer) {
        if (_isPaused || !_isRomLoaded) return;
        _runFrame();
      });
    } else {
      _startEmulationLoop();
    }
  }

  /// Sets rewind mode speed factor multiplier
  void setRewind(bool enabled) {
    debugPrint('Rewind: $enabled');
  }

  /// Set audio volume output (0.0 to 1.0)
  void setVolume(double volume) {
    globalVolume = volume.clamp(0.0, 1.0);
    debugPrint('Set volume: $globalVolume');
  }

  /// Maps inputs dynamically to pressed buttons map
  void setButtonState(String button, bool pressed) {
    int id;
    switch (button.toLowerCase()) {
      case 'up':
        id = 4;
        break;
      case 'down':
        id = 5;
        break;
      case 'left':
        id = 6;
        break;
      case 'right':
        id = 7;
        break;
      case 'a':
        id = 1;
        break;
      case 'b':
        id = 0;
        break;
      case 'c':
        id = 8;
        break;
      case 'start':
        id = 3;
        break;
      default:
        return;
    }
    pressedButtons[id] = pressed;
  }
}
