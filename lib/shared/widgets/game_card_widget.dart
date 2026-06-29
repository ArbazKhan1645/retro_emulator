import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/game_model.dart';
import 'console_badge_widget.dart';
import 'game_artwork.dart';

class GameCardWidget extends StatefulWidget {
  const GameCardWidget({
    super.key,
    required this.game,
    required this.onTap,
    this.onFavoriteTap,
    this.width,
    this.height,
    this.showRecentBadge = false,
    this.animationDelay = Duration.zero,
  });

  final GameModel game;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteTap;
  final double? width;
  final double? height;
  final bool showRecentBadge;
  final Duration animationDelay;

  @override
  State<GameCardWidget> createState() => _GameCardWidgetState();
}

class _GameCardWidgetState extends State<GameCardWidget> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final width = widget.width ?? AppConstants.cardWidth;
    final height = widget.height ?? AppConstants.cardHeight;

    return RepaintBoundary(
      child: AnimatedScale(
        scale: _pressed ? .975 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: SizedBox(
          width: width,
          height: height,
          child: Material(
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
              side: BorderSide(color: Colors.white.withValues(alpha: .08)),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onTap();
              },
              onHighlightChanged: (value) {
                if (_pressed != value) setState(() => _pressed = value);
              },
              child: _GameCardBody(
                game: widget.game,
                showRecentBadge: widget.showRecentBadge,
                onFavoriteTap: widget.onFavoriteTap,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GameCardBody extends StatelessWidget {
  const _GameCardBody({
    required this.game,
    required this.showRecentBadge,
    this.onFavoriteTap,
  });

  final GameModel game;
  final bool showRecentBadge;
  final VoidCallback? onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: GameArtwork(
            key: ValueKey('art_${game.id}_${game.coverUrl ?? ''}'),
            title: game.title,
            imageUrl: game.coverUrl,
          ),
        ),
        const RepaintBoundary(child: _CardGradientOverlay()),
        Positioned(
          left: 10,
          top: 10,
          child: ConsoleBadge(
            consoleName: game.consolePlatform,
            compact: true,
          ),
        ),
        if (onFavoriteTap != null)
          Positioned(
            top: 6,
            right: 6,
            child: IconButton(
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.overlay.withValues(alpha: .58),
                foregroundColor: game.isFavorite
                    ? AppColors.hotPink
                    : Colors.white.withValues(alpha: .78),
              ),
              onPressed: onFavoriteTap,
              icon: Icon(
                game.isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 18,
              ),
            ),
          ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: _GameCardFooter(
            game: game,
            showRecentBadge: showRecentBadge,
            accent: accent,
          ),
        ),
      ],
    );
  }
}

class _CardGradientOverlay extends StatelessWidget {
  const _CardGradientOverlay();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x1A000000),
            Color(0x00000000),
            Color(0x8F05070A),
            Color(0xF205070A),
          ],
          stops: [0, .42, .7, 1],
        ),
      ),
    );
  }
}

class _GameCardFooter extends StatelessWidget {
  const _GameCardFooter({
    required this.game,
    required this.showRecentBadge,
    required this.accent,
  });

  final GameModel game;
  final bool showRecentBadge;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showRecentBadge) ...[
          Row(
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'CONTINUE',
                style: AppTextStyles.labelSmall.copyWith(
                  color: accent,
                  fontSize: 9,
                  letterSpacing: .8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        Text(
          game.title,
          style: AppTextStyles.gameTitle.copyWith(
            color: Colors.white,
            fontSize: 15,
            height: 1.18,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: Text(
                _metadata,
                style: AppTextStyles.gameMeta.copyWith(
                  color: Colors.white.withValues(alpha: .58),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (game.rating > 0) ...[
              Icon(Icons.star_rounded, color: accent, size: 12),
              const SizedBox(width: 3),
              Text(
                game.rating.toStringAsFixed(1),
                style: AppTextStyles.gameMeta.copyWith(
                  color: Colors.white.withValues(alpha: .72),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  String get _metadata {
    final values = <String>[
      if (game.releaseYear != null) '${game.releaseYear}',
      if (game.genre != null && game.genre!.isNotEmpty) game.genre!,
    ];
    return values.isEmpty ? game.consolePlatform : values.join('  •  ');
  }
}
