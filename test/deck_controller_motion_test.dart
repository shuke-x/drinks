import 'package:drinks/stores/deck_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('deck drag is calmer and does not double-notify on ticker frames', () {
    final deck = DeckController();
    var notifications = 0;
    deck.addListener(() => notifications++);

    deck.onDragStart(0);
    deck.onDragUpdate(kDeckDragStep);
    expect(deck.pos, -1);

    final afterPointerUpdate = notifications;
    deck.tick(1 / 60);
    expect(notifications, afterPointerUpdate);

    deck.onDragEnd(-5000);
    expect(deck.vel, 3.2);
    final flingVelocity = deck.vel;
    deck.tick(.05);
    expect(deck.vel.abs(), lessThan(flingVelocity.abs()));

    deck.dispose();
  });

  test('slow release springs to a card boundary and can be interrupted', () {
    final deck = DeckController();

    deck.onDragStart(0);
    deck.onDragUpdate(-100);
    deck.onDragEnd();
    expect(deck.settling, isTrue);

    for (var frame = 0; frame < 240 && deck.settling; frame++) {
      deck.tick(1 / 60);
    }
    expect(deck.settling, isFalse);
    expect(deck.pos, 0);
    expect(deck.vel, 0);

    deck.onDragStart(0);
    deck.onDragUpdate(-150);
    deck.onDragEnd();
    expect(deck.settling, isTrue);
    deck.tick(1 / 60);
    deck.onDragStart(40);
    expect(deck.settling, isFalse);

    deck.dispose();
  });

  test('reduced motion release settles immediately', () {
    final deck = DeckController();

    deck.onDragStart(0);
    deck.onDragUpdate(-150);
    deck.onDragEnd(900, true);

    expect(deck.dragging, isFalse);
    expect(deck.settling, isFalse);
    expect(deck.pos, deck.pos.roundToDouble());
    expect(deck.vel, 0);

    deck.dispose();
  });
}
