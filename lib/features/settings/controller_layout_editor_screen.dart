import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/glass_container.dart';
import '../settings/providers/settings_provider.dart';

class ControllerLayoutEditorScreen extends ConsumerStatefulWidget {
  const ControllerLayoutEditorScreen({super.key});

  @override
  ConsumerState<ControllerLayoutEditorScreen> createState() =>
      _ControllerLayoutEditorScreenState();
}

class _ControllerLayoutEditorScreenState
    extends ConsumerState<ControllerLayoutEditorScreen> {
  String? _selectedPart; // 'dpad', 'action', 'lsh', 'rsh', 'center'

  // Local state for dragging offsets and scales to make dragging smooth
  double _dpadX = 0.0;
  double _dpadY = 0.0;
  double _dpadS = 1.0;

  double _actionX = 0.0;
  double _actionY = 0.0;
  double _actionS = 1.0;

  double _lShX = 0.0;
  double _lShY = 0.0;
  double _lShS = 1.0;

  double _rShX = 0.0;
  double _rShY = 0.0;
  double _rShS = 1.0;

  double _centX = 0.0;
  double _centY = 0.0;
  double _centS = 1.0;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Lock to landscape during editing since controllers are designed for landscape gameplay
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _initializeValues(AppSettings settings) {
    if (_initialized) return;
    _dpadX = settings.dpadOffsetX;
    _dpadY = settings.dpadOffsetY;
    _dpadS = settings.dpadScale;

    _actionX = settings.actionPadOffsetX;
    _actionY = settings.actionPadOffsetY;
    _actionS = settings.actionPadScale;

    _lShX = settings.lShoulderOffsetX;
    _lShY = settings.lShoulderOffsetY;
    _lShS = settings.lShoulderScale;

    _rShX = settings.rShoulderOffsetX;
    _rShY = settings.rShoulderOffsetY;
    _rShS = settings.rShoulderScale;

    _centX = settings.centerOffsetX;
    _centY = settings.centerOffsetY;
    _centS = settings.centerScale;

    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    _initializeValues(settings);

    return Scaffold(
      backgroundColor: const Color(0xFF06060C),
      body: Stack(
        children: [
          // === Blueprint Grid Background ===
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(),
            ),
          ),

          // === Centered Mock Game Screen Bounds (To help user place controls) ===
          Center(
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: Colors.white12, width: 1.5),
                ),
                child: const Center(
                  child: Text(
                    'GAME VIEWPORT (4:3)',
                    style: TextStyle(
                        color: Colors.white12,
                        fontSize: 16,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),

          // === Drag & Edit Area ===
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double baseScale = constraints.maxWidth < 600 ? 0.9 : 1.0;

                // Resolved coordinate containers
                final dpadSize = 136.0 * _dpadS * baseScale;
                final actionSize = 136.0 * _actionS * baseScale;

                return Stack(
                  children: [
                    // === L1/L2 Shoulder Buttons Node ===
                    Positioned(
                      left: 24 + _lShX,
                      bottom: 20 +
                          136.0 * _dpadS * baseScale +
                          16 * _dpadS * baseScale +
                          _lShY,
                      child: _buildDraggableNode(
                        id: 'lsh',
                        scale: _lShS * baseScale,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _mockShoulderButton('L2', _lShS * baseScale),
                            const SizedBox(width: 8),
                            _mockShoulderButton('L1', _lShS * baseScale),
                          ],
                        ),
                        onDrag: (dx, dy) {
                          setState(() {
                            _lShX += dx;
                            _lShY -= dy;
                          });
                        },
                      ),
                    ),

                    // === D-Pad Button Node ===
                    Positioned(
                      left: 24 + _dpadX,
                      bottom: 20 + _dpadY,
                      child: _buildDraggableNode(
                        id: 'dpad',
                        scale: _dpadS * baseScale,
                        child: _mockDPad(dpadSize),
                        onDrag: (dx, dy) {
                          setState(() {
                            _dpadX += dx;
                            _dpadY -= dy;
                          });
                        },
                      ),
                    ),

                    // === R1/R2 Shoulder Buttons Node ===
                    Positioned(
                      right: 24 + _rShX,
                      bottom: 20 +
                          136.0 * _actionS * baseScale +
                          16 * _actionS * baseScale +
                          _rShY,
                      child: _buildDraggableNode(
                        id: 'rsh',
                        scale: _rShS * baseScale,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _mockShoulderButton('R1', _rShS * baseScale),
                            const SizedBox(width: 8),
                            _mockShoulderButton('R2', _rShS * baseScale),
                          ],
                        ),
                        onDrag: (dx, dy) {
                          setState(() {
                            _rShX -=
                                dx; // Moving left increases offset from right edge
                            _rShY -= dy;
                          });
                        },
                      ),
                    ),

                    // === Action Pad Buttons Node ===
                    Positioned(
                      right: 24 + _actionX,
                      bottom: 20 + _actionY,
                      child: _buildDraggableNode(
                        id: 'action',
                        scale: _actionS * baseScale,
                        child: _mockActionButtons(actionSize),
                        onDrag: (dx, dy) {
                          setState(() {
                            _actionX -=
                                dx; // Moving left increases offset from right edge
                            _actionY -= dy;
                          });
                        },
                      ),
                    ),

                    // === Center Select/Start Pills Node ===
                    Positioned(
                      left:
                          (constraints.maxWidth - (150 * _centS * baseScale)) /
                                  2 +
                              _centX,
                      bottom: 16 + _centY,
                      child: _buildDraggableNode(
                        id: 'center',
                        scale: _centS * baseScale,
                        child: _mockCenterButtons(_centS * baseScale),
                        onDrag: (dx, dy) {
                          setState(() {
                            _centX += dx;
                            _centY -= dy;
                          });
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // === Floating Header Toolbar ===
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.arrow_back_ios_new_rounded,
                            size: 12, color: Colors.white70),
                        SizedBox(width: 8),
                        Text('Back',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                Text('Controller layout', style: AppTextStyles.headlineSmall),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _resetLayout,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Text('Reset',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _saveLayout,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Save Layout',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // === Floating Bottom Resize Toolbar (Only shows if a node is selected) ===
          if (_selectedPart != null)
            Positioned(
              bottom: 12,
              left: 32,
              right: 32,
              child: Center(
                child: GlassContainer(
                  borderRadius: BorderRadius.circular(16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  width: 480,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.2), width: 1.5),
                  child: Row(
                    children: [
                      Text(
                        _getSelectedName().toUpperCase(),
                        style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.neonCyan,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 16),
                      const Text('Size:',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                      Expanded(
                        child: Slider(
                          value: _getSelectedScale(),
                          min: 0.6,
                          max: 1.4,
                          divisions: 8,
                          onChanged: (val) {
                            setState(() {
                              _updateSelectedScale(val);
                            });
                          },
                        ),
                      ),
                      Text(
                        '${(_getSelectedScale() * 100).toInt()}%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white54, size: 18),
                        onPressed: () => setState(() => _selectedPart = null),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // === Dynamic Layout Node Builder ===
  Widget _buildDraggableNode({
    required String id,
    required double scale,
    required Widget child,
    required void Function(double, double) onDrag,
  }) {
    final isSelected = _selectedPart == id;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedPart = id;
        });
      },
      onPanUpdate: (details) {
        if (_selectedPart != id) {
          setState(() {
            _selectedPart = id;
          });
        }
        onDrag(details.delta.dx, details.delta.dy);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.neonCyan : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.neonCyan.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: child,
      ),
    );
  }

  // === Save and Reset Methods ===
  Future<void> _saveLayout() async {
    HapticFeedback.mediumImpact();
    final notifier = ref.read(settingsProvider.notifier);
    await notifier.updateDpadLayout(_dpadX, _dpadY, _dpadS);
    await notifier.updateActionPadLayout(_actionX, _actionY, _actionS);
    await notifier.updateLShoulderLayout(_lShX, _lShY, _lShS);
    await notifier.updateRShoulderLayout(_rShX, _rShY, _rShS);
    await notifier.updateCenterLayout(_centX, _centY, _centS);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Touch controller layout saved successfully!'),
        backgroundColor: AppColors.success,
      ),
    );
    context.pop();
  }

  void _resetLayout() {
    HapticFeedback.heavyImpact();
    setState(() {
      _dpadX = 0.0;
      _dpadY = 0.0;
      _dpadS = 1.0;

      _actionX = 0.0;
      _actionY = 0.0;
      _actionS = 1.0;

      _lShX = 0.0;
      _lShY = 0.0;
      _lShS = 1.0;

      _rShX = 0.0;
      _rShY = 0.0;
      _rShS = 1.0;

      _centX = 0.0;
      _centY = 0.0;
      _centS = 1.0;

      _selectedPart = null;
    });
  }

  // === Selected Element Helpers ===
  String _getSelectedName() {
    switch (_selectedPart) {
      case 'dpad':
        return 'D-Pad';
      case 'action':
        return 'Action Pad';
      case 'lsh':
        return 'Left Shoulder';
      case 'rsh':
        return 'Right Shoulder';
      case 'center':
        return 'Center Pills';
      default:
        return '';
    }
  }

  double _getSelectedScale() {
    switch (_selectedPart) {
      case 'dpad':
        return _dpadS;
      case 'action':
        return _actionS;
      case 'lsh':
        return _lShS;
      case 'rsh':
        return _rShS;
      case 'center':
        return _centS;
      default:
        return 1.0;
    }
  }

  void _updateSelectedScale(double scale) {
    switch (_selectedPart) {
      case 'dpad':
        _dpadS = scale;
        break;
      case 'action':
        _actionS = scale;
        break;
      case 'lsh':
        _lShS = scale;
        break;
      case 'rsh':
        _rShS = scale;
        break;
      case 'center':
        _centS = scale;
        break;
    }
  }

  // === Mock Controller Graphics (Rendered identical to actual gameplay touch layouts) ===
  Widget _mockShoulderButton(String label, double scale) {
    return Container(
      width: 54 * scale,
      height: 24 * scale,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6 * scale),
        border: Border.all(color: Colors.white30, width: 1.5),
      ),
      child: Center(
        child: Text(label,
            style: TextStyle(
                color: Colors.white70,
                fontSize: 10 * scale,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _mockDPad(double size) {
    final btnSize = size * 0.32;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
                border: Border.all(color: Colors.white24)),
          ),
          Positioned(
              top: 4, child: _mockDirButton('▲', btnSize, btnSize * 1.3)),
          Positioned(
              bottom: 4, child: _mockDirButton('▼', btnSize, btnSize * 1.3)),
          Positioned(
              left: 4, child: _mockDirButton('◀', btnSize * 1.3, btnSize)),
          Positioned(
              right: 4, child: _mockDirButton('▶', btnSize * 1.3, btnSize)),
          Container(
            width: size * 0.28,
            height: size * 0.28,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1E1E1E),
                border: Border.all(color: Colors.black26)),
          ),
        ],
      ),
    );
  }

  Widget _mockDirButton(String label, double w, double h) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white12),
      ),
      child: Center(
        child: Text(label,
            style: TextStyle(
                color: Colors.white54,
                fontSize: w * 0.42,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _mockActionButtons(double size) {
    final btnSize = size * 0.28;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
                border: Border.all(color: Colors.white24)),
          ),
          Positioned(
              top: 6,
              child: _mockActionButton('▲', const Color(0xFF00E676), btnSize)),
          Positioned(
              right: 6,
              child: _mockActionButton('●', const Color(0xFFFF1744), btnSize)),
          Positioned(
              bottom: 6,
              child: _mockActionButton('✖', const Color(0xFF2979FF), btnSize)),
          Positioned(
              left: 6,
              child: _mockActionButton('■', const Color(0xFFE040FB), btnSize)),
        ],
      ),
    );
  }

  Widget _mockActionButton(String sym, Color col, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.65),
        border: Border.all(color: col.withOpacity(0.55), width: 2),
      ),
      child: Center(
        child: Text(sym,
            style: TextStyle(
                color: col.withOpacity(0.85),
                fontSize: size * 0.42,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _mockCenterButtons(double scale) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _mockPill('SHARE', scale),
        SizedBox(width: 24 * scale),
        _mockPill('OPTIONS', scale),
      ],
    );
  }

  Widget _mockPill(String label, double scale) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.rotate(
          angle: -0.2,
          child: Container(
            width: 52 * scale,
            height: 16 * scale,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8 * scale),
              color: Colors.white.withOpacity(0.12),
              border: Border.all(color: Colors.white30),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(
                color: Colors.white30,
                fontSize: 7 * scale,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// === Designer Grid Background Painter ===
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF151528)
      ..strokeWidth = 1.0;

    const double step = 32.0;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
