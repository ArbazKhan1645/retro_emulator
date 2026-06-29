// ignore_for_file: non_constant_identifier_names

import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

// ============================================================
// Libretro Structs
// ============================================================

final class RetroGameInfo extends ffi.Struct {
  external ffi.Pointer<Utf8> path;
  external ffi.Pointer<ffi.Void> data;
  @ffi.Size()
  external int size;
  external ffi.Pointer<Utf8> meta;
}

// ============================================================
// Libretro Native Callback Signatures
// ============================================================

typedef RetroEnvironmentNative = ffi.Bool Function(
    ffi.Uint32 cmd, ffi.Pointer<ffi.Void> data);
typedef RetroVideoRefreshNative = ffi.Void Function(ffi.Pointer<ffi.Void> data,
    ffi.Uint32 width, ffi.Uint32 height, ffi.Size pitch);
typedef RetroAudioSampleNative = ffi.Void Function(
    ffi.Int16 left, ffi.Int16 right);
typedef RetroAudioSampleBatchNative = ffi.Size Function(
    ffi.Pointer<ffi.Int16> data, ffi.Size frames);
typedef RetroInputPollNative = ffi.Void Function();
typedef RetroInputStateNative = ffi.Int16 Function(
    ffi.Uint32 port, ffi.Uint32 device, ffi.Uint32 index, ffi.Uint32 id);

// ============================================================
// Libretro Dart FFI wrapper
// ============================================================

class LibretroFFI {
  final ffi.DynamicLibrary dylib;

  LibretroFFI(this.dylib) {
    _retro_init = dylib
        .lookup<ffi.NativeFunction<ffi.Void Function()>>('retro_init')
        .asFunction();
    _retro_deinit = dylib
        .lookup<ffi.NativeFunction<ffi.Void Function()>>('retro_deinit')
        .asFunction();
    _retro_run = dylib
        .lookup<ffi.NativeFunction<ffi.Void Function()>>('retro_run')
        .asFunction();
    _retro_serialize_size = dylib
        .lookup<ffi.NativeFunction<ffi.Size Function()>>('retro_serialize_size')
        .asFunction();
    _retro_serialize = dylib
        .lookup<
            ffi.NativeFunction<
                ffi.Bool Function(
                    ffi.Pointer<ffi.Void>, ffi.Size)>>('retro_serialize')
        .asFunction();
    _retro_unserialize = dylib
        .lookup<
            ffi.NativeFunction<
                ffi.Bool Function(
                    ffi.Pointer<ffi.Void>, ffi.Size)>>('retro_unserialize')
        .asFunction();
    _retro_set_environment = dylib
        .lookup<
            ffi.NativeFunction<
                ffi.Void Function(
                    ffi.Pointer<ffi.NativeFunction<RetroEnvironmentNative>>
                        cb)>>('retro_set_environment')
        .asFunction();
    _retro_set_video_refresh = dylib
        .lookup<
            ffi.NativeFunction<
                ffi.Void Function(
                    ffi.Pointer<ffi.NativeFunction<RetroVideoRefreshNative>>
                        cb)>>('retro_set_video_refresh')
        .asFunction();
    _retro_set_audio_sample = dylib
        .lookup<
            ffi.NativeFunction<
                ffi.Void Function(
                    ffi.Pointer<ffi.NativeFunction<RetroAudioSampleNative>>
                        cb)>>('retro_set_audio_sample')
        .asFunction();
    _retro_set_audio_sample_batch = dylib
        .lookup<
            ffi.NativeFunction<
                ffi.Void Function(
                    ffi.Pointer<ffi.NativeFunction<RetroAudioSampleBatchNative>>
                        cb)>>('retro_set_audio_sample_batch')
        .asFunction();
    _retro_set_input_poll = dylib
        .lookup<
            ffi.NativeFunction<
                ffi.Void Function(
                    ffi.Pointer<ffi.NativeFunction<RetroInputPollNative>>
                        cb)>>('retro_set_input_poll')
        .asFunction();
    _retro_set_input_state = dylib
        .lookup<
            ffi.NativeFunction<
                ffi.Void Function(
                    ffi.Pointer<ffi.NativeFunction<RetroInputStateNative>>
                        cb)>>('retro_set_input_state')
        .asFunction();
    _retro_load_game = dylib
        .lookup<
            ffi.NativeFunction<
                ffi.Bool Function(
                    ffi.Pointer<RetroGameInfo> game)>>('retro_load_game')
        .asFunction();
    _retro_unload_game = dylib
        .lookup<ffi.NativeFunction<ffi.Void Function()>>('retro_unload_game')
        .asFunction();
    _retro_reset = dylib
        .lookup<ffi.NativeFunction<ffi.Void Function()>>('retro_reset')
        .asFunction();
  }

  late final void Function() _retro_init;
  late final void Function() _retro_deinit;
  late final void Function() _retro_run;
  late final int Function() _retro_serialize_size;
  late final bool Function(ffi.Pointer<ffi.Void> data, int size)
      _retro_serialize;
  late final bool Function(ffi.Pointer<ffi.Void> data, int size)
      _retro_unserialize;
  late final void Function(
          ffi.Pointer<ffi.NativeFunction<RetroEnvironmentNative>> cb)
      _retro_set_environment;
  late final void Function(
          ffi.Pointer<ffi.NativeFunction<RetroVideoRefreshNative>> cb)
      _retro_set_video_refresh;
  late final void Function(
          ffi.Pointer<ffi.NativeFunction<RetroAudioSampleNative>> cb)
      _retro_set_audio_sample;
  late final void Function(
          ffi.Pointer<ffi.NativeFunction<RetroAudioSampleBatchNative>> cb)
      _retro_set_audio_sample_batch;
  late final void Function(
          ffi.Pointer<ffi.NativeFunction<RetroInputPollNative>> cb)
      _retro_set_input_poll;
  late final void Function(
          ffi.Pointer<ffi.NativeFunction<RetroInputStateNative>> cb)
      _retro_set_input_state;
  late final bool Function(ffi.Pointer<RetroGameInfo> game) _retro_load_game;
  late final void Function() _retro_unload_game;
  late final void Function() _retro_reset;

  void retro_init() => _retro_init();
  void retro_deinit() => _retro_deinit();
  void retro_run() => _retro_run();
  int retro_serialize_size() => _retro_serialize_size();
  bool retro_serialize(ffi.Pointer<ffi.Void> data, int size) =>
      _retro_serialize(data, size);
  bool retro_unserialize(ffi.Pointer<ffi.Void> data, int size) =>
      _retro_unserialize(data, size);

  void retro_set_environment(
          ffi.Pointer<ffi.NativeFunction<RetroEnvironmentNative>> cb) =>
      _retro_set_environment(cb);
  void retro_set_video_refresh(
          ffi.Pointer<ffi.NativeFunction<RetroVideoRefreshNative>> cb) =>
      _retro_set_video_refresh(cb);
  void retro_set_audio_sample(
          ffi.Pointer<ffi.NativeFunction<RetroAudioSampleNative>> cb) =>
      _retro_set_audio_sample(cb);
  void retro_set_audio_sample_batch(
          ffi.Pointer<ffi.NativeFunction<RetroAudioSampleBatchNative>> cb) =>
      _retro_set_audio_sample_batch(cb);
  void retro_set_input_poll(
          ffi.Pointer<ffi.NativeFunction<RetroInputPollNative>> cb) =>
      _retro_set_input_poll(cb);
  void retro_set_input_state(
          ffi.Pointer<ffi.NativeFunction<RetroInputStateNative>> cb) =>
      _retro_set_input_state(cb);
  bool retro_load_game(ffi.Pointer<RetroGameInfo> game) =>
      _retro_load_game(game);
  void retro_unload_game() => _retro_unload_game();
  void retro_reset() => _retro_reset();
}
