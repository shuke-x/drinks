import 'package:drinks/models/cocktail.dart';
import 'package:drinks/stores/deck_store.dart';
import 'package:flutter_test/flutter_test.dart';

Cocktail _drink({
  String zh = '古典',
  String en = 'Old Fashioned',
  List<String> tags = const ['烈酒感', '偏苦甜', '烈酒感'],
}) {
  return Cocktail(
    id: 'old-fashioned',
    zh: zh,
    en: en,
    base: '威士忌',
    abv: 32,
    color: '#B06C35',
    tags: tags,
    glass: '',
    garnish: '',
    flavor: '',
    story: '',
    recipe: const [],
    steps: const [],
  );
}

void main() {
  group('cocktail presentation', () {
    test('uses English as the primary title in the English locale', () {
      final drink = _drink();

      expect(drink.nameFor('en'), 'Old Fashioned');
      expect(drink.alternateNameFor('en'), '古典');
      expect(drink.nameFor('zh'), '古典');
      expect(drink.alternateNameFor('zh'), 'Old Fashioned');
    });

    test('falls back safely when imported English name is empty', () {
      final drink = _drink(en: '');

      expect(drink.nameFor('en'), '古典');
      expect(drink.alternateNameFor('en'), isNull);
    });

    test('builds one to three unique card tips', () {
      expect(_drink().cardTips, ['威士忌', '烈酒感', '偏苦甜']);
      expect(_drink(tags: const []).cardTips, ['威士忌']);
    });
  });

  test('deck drag follows the pointer with capped release velocity', () {
    final deck = DeckController();

    deck.onDragStart(kDeckDragStep);
    deck.onDragUpdate(0);
    expect(deck.pos, closeTo(1, .001));

    deck.onDragEnd(-5000);
    expect(deck.vel, closeTo(3.2, .001));

    deck.tick(.05);
    expect(deck.pos, greaterThan(1.1));
    expect(deck.vel, lessThan(3.2));

    deck.dispose();
  });
}
