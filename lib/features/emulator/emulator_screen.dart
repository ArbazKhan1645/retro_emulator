import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/models/game_model.dart';
import '../../native_bridge/emulator_bridge.dart';
import '../emulator/providers/emulator_provider.dart';
import '../library/providers/library_provider.dart';
import 'widgets/touch_controls_widget.dart';
import 'widgets/quick_menu_overlay.dart';
import 'widgets/fps_counter_widget.dart';

class EmulatorScreen extends ConsumerStatefulWidget {
  const EmulatorScreen(
      {super.key, required this.gameId, this.initialSaveStatePath});
  final String gameId;
  final String? initialSaveStatePath;

  @override
  ConsumerState<EmulatorScreen> createState() => _EmulatorScreenState();
}

class _EmulatorScreenState extends ConsumerState<EmulatorScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  String _lastBtn = '';
  bool _btnActive = false;
  ui.Image? _frameImage;
  bool _isDecoding = false;
  int _colorMode = 1; // Default Standard RGB565

  void _cycleColorMode() {
    setState(() {
      _colorMode = (_colorMode + 1) % 4;
    });
    final modes = ['BGR565', 'RGB565', '0RGB1555', '0BGR1555'];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Color Mode: ${modes[_colorMode]}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadGame());
  }

  Future<void> _loadGame() async {
    final library = ref.read(libraryProvider);
    GameModel? game;
    try {
      game = library.games.firstWhere((g) => g.id == widget.gameId);
    } catch (_) {
      return;
    }
    await ref.read(emulatorProvider.notifier).loadGame(
          game,
          initialSaveStatePath: widget.initialSaveStatePath,
        );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    ref.read(emulatorProvider.notifier).stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emState = ref.watch(emulatorProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: _buildGameSurface(emState),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: FpsCounterWidget(fps: emState.fps),
          ),
          if (!emState.showQuickMenu)
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _HudButton(
                        icon: Icons.palette_rounded,
                        onTap: _cycleColorMode,
                      ),
                      const SizedBox(width: 6),
                      _HudButton(
                        icon: emState.isFastForwarding
                            ? Icons.fast_forward_rounded
                            : Icons.fast_forward_outlined,
                        onTap: () => ref
                            .read(emulatorProvider.notifier)
                            .setFastForward(!emState.isFastForwarding),
                      ),
                      const SizedBox(width: 6),
                      _HudButton(
                        icon: Icons.refresh_rounded,
                        onTap: () =>
                            ref.read(emulatorProvider.notifier).reset(),
                      ),
                      const SizedBox(width: 6),
                      _HudButton(
                        icon: emState.isMuted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        onTap: () =>
                            ref.read(emulatorProvider.notifier).toggleMute(),
                      ),
                      const SizedBox(width: 6),
                      _HudButton(
                        icon: Icons.menu_rounded,
                        onTap: () => ref
                            .read(emulatorProvider.notifier)
                            .toggleQuickMenu(),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms),
            ),
          if (emState.showControls && !emState.showQuickMenu)
            Positioned.fill(
              child: TouchControlsWidget(
                onButtonDown: (btn) => _handleInput(btn, true),
                onButtonUp: (btn) => _handleInput(btn, false),
              ).animate().fadeIn(duration: 200.ms),
            ),
          if (emState.showQuickMenu)
            Positioned.fill(
              child: QuickMenuOverlay(
                game: emState.currentGame,
                status: emState.status,
                isFastForwarding: emState.isFastForwarding,
                currentSlot: emState.currentSaveSlot,
                onResume: () =>
                    ref.read(emulatorProvider.notifier).toggleQuickMenu(),
                onSave: () => ref.read(emulatorProvider.notifier).quickSave(),
                onLoad: () => ref.read(emulatorProvider.notifier).quickLoad(),
                onFastForward: (v) =>
                    ref.read(emulatorProvider.notifier).setFastForward(v),
                onToggleControls: () =>
                    ref.read(emulatorProvider.notifier).toggleControls(),
                onExit: () {
                  ref.read(emulatorProvider.notifier).stop();
                  context.pop();
                },
                onSlotChanged: (slot) =>
                    ref.read(emulatorProvider.notifier).setSaveSlot(slot),
              ).animate().fadeIn(duration: 200.ms),
            ),
          if (emState.status == EmulatorStatus.loading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.85),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Loading ${emState.currentGame?.title ?? 'game'}...',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          if (emState.status == EmulatorStatus.error)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.9),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 60),
                    const SizedBox(height: 16),
                    Text(
                      emState.error ?? 'An error occurred',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGameSurface(EmulatorState emState) {
    return Container(
      color: Colors.black,
      width: double.infinity,
      height: double.infinity,
      child: emState.status == EmulatorStatus.running ||
              emState.status == EmulatorStatus.paused
          ? Align(
              alignment: Alignment.center,
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Container(
                  color: const Color(0xFF03030F),
                  child: AnimatedBuilder(
                    animation: _animCtrl,
                    builder: (context, _) {
                      // Check if FFI has populated new frame bytes
                      if (latestFrameBytes != null && !_isDecoding) {
                        _isDecoding = true;
                        debugPrint(
                            'FRAME_DEBUG: w=$latestWidth, h=$latestHeight, pitch=$latestPitch, format=$activePixelFormat');
                        Uint8List rgbaBytes;
                        if (activePixelFormat == 2) {
                          rgbaBytes = unpackRGB565toRGBA(
                              latestFrameBytes!,
                              latestWidth,
                              latestHeight,
                              latestPitch,
                              _colorMode);
                        } else if (activePixelFormat == 1) {
                          rgbaBytes = unpackXRGB8888toRGBA(latestFrameBytes!,
                              latestWidth, latestHeight, latestPitch);
                        } else if (activePixelFormat == 0) {
                          // Fallback to 15-bit unpacking (using Case 2/6: 0RGB1555 mode)
                          rgbaBytes = unpackRGB565toRGBA(latestFrameBytes!,
                              latestWidth, latestHeight, latestPitch, 2);
                        } else {
                          rgbaBytes = latestFrameBytes!;
                        }

                        ui.decodeImageFromPixels(
                          rgbaBytes,
                          latestWidth,
                          latestHeight,
                          ui.PixelFormat.rgba8888,
                          (ui.Image img) {
                            if (mounted) {
                              setState(() {
                                _frameImage = img;
                                _isDecoding = false;
                              });
                            }
                          },
                        );
                      }

                      return CustomPaint(
                        painter: _RetroGameVisualizerPainter(
                          animValue: _animCtrl.value,
                          gameTitle:
                              emState.currentGame?.title ?? 'ROAD RASH 3',
                          lastButton: _lastBtn,
                          isButtonPressed: _btnActive,
                          frameImage: _frameImage,
                        ),
                      );
                    },
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  void _handleInput(String button, bool pressed) {
    HapticFeedback.selectionClick();
    EmulatorBridge.instance.setButtonState(button, pressed);
    setState(() {
      _lastBtn = button.toUpperCase();
      _btnActive = pressed;
    });
  }

  Uint8List unpackRGB565toRGBA(
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

        int r = 0;
        int g = 0;
        int b = 0;

        switch (mode) {
          case 0: // BGR565 (Little Endian)
            r = (val & 0x1F) * 255 ~/ 31;
            g = ((val >> 5) & 0x3F) * 255 ~/ 63;
            b = ((val >> 11) & 0x1F) * 255 ~/ 31;
            break;
          case 1: // RGB565 (Little Endian)
            r = ((val >> 11) & 0x1F) * 255 ~/ 31;
            g = ((val >> 5) & 0x3F) * 255 ~/ 63;
            b = (val & 0x1F) * 255 ~/ 31;
            break;
          case 2: // 0RGB1555 (Little Endian)
            r = ((val >> 10) & 0x1F) * 255 ~/ 31;
            g = ((val >> 5) & 0x1F) * 255 ~/ 31;
            b = (val & 0x1F) * 255 ~/ 31;
            break;
          case 3: // 0BGR1555 (Little Endian)
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

  Uint8List unpackXRGB8888toRGBA(
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

        // Swap Red and Blue channels (BGRX mapping) to fix color rendering
        rgba[dstIdx++] = r;
        rgba[dstIdx++] = g;
        rgba[dstIdx++] = b;
        rgba[dstIdx++] = 255;
      }
    }
    return rgba;
  }
}

class _HudButton extends StatelessWidget {
  const _HudButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(icon, color: Colors.white70, size: 18),
      ),
    );
  }
}

// ============================================================
// Interactive Cyberpunk Retro Gameplay Painter (Real Core Video Output)
// ============================================================
class _RetroGameVisualizerPainter extends CustomPainter {
  _RetroGameVisualizerPainter({
    required this.animValue,
    required this.gameTitle,
    required this.lastButton,
    required this.isButtonPressed,
    this.frameImage,
  });

  final double animValue;
  final String gameTitle;
  final String lastButton;
  final bool isButtonPressed;
  final ui.Image? frameImage;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;

    // 1. If a real game frame is available, render it stretching to fill screen!
    if (frameImage != null) {
      canvas.drawImageRect(
        frameImage!,
        Rect.fromLTWH(
            0, 0, frameImage!.width.toDouble(), frameImage!.height.toDouble()),
        Rect.fromLTWH(0, 0, size.width, size.height),
        paint,
      );

      // CRT Scanlines overlay
      final scanlinePaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.06)
        ..strokeWidth = 1.0;
      for (var y = 0.0; y < size.height; y += 4.0) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), scanlinePaint);
      }
      return;
    }

    // 2. If no real frame, draw a clean dark retro monitor screen (No mock game)
    // Dark background
    paint.color = const Color(0xFF03030D);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Subtle pulsing synthwave grid
    final gridPaint = Paint()
      ..color =
          const Color(0xFF7C3AED).withValues(alpha: 0.1 + 0.05 * animValue)
      ..strokeWidth = 1.0;
    const gridCount = 12;
    for (var i = 0; i <= gridCount; i++) {
      final y = size.height * (i / gridCount);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (var i = 0; i <= gridCount; i++) {
      final x = size.width * (i / gridCount);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Centered controller icon and waiting text
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'CORE LOADED SUCCESSFUL\nWAITING FOR VIDEO FEED',
        style: TextStyle(
          color: const Color(0xFF00D4FF),
          fontSize: 12,
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
          height: 1.5,
          letterSpacing: 2,
          shadows: [
            Shadow(
                color: const Color(0xFF00D4FF).withValues(alpha: 0.8),
                blurRadius: 10),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2,
          (size.height - textPainter.height) / 2 - 30),
    );

    // Pulsing core logo at center
    final coreGlow = Paint()
      ..color = const Color(0xFFFF0080).withValues(alpha: 0.1 + 0.1 * animValue)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width / 2, (size.height / 2) + 40),
        20 + 8 * animValue, coreGlow);

    paint.color = const Color(0xFFFF0080);
    canvas.drawCircle(Offset(size.width / 2, (size.height / 2) + 40), 6, paint);

    // Active Game HUD Label
    final gamePainter = TextPainter(
      text: TextSpan(
        text: 'GAME: ${gameTitle.toUpperCase()}',
        style: TextStyle(
          color: const Color(0xFF39FF14),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          letterSpacing: 1.5,
          shadows: [
            Shadow(
                color: const Color(0xFF39FF14).withValues(alpha: 0.6),
                blurRadius: 6)
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    gamePainter.paint(canvas, const Offset(20, 20));

    // Pad state overlay at the bottom left
    if (lastButton.isNotEmpty) {
      final inputPainter = TextPainter(
        text: TextSpan(
          text: 'KEY STATE: $lastButton',
          style: TextStyle(
            color: isButtonPressed
                ? const Color(0xFF39FF14)
                : const Color(0xFF6B6B8A),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      inputPainter.paint(canvas, Offset(20, size.height - 35));
    }

    // 3. CRT Scanlines effect overlay
    final scanlinePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..strokeWidth = 1.0;
    for (var y = 0.0; y < size.height; y += 4.0) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), scanlinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RetroGameVisualizerPainter oldDelegate) => true;
}
