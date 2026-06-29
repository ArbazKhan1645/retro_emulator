import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../settings/providers/settings_provider.dart';

enum GenesisButton { up, down, left, right, a, b, c, start, mode }

class TouchControlsWidget extends ConsumerWidget {
  const TouchControlsWidget({
    super.key,
    required this.onButtonDown,
    required this.onButtonUp,
    this.opacity = 0.75,
    this.scale = 1.0,
  });

  final void Function(String) onButtonDown;
  final void Function(String) onButtonUp;
  final double opacity;
  final double scale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Opacity(
      opacity: opacity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isPortrait = constraints.maxHeight > constraints.maxWidth;
          final screenWidth = constraints.maxWidth;

          // Calculate scale dynamically based on screen width to guarantee no overlap
          double dynamicScale = scale * settings.touchControlsSize;
          if (screenWidth < 360) {
            dynamicScale *= 0.7;
          } else if (screenWidth < 400) {
            dynamicScale *= 0.8;
          } else if (screenWidth < 600) {
            dynamicScale *= 0.9;
          } else if (screenWidth < 1000) {
            dynamicScale *= 1.0;
          } else {
            dynamicScale *= 1.15;
          }

          // D-Pad and Action Pad dimensions
          final dpadSize = 136.0 * dynamicScale * settings.dpadScale;
          final actionSize = 136.0 * dynamicScale * settings.actionPadScale;

          return SafeArea(
            child: Stack(
              children: [
                // === LEFT CONTROLS: L1 & L2 Shoulder Buttons ===
                Positioned(
                  left: (isPortrait ? 16 : 24) + settings.lShoulderOffsetX,
                  bottom: (isPortrait ? 110 : 20) +
                      (136.0 * dynamicScale * settings.dpadScale) +
                      (16.0 * dynamicScale * settings.dpadScale) +
                      settings.lShoulderOffsetY,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ShoulderButton(
                        label: 'L2',
                        onDown: () =>
                            onButtonDown('a'), // Alternative mapping to A
                        onUp: () => onButtonUp('a'),
                        scale: dynamicScale * settings.lShoulderScale,
                      ),
                      const SizedBox(width: 8),
                      _ShoulderButton(
                        label: 'L1',
                        onDown: () => onButtonDown('a'), // Map to Sega A
                        onUp: () => onButtonUp('a'),
                        scale: dynamicScale * settings.lShoulderScale,
                      ),
                    ],
                  ),
                ),

                // === LEFT CONTROLS: D-Pad ===
                Positioned(
                  left: (isPortrait ? 16 : 24) + settings.dpadOffsetX,
                  bottom: (isPortrait ? 110 : 20) + settings.dpadOffsetY,
                  child: _DPad(
                    onButtonDown: onButtonDown,
                    onButtonUp: onButtonUp,
                    size: dpadSize,
                  ),
                ),

                // === RIGHT CONTROLS: R1 & R2 Shoulder Buttons ===
                Positioned(
                  right: (isPortrait ? 16 : 24) + settings.rShoulderOffsetX,
                  bottom: (isPortrait ? 110 : 20) +
                      (136.0 * dynamicScale * settings.actionPadScale) +
                      (16.0 * dynamicScale * settings.actionPadScale) +
                      settings.rShoulderOffsetY,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ShoulderButton(
                        label: 'R1',
                        onDown: () => onButtonDown('c'), // Map to Sega C
                        onUp: () => onButtonUp('c'),
                        scale: dynamicScale * settings.rShoulderScale,
                      ),
                      const SizedBox(width: 8),
                      _ShoulderButton(
                        label: 'R2',
                        onDown: () =>
                            onButtonDown('c'), // Alternative mapping to C
                        onUp: () => onButtonUp('c'),
                        scale: dynamicScale * settings.rShoulderScale,
                      ),
                    ],
                  ),
                ),

                // === RIGHT CONTROLS: Action Buttons (PlayStation layout) ===
                Positioned(
                  right: (isPortrait ? 16 : 24) + settings.actionPadOffsetX,
                  bottom: (isPortrait ? 110 : 20) + settings.actionPadOffsetY,
                  child: _ActionButtons(
                    onButtonDown: onButtonDown,
                    onButtonUp: onButtonUp,
                    size: actionSize,
                  ),
                ),

                // === CENTER CONTROLS (Select/Share & Start/Options) ===
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: (isPortrait ? 30 : 16) + settings.centerOffsetY,
                  child: Center(
                    child: Transform.translate(
                      offset: Offset(settings.centerOffsetX, 0),
                      child: _CenterButtons(
                        onButtonDown: onButtonDown,
                        onButtonUp: onButtonUp,
                        scale: dynamicScale * settings.centerScale,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// D-PAD WIDGET (PlayStation style separated cross inside dish)
// ============================================================
class _DPad extends StatelessWidget {
  const _DPad({
    required this.onButtonDown,
    required this.onButtonUp,
    required this.size,
  });

  final void Function(String) onButtonDown;
  final void Function(String) onButtonUp;
  final double size;

  @override
  Widget build(BuildContext context) {
    final btnSize = size * 0.32;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // D-pad circular backplate
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.35),
                border: Border.all(
                    color: Colors.white.withOpacity(0.08), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ]),
          ),
          // UP Button
          Positioned(
            top: 4,
            child: _DPadDirectionButton(
              symbol: '▲',
              direction: 'up',
              width: btnSize,
              height: btnSize * 1.3,
              onDown: () => onButtonDown('up'),
              onUp: () => onButtonUp('up'),
            ),
          ),
          // DOWN Button
          Positioned(
            bottom: 4,
            child: _DPadDirectionButton(
              symbol: '▼',
              direction: 'down',
              width: btnSize,
              height: btnSize * 1.3,
              onDown: () => onButtonDown('down'),
              onUp: () => onButtonUp('down'),
            ),
          ),
          // LEFT Button
          Positioned(
            left: 4,
            child: _DPadDirectionButton(
              symbol: '◀',
              direction: 'left',
              width: btnSize * 1.3,
              height: btnSize,
              onDown: () => onButtonDown('left'),
              onUp: () => onButtonUp('left'),
            ),
          ),
          // RIGHT Button
          Positioned(
            right: 4,
            child: _DPadDirectionButton(
              symbol: '▶',
              direction: 'right',
              width: btnSize * 1.3,
              height: btnSize,
              onDown: () => onButtonDown('right'),
              onUp: () => onButtonUp('right'),
            ),
          ),
          // Center pivot cap
          Container(
            width: size * 0.28,
            height: size * 0.28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF161618),
              border: Border.all(color: Colors.black, width: 2),
            ),
          ),
        ],
      ),
    );
  }
}

class _DPadDirectionButton extends StatefulWidget {
  const _DPadDirectionButton({
    required this.symbol,
    required this.direction,
    required this.width,
    required this.height,
    required this.onDown,
    required this.onUp,
  });

  final String symbol;
  final String direction;
  final double width;
  final double height;
  final VoidCallback onDown;
  final VoidCallback onUp;

  @override
  State<_DPadDirectionButton> createState() => _DPadDirectionButtonState();
}

class _DPadDirectionButtonState extends State<_DPadDirectionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    BorderRadius borderRadius;
    switch (widget.direction) {
      case 'up':
        borderRadius = const BorderRadius.vertical(top: Radius.circular(8));
        break;
      case 'down':
        borderRadius = const BorderRadius.vertical(bottom: Radius.circular(8));
        break;
      case 'left':
        borderRadius = const BorderRadius.horizontal(left: Radius.circular(8));
        break;
      case 'right':
        borderRadius = const BorderRadius.horizontal(right: Radius.circular(8));
        break;
      default:
        borderRadius = BorderRadius.circular(4);
    }

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.selectionClick();
        setState(() => _pressed = true);
        widget.onDown();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onUp();
      },
      onTapCancel: () {
        setState(() => _pressed = false);
        widget.onUp();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: _pressed
              ? Colors.white.withOpacity(0.2)
              : Colors.black.withOpacity(0.55),
          borderRadius: borderRadius,
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
        ),
        child: Center(
          child: Text(
            widget.symbol,
            style: TextStyle(
              color: _pressed ? Colors.white : Colors.white60,
              fontSize: widget.width * 0.42,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ACTION BUTTONS WIDGET (PlayStation style: Triangle, Circle, Cross, Square)
// ============================================================
class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.onButtonDown,
    required this.onButtonUp,
    required this.size,
  });

  final void Function(String) onButtonDown;
  final void Function(String) onButtonUp;
  final double size;

  @override
  Widget build(BuildContext context) {
    final btnSize = size * 0.28;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Action Pad backplate
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.35),
                border: Border.all(
                    color: Colors.white.withOpacity(0.08), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ]),
          ),
          // TRIANGLE (▲) - Top Action Button (Maps to Start/Pause)
          Positioned(
            top: 6,
            child: _ActionPadButton(
              symbol: '▲',
              color: const Color(0xFF00E676), // PlayStation Green
              size: btnSize,
              onDown: () => onButtonDown('start'),
              onUp: () => onButtonUp('start'),
            ),
          ),
          // CIRCLE (●) - Right Action Button (Maps to Sega C)
          Positioned(
            right: 6,
            child: _ActionPadButton(
              symbol: '●',
              color: const Color(0xFFFF1744), // PlayStation Red
              size: btnSize,
              onDown: () => onButtonDown('c'),
              onUp: () => onButtonUp('c'),
            ),
          ),
          // CROSS (✖) - Bottom Action Button (Maps to Sega B)
          Positioned(
            bottom: 6,
            child: _ActionPadButton(
              symbol: '✖',
              color: const Color(0xFF2979FF), // PlayStation Blue
              size: btnSize,
              onDown: () => onButtonDown('b'),
              onUp: () => onButtonUp('b'),
            ),
          ),
          // SQUARE (■) - Left Action Button (Maps to Sega A)
          Positioned(
            left: 6,
            child: _ActionPadButton(
              symbol: '■',
              color: const Color(0xFFE040FB), // PlayStation Pink/Magenta
              size: btnSize,
              onDown: () => onButtonDown('a'),
              onUp: () => onButtonUp('a'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPadButton extends StatefulWidget {
  const _ActionPadButton({
    required this.symbol,
    required this.color,
    required this.size,
    required this.onDown,
    required this.onUp,
  });

  final String symbol;
  final Color color;
  final double size;
  final VoidCallback onDown;
  final VoidCallback onUp;

  @override
  State<_ActionPadButton> createState() => _ActionPadButtonState();
}

class _ActionPadButtonState extends State<_ActionPadButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.selectionClick();
        setState(() => _pressed = true);
        widget.onDown();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onUp();
      },
      onTapCancel: () {
        setState(() => _pressed = false);
        widget.onUp();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _pressed
              ? widget.color.withOpacity(0.3)
              : Colors.black.withOpacity(0.65),
          border: Border.all(
              color: widget.color.withOpacity(_pressed ? 0.9 : 0.45), width: 2),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: widget.color.withOpacity(0.6),
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                  )
                ],
        ),
        child: Center(
          child: Text(
            widget.symbol,
            style: TextStyle(
              color: _pressed ? Colors.white : widget.color.withOpacity(0.85),
              fontSize: widget.size * 0.42,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SHOULDER BUTTON WIDGET (L1/L2, R1/R2 Capsule Buttons)
// ============================================================
class _ShoulderButton extends StatefulWidget {
  const _ShoulderButton({
    required this.label,
    required this.onDown,
    required this.onUp,
    required this.scale,
  });

  final String label;
  final VoidCallback onDown;
  final VoidCallback onUp;
  final double scale;

  @override
  State<_ShoulderButton> createState() => _ShoulderButtonState();
}

class _ShoulderButtonState extends State<_ShoulderButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final width = 54.0 * widget.scale;
    final height = 24.0 * widget.scale;
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.selectionClick();
        setState(() => _pressed = true);
        widget.onDown();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onUp();
      },
      onTapCancel: () {
        setState(() => _pressed = false);
        widget.onUp();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6 * widget.scale),
          color: _pressed
              ? Colors.white.withOpacity(0.2)
              : Colors.black.withOpacity(0.55),
          border: Border.all(
              color: Colors.white.withOpacity(_pressed ? 0.35 : 0.15),
              width: 1.5),
        ),
        child: Center(
          child: Text(
            widget.label,
            style: TextStyle(
              color: _pressed ? Colors.white : Colors.white70,
              fontSize: 10 * widget.scale,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// CENTER PILL BUTTONS (SHARE / OPTIONS)
// ============================================================
class _CenterButtons extends StatelessWidget {
  const _CenterButtons({
    required this.onButtonDown,
    required this.onButtonUp,
    required this.scale,
  });

  final void Function(String) onButtonDown;
  final void Function(String) onButtonUp;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CenterPillButton(
          label: 'SHARE',
          onDown: () => onButtonDown('mode'), // Labeled MODE internally
          onUp: () => onButtonUp('mode'),
          scale: scale,
        ),
        SizedBox(width: 24 * scale),
        _CenterPillButton(
          label: 'OPTIONS',
          onDown: () => onButtonDown('start'), // Maps to Sega START
          onUp: () => onButtonUp('start'),
          scale: scale,
        ),
      ],
    );
  }
}

class _CenterPillButton extends StatefulWidget {
  const _CenterPillButton({
    required this.label,
    required this.onDown,
    required this.onUp,
    required this.scale,
  });

  final String label;
  final VoidCallback onDown;
  final VoidCallback onUp;
  final double scale;

  @override
  State<_CenterPillButton> createState() => _CenterPillButtonState();
}

class _CenterPillButtonState extends State<_CenterPillButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final width = 52.0 * widget.scale;
    final height = 16.0 * widget.scale;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapDown: (_) {
            HapticFeedback.selectionClick();
            setState(() => _pressed = true);
            widget.onDown();
          },
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onUp();
          },
          onTapCancel: () {
            setState(() => _pressed = false);
            widget.onUp();
          },
          child: Transform.rotate(
            angle: -0.2, // PS slanted angle for SELECT/START rubber pills
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 60),
              width: width,
              height: height,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(height / 2),
                  color: _pressed
                      ? Colors.white.withOpacity(0.35)
                      : Colors.black.withOpacity(0.7),
                  border: Border.all(
                      color: Colors.white.withOpacity(_pressed ? 0.35 : 0.15),
                      width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                    )
                  ]),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.label,
          style: TextStyle(
            color: Colors.white30,
            fontSize: 7 * widget.scale,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
