import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
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
// D-PAD WIDGET (Stateful, unified sliding multi-directional)
// ============================================================
class _DPad extends StatefulWidget {
  const _DPad({
    required this.onButtonDown,
    required this.onButtonUp,
    required this.size,
  });

  final void Function(String) onButtonDown;
  final void Function(String) onButtonUp;
  final double size;

  @override
  State<_DPad> createState() => _DPadState();
}

class _DPadState extends State<_DPad> {
  bool _up = false;
  bool _down = false;
  bool _left = false;
  bool _right = false;

  void _updateTouch(Offset localPos) {
    final R = widget.size / 2;
    final dx = localPos.dx - R;
    final dy = localPos.dy - R;
    final dist = math.sqrt(dx * dx + dy * dy);

    bool newUp = false;
    bool newDown = false;
    bool newLeft = false;
    bool newRight = false;

    // Generous boundary: allow sliding up to 2.2x radius before release for comfort
    if (dist >= R * 0.15 && dist <= R * 2.2) {
      final angle = math.atan2(dy, dx) * 180 / math.pi;

      // 8-way directional mapping (diagonals trigger both buttons)
      if (angle >= -67.5 && angle < -22.5) {
        newUp = true;
        newRight = true;
      } else if (angle >= -22.5 && angle < 22.5) {
        newRight = true;
      } else if (angle >= 22.5 && angle < 67.5) {
        newDown = true;
        newRight = true;
      } else if (angle >= 67.5 && angle < 112.5) {
        newDown = true;
      } else if (angle >= 112.5 && angle < 157.5) {
        newDown = true;
        newLeft = true;
      } else if (angle >= 157.5 || angle < -157.5) {
        newLeft = true;
      } else if (angle >= -157.5 && angle < -112.5) {
        newUp = true;
        newLeft = true;
      } else if (angle >= -112.5 && angle < -67.5) {
        newUp = true;
      }
    }

    _setButtonState('up', newUp);
    _setButtonState('down', newDown);
    _setButtonState('left', newLeft);
    _setButtonState('right', newRight);
  }

  void _setButtonState(String key, bool pressed) {
    bool current;
    switch (key) {
      case 'up': current = _up; break;
      case 'down': current = _down; break;
      case 'left': current = _left; break;
      case 'right': current = _right; break;
      default: return;
    }

    if (current != pressed) {
      if (pressed) {
        HapticFeedback.selectionClick();
        widget.onButtonDown(key);
      } else {
        widget.onButtonUp(key);
      }

      setState(() {
        switch (key) {
          case 'up': _up = pressed; break;
          case 'down': _down = pressed; break;
          case 'left': _left = pressed; break;
          case 'right': _right = pressed; break;
        }
      });
    }
  }

  void _releaseAll() {
    _setButtonState('up', false);
    _setButtonState('down', false);
    _setButtonState('left', false);
    _setButtonState('right', false);
  }

  @override
  Widget build(BuildContext context) {
    final btnSize = widget.size * 0.32;
    return Listener(
      onPointerDown: (event) => _updateTouch(event.localPosition),
      onPointerMove: (event) => _updateTouch(event.localPosition),
      onPointerUp: (_) => _releaseAll(),
      onPointerCancel: (_) => _releaseAll(),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // D-pad circular backplate
            Container(
              width: widget.size,
              height: widget.size,
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
              child: _DPadVisualButton(
                symbol: '▲',
                direction: 'up',
                width: btnSize,
                height: btnSize * 1.3,
                isPressed: _up,
              ),
            ),
            // DOWN Button
            Positioned(
              bottom: 4,
              child: _DPadVisualButton(
                symbol: '▼',
                direction: 'down',
                width: btnSize,
                height: btnSize * 1.3,
                isPressed: _down,
              ),
            ),
            // LEFT Button
            Positioned(
              left: 4,
              child: _DPadVisualButton(
                symbol: '◀',
                direction: 'left',
                width: btnSize * 1.3,
                height: btnSize,
                isPressed: _left,
              ),
            ),
            // RIGHT Button
            Positioned(
              right: 4,
              child: _DPadVisualButton(
                symbol: '▶',
                direction: 'right',
                width: btnSize * 1.3,
                height: btnSize,
                isPressed: _right,
              ),
            ),
            // Center pivot cap
            Container(
              width: widget.size * 0.28,
              height: widget.size * 0.28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF161618),
                border: Border.all(color: Colors.black, width: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DPadVisualButton extends StatelessWidget {
  const _DPadVisualButton({
    required this.symbol,
    required this.direction,
    required this.width,
    required this.height,
    required this.isPressed,
  });

  final String symbol;
  final String direction;
  final double width;
  final double height;
  final bool isPressed;

  @override
  Widget build(BuildContext context) {
    BorderRadius borderRadius;
    switch (direction) {
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 60),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isPressed
            ? Colors.white.withOpacity(0.25)
            : Colors.black.withOpacity(0.55),
        borderRadius: borderRadius,
        border: Border.all(color: Colors.white.withOpacity(isPressed ? 0.25 : 0.12), width: 1),
      ),
      child: Center(
        child: Text(
          symbol,
          style: TextStyle(
            color: isPressed ? Colors.white : Colors.white60,
            fontSize: width * 0.38,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ACTION BUTTONS WIDGET (Stateful, unified multi-touch sectors)
// ============================================================
class _ActionButtons extends StatefulWidget {
  const _ActionButtons({
    required this.onButtonDown,
    required this.onButtonUp,
    required this.size,
  });

  final void Function(String) onButtonDown;
  final void Function(String) onButtonUp;
  final double size;

  @override
  State<_ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends State<_ActionButtons> {
  // Track which button each active pointer is pressing
  final Map<int, String> _pointerToButton = {};

  // Visual pressed states
  bool _aPressed = false;
  bool _bPressed = false;
  bool _cPressed = false;
  bool _startPressed = false;

  void _handlePointerEvent(PointerEvent event) {
    final R = widget.size / 2;
    final dx = event.localPosition.dx - R;
    final dy = event.localPosition.dy - R;
    final dist = math.sqrt(dx * dx + dy * dy);

    String? targetButton;

    // Multi-touch target scaling: allow touching slightly outside visual bounds (up to 1.45x radius)
    if (dist >= 0 && dist <= R * 1.45) {
      final angle = math.atan2(dy, dx) * 180 / math.pi;

      if (angle >= -45 && angle < 45) {
        targetButton = 'c';
      } else if (angle >= 45 && angle < 135) {
        targetButton = 'b';
      } else if (angle >= 135 || angle < -135) {
        targetButton = 'a';
      } else if (angle >= -135 && angle < -45) {
        targetButton = 'start';
      }
    }

    final prevButton = _pointerToButton[event.pointer];

    if (event is PointerDownEvent || event is PointerMoveEvent) {
      if (targetButton != prevButton) {
        if (prevButton != null) {
          _releaseButtonForPointer(event.pointer, prevButton);
        }
        if (targetButton != null) {
          _pressButtonForPointer(event.pointer, targetButton);
        }
      }
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      if (prevButton != null) {
        _releaseButtonForPointer(event.pointer, prevButton);
      }
    }
  }

  void _pressButtonForPointer(int pointer, String button) {
    _pointerToButton[pointer] = button;
    
    // Trigger onButtonDown only if this button wasn't already pressed by another finger
    final alreadyPressed = _pointerToButton.values.where((b) => b == button).length > 1;
    
    if (!alreadyPressed) {
      HapticFeedback.selectionClick();
      widget.onButtonDown(button);
      _setVisualState(button, true);
    }
  }

  void _releaseButtonForPointer(int pointer, String button) {
    _pointerToButton.remove(pointer);
    
    // Trigger onButtonUp only if no other finger is currently pressing this button
    final stillPressed = _pointerToButton.values.contains(button);
    
    if (!stillPressed) {
      widget.onButtonUp(button);
      _setVisualState(button, false);
    }
  }

  void _setVisualState(String button, bool pressed) {
    setState(() {
      switch (button) {
        case 'a': _aPressed = pressed; break;
        case 'b': _bPressed = pressed; break;
        case 'c': _cPressed = pressed; break;
        case 'start': _startPressed = pressed; break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final btnSize = widget.size * 0.28;
    return Listener(
      onPointerDown: _handlePointerEvent,
      onPointerMove: _handlePointerEvent,
      onPointerUp: _handlePointerEvent,
      onPointerCancel: _handlePointerEvent,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Action Pad backplate
            Container(
              width: widget.size,
              height: widget.size,
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
              child: _ActionPadVisualButton(
                symbol: '▲',
                color: const Color(0xFF00E676), // PlayStation Green
                size: btnSize,
                isPressed: _startPressed,
              ),
            ),
            // CIRCLE (●) - Right Action Button (Maps to Sega C)
            Positioned(
              right: 6,
              child: _ActionPadVisualButton(
                symbol: '●',
                color: const Color(0xFFFF1744), // PlayStation Red
                size: btnSize,
                isPressed: _cPressed,
              ),
            ),
            // CROSS (✖) - Bottom Action Button (Maps to Sega B)
            Positioned(
              bottom: 6,
              child: _ActionPadVisualButton(
                symbol: '✖',
                color: const Color(0xFF2979FF), // PlayStation Blue
                size: btnSize,
                isPressed: _bPressed,
              ),
            ),
            // SQUARE (■) - Left Action Button (Maps to Sega A)
            Positioned(
              left: 6,
              child: _ActionPadVisualButton(
                symbol: '■',
                color: const Color(0xFFE040FB), // PlayStation Pink/Magenta
                size: btnSize,
                isPressed: _aPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionPadVisualButton extends StatelessWidget {
  const _ActionPadVisualButton({
    required this.symbol,
    required this.color,
    required this.size,
    required this.isPressed,
  });

  final String symbol;
  final Color color;
  final double size;
  final bool isPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 60),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isPressed
            ? color.withOpacity(0.3)
            : Colors.black.withOpacity(0.65),
        border: Border.all(
            color: color.withOpacity(isPressed ? 0.9 : 0.45), width: 2),
        boxShadow: isPressed
            ? [
                BoxShadow(
                  color: color.withOpacity(0.6),
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
          symbol,
          style: TextStyle(
            color: isPressed ? Colors.white : color.withOpacity(0.85),
            fontSize: size * 0.42,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SHOULDER BUTTON WIDGET (L1/L2, R1/R2 Capsule Buttons with expanded hitbox)
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
      behavior: HitTestBehavior.opaque,
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
      child: Padding(
        padding: EdgeInsets.all(10.0 * widget.scale), // Expanded invisible hit target padding
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
      ),
    );
  }
}

// ============================================================
// CENTER PILL BUTTONS (SHARE / OPTIONS with expanded hitbox)
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
        SizedBox(width: 12 * scale),
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
          behavior: HitTestBehavior.opaque,
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
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.0 * widget.scale, vertical: 10.0 * widget.scale), // Expanded target padding
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
        ),
        const SizedBox(height: 4),
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

