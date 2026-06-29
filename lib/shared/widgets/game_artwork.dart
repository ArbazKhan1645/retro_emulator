import 'dart:io' show File;
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';

/// Displays remote artwork when available and a deterministic editorial
/// composition when it is not. Offline libraries still feel intentionally
/// designed instead of showing an empty placeholder.
class GameArtwork extends StatelessWidget {
  const GameArtwork({
    super.key,
    required this.title,
    this.imageUrl,
    this.assetPath,
    this.fit = BoxFit.cover,
    this.showTitle = false,
  });

  final String title;
  final String? imageUrl;
  final String? assetPath;
  final BoxFit fit;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final asset = assetPath;
    if (asset != null && asset.isNotEmpty) {
      if (!kIsWeb && !asset.startsWith('assets/')) {
        final file = File(asset);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: fit,
            errorBuilder: (_, __, ___) => _GeneratedArtwork(
              title: title,
              showTitle: showTitle,
            ),
          );
        }
      }

      return Image.asset(
        asset,
        fit: fit,
        errorBuilder: (_, __, ___) => _GeneratedArtwork(
          title: title,
          showTitle: showTitle,
        ),
      );
    }

    final url = imageUrl;
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        placeholder: (_, __) => _GeneratedArtwork(
          title: title,
          showTitle: showTitle,
        ),
        errorWidget: (_, __, ___) => _GeneratedArtwork(
          title: title,
          showTitle: showTitle,
        ),
      );
    }
    return _GeneratedArtwork(title: title, showTitle: showTitle);
  }
}

class _GeneratedArtwork extends StatelessWidget {
  const _GeneratedArtwork({required this.title, required this.showTitle});

  final String title;
  final bool showTitle;

  static const _palettes = <List<Color>>[
    [Color(0xFF17243A), Color(0xFFB26C4A), Color(0xFFE0B66C)],
    [Color(0xFF142D2D), Color(0xFF397C72), Color(0xFFD1A866)],
    [Color(0xFF241B35), Color(0xFF705A8C), Color(0xFFD28B72)],
    [Color(0xFF30191E), Color(0xFF9B4B57), Color(0xFFE0AA67)],
    [Color(0xFF18243A), Color(0xFF496DA6), Color(0xFFB9A16B)],
    [Color(0xFF2A2418), Color(0xFF907644), Color(0xFFCF7658)],
  ];

  @override
  Widget build(BuildContext context) {
    final hash = title.codeUnits.fold<int>(0, (value, unit) => value + unit);
    final palette = _palettes[hash % _palettes.length];
    final code = (hash % 97 + 1).toString().padLeft(2, '0');
    final initials = title
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return LayoutBuilder(
      builder: (context, constraints) {
        final shortSide = math.min(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    palette[0],
                    Color.lerp(palette[0], palette[1], .38)!
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _ArtworkPainter(
                  accent: palette[1],
                  highlight: palette[2],
                  seed: hash,
                ),
              ),
            ),
            Positioned(
              top: shortSide * .08,
              left: shortSide * .08,
              child: Text(
                'RV  /  $code',
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white.withOpacity(.68),
                  letterSpacing: 1.2,
                  fontSize: math.max(8, shortSide * .045),
                ),
              ),
            ),
            Positioned(
              right: -shortSide * .04,
              bottom: showTitle ? shortSide * .12 : -shortSide * .05,
              child: Text(
                initials.isEmpty ? 'R' : initials,
                style: AppTextStyles.displayLarge.copyWith(
                  fontSize: shortSide * .62,
                  height: .8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -shortSide * .06,
                  color: palette[2].withOpacity(.2),
                ),
              ),
            ),
            Positioned(
              left: shortSide * .08,
              bottom: shortSide * .08,
              child: Container(
                width: shortSide * .22,
                height: 3,
                decoration: BoxDecoration(
                  color: palette[2],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            if (showTitle)
              Positioned(
                left: shortSide * .08,
                right: shortSide * .12,
                bottom: shortSide * .13,
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: Colors.white,
                    fontSize: math.max(18, shortSide * .13),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ArtworkPainter extends CustomPainter {
  const _ArtworkPainter({
    required this.accent,
    required this.highlight,
    required this.seed,
  });

  final Color accent;
  final Color highlight;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final diagonal = Paint()
      ..color = Colors.white.withOpacity(.035)
      ..strokeWidth = 1;
    final spacing = math.max(24.0, size.shortestSide * .13);
    for (double x = -size.height; x < size.width; x += spacing) {
      canvas.drawLine(
          Offset(x, size.height), Offset(x + size.height, 0), diagonal);
    }

    final orb = Paint()
      ..shader = RadialGradient(
        colors: [accent.withOpacity(.6), accent.withOpacity(0)],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * .72, size.height * .28),
          radius: size.longestSide * .55,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * .72, size.height * .28),
      size.longestSide * .55,
      orb,
    );

    final ring = Paint()
      ..color = highlight.withOpacity(.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, size.shortestSide * .012);
    final center =
        Offset(size.width * (.66 + (seed % 9) / 100), size.height * .42);
    canvas.drawCircle(center, size.shortestSide * .27, ring);
    canvas.drawCircle(center, size.shortestSide * .19,
        ring..color = highlight.withOpacity(.16));
  }

  @override
  bool shouldRepaint(covariant _ArtworkPainter oldDelegate) =>
      oldDelegate.seed != seed;
}
