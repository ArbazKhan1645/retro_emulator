import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/game_model.dart';
import '../../../shared/widgets/game_card_widget.dart';
import '../../../shared/widgets/shimmer_card.dart';

/// A horizontal scrolling row of game cards.
///
/// Shows a shimmer skeleton while [isLoading] is true,
/// an empty-state message when [games] is empty,
/// and a scrollable list of [GameCardWidget] tiles otherwise.
class GameRowWidget extends StatelessWidget {
  const GameRowWidget({
    super.key,
    required this.games,
    required this.onGameTap,
    required this.onFavoriteTap,
    this.isLoading = false,
    this.showRecentBadge = false,
    this.cardWidth,
    this.cardHeight,
  });

  /// The list of games to display.
  final List<GameModel> games;

  /// Called when the user taps a game card.
  final void Function(GameModel) onGameTap;

  /// Called when the user taps the favourite toggle on a card.
  final void Function(GameModel) onFavoriteTap;

  /// When true, shimmer skeleton cards are displayed instead of real content.
  final bool isLoading;

  /// When true, a "Recently Played" badge is overlaid on each card.
  final bool showRecentBadge;

  /// Optional override for card width.
  final double? cardWidth;

  /// Optional override for card height. Also controls the row height.
  final double? cardHeight;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const ShimmerRow(count: 5);
    if (games.isEmpty) return const _EmptyRow();
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final resolvedWidth = cardWidth ?? (wide ? 184.0 : AppConstants.cardWidth);
    final resolvedHeight =
        cardHeight ?? (wide ? 264.0 : AppConstants.cardHeight);
    final horizontalPadding = wide ? 28.0 : 20.0;

    return SizedBox(
      height: resolvedHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        physics: const BouncingScrollPhysics(),
        itemCount: games.length,
        itemBuilder: (context, index) {
          final game = games[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GameCardWidget(
              game: game,
              onTap: () => onGameTap(game),
              onFavoriteTap: () => onFavoriteTap(game),
              width: resolvedWidth,
              height: resolvedHeight,
              showRecentBadge: showRecentBadge,
              animationDelay: Duration(milliseconds: index * 60),
            ),
          );
        },
      ),
    );
  }
}

/// Shown when the games list is empty.
class _EmptyRow extends StatelessWidget {
  const _EmptyRow();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 60,
      child: Center(
        child: Text(
          'No games yet. Add ROMs to get started!',
          style: TextStyle(
            color: Color(0xFF6B6B8A),
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
