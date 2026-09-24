import 'package:flutter/material.dart';

import '../models/cocktail.dart';
import '../stores/deck_store.dart';
import '../views/next/widgets/deck_card.dart';

/// Reusable curved card stack renderer used by recommendation and favorites.
///
/// The controller owns gesture/animation state; this widget only maps the
/// current position to the visible card slots.
class DeckCardList extends StatelessWidget {
  const DeckCardList({
    super.key,
    required this.drinks,
    required this.deck,
    required this.width,
    this.height,
    required this.onOpen,
  });

  final List<Cocktail> drinks;
  final DeckController deck;
  final double width;
  final double? height;
  final ValueChanged<Cocktail> onOpen;

  @override
  Widget build(BuildContext context) {
    if (drinks.isEmpty) return const SizedBox.expand();
    final len = drinks.length;
    final base = deck.pos.round();
    final slots = <_DeckSlot>[];
    for (var k = -2; k <= 2; k++) {
      final slot = base + k;
      final drink = drinks[((slot % len) + len) % len];
      slots.add(_DeckSlot(drink: drink, t: slot - deck.pos, key: 's$k'));
    }
    slots.sort((a, b) => b.t.abs().compareTo(a.t.abs()));
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final slot in slots)
          DeckCardTransform(
            key: ValueKey(slot.key),
            drink: slot.drink,
            t: slot.t,
            stageWidth: width,
            stageHeight: height,
            landed: deck.landedId == slot.drink.id && slot.t.abs() < .4,
            engaged: deck.dragging && slot.t.abs() < .5,
            onTap: () => onOpen(slot.drink),
          ),
      ],
    );
  }
}

class _DeckSlot {
  const _DeckSlot({required this.drink, required this.t, required this.key});

  final Cocktail drink;
  final double t;
  final String key;
}
