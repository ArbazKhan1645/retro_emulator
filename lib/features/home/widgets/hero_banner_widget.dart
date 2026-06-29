import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/game_model.dart';
import '../../../shared/widgets/console_badge_widget.dart';
import '../../../shared/widgets/game_artwork.dart';
import '../../../shared/widgets/retro_button.dart';

class HeroBannerWidget extends StatefulWidget {
  const HeroBannerWidget({
    super.key,
    required this.games,
    required this.onPlay,
    required this.onDetails,
  });

  final List<GameModel> games;
  final void Function(GameModel) onPlay;
  final void Function(GameModel) onDetails;

  @override
  State<HeroBannerWidget> createState() => _HeroBannerWidgetState();
}

class _HeroBannerWidgetState extends State<HeroBannerWidget> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _scheduleAdvance();
  }

  void _scheduleAdvance() {
    Future.delayed(const Duration(seconds: 7), () {
      if (!mounted) return;
      if (widget.games.length > 1) {
        final next = (_currentPage + 1) % widget.games.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
        );
      }
      _scheduleAdvance();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.games.isEmpty) return const SizedBox.shrink();
    final wide = MediaQuery.sizeOf(context).width >= 840;
    return SizedBox(
      height: wide ? 440 : AppConstants.heroHeight,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.games.length,
            onPageChanged: (value) => setState(() => _currentPage = value),
            itemBuilder: (context, index) {
              final game = widget.games[index];
              return _HeroPage(
                game: game,
                wide: wide,
                onPlay: () => widget.onPlay(game),
                onDetails: () => widget.onDetails(game),
              );
            },
          ),
          if (widget.games.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: wide ? 22 : 28,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.games.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: index == _currentPage ? 18 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: index == _currentPage
                          ? Theme.of(context).colorScheme.primary
                          : AppColors.textHint,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroPage extends StatelessWidget {
  const _HeroPage(
      {required this.game,
      required this.wide,
      required this.onPlay,
      required this.onDetails});

  final GameModel game;
  final bool wide;
  final VoidCallback onPlay;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        wide ? 28 : 16,
        wide ? 24 : 76,
        wide ? 28 : 16,
        48,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(wide ? 26 : 22),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              GameArtwork(
                title: game.title,
                imageUrl: game.backgroundUrl ?? game.coverUrl,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [
                      Color(0xFA05070A),
                      Color(0xB805070A),
                      Color(0x1605070A),
                    ],
                    stops: [0, .48, 1],
                  ),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final contentRight = wide ? constraints.maxWidth * .43 : 24.0;
                  return Positioned(
                    left: wide ? 40 : 24,
                    right: contentRight,
                    bottom: wide ? 36 : 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'FEATURED',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                letterSpacing: 1.5,
                                fontSize: 9,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 24,
                              height: 1,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(.65),
                            ),
                            const SizedBox(width: 10),
                            ConsoleBadge(consoleName: game.consolePlatform),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          game.title,
                          style: AppTextStyles.displayMedium.copyWith(
                            fontSize: wide ? 39 : 29,
                            height: 1.05,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 9),
                        Text(
                          _metadata,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withOpacity(.68),
                          ),
                        ),
                        if (game.description != null &&
                            game.description!.isNotEmpty) ...[
                          const SizedBox(height: 11),
                          Text(
                            game.description!,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white.withOpacity(.66),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        SizedBox(height: wide ? 26 : 20),
                        Row(
                          children: [
                            RetroPlayButton(
                              onPressed: onPlay,
                              width: wide ? 138 : 124,
                              height: 48,
                            ),
                            const SizedBox(width: 10),
                            RetroOutlineButton(
                              label: 'Details',
                              icon: Icons.arrow_outward_rounded,
                              onPressed: onDetails,
                              width: wide ? 126 : 116,
                              height: 48,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _metadata {
    final values = <String>[
      if (game.releaseYear != null) '${game.releaseYear}',
      if (game.genre != null && game.genre!.isNotEmpty) game.genre!,
      if (game.rating > 0) '★ ${game.rating.toStringAsFixed(1)}',
    ];
    return values.join('  •  ');
  }
}
