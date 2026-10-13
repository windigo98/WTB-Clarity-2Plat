import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wtb_clarity/src/data/store.dart';
import 'package:wtb_clarity/src/logic/clarity_logic.dart';
import 'package:wtb_clarity/src/models/app_data.dart';
import 'package:wtb_clarity/src/services/gateways.dart';
import 'package:wtb_clarity/src/state/app_state.dart';

void main() {
  test('levels rise on the published curve', () {
    expect(XpRules.levelFor(0), 1);
    expect(XpRules.levelFor(39), 1);
    expect(XpRules.levelFor(40), 2);
    expect(XpRules.xpIntoLevel(40), 0);
    expect(XpRules.titleFor(1), 'Tide Scout');
  });

  test('a freeze covers one missed day and keeps the habit streak', () {
    final today = DateTime(2026, 10, 13);
    final created = DateTime(2026, 10, 10);
    final gaps = FreezePlan.coverGaps(
      today: today,
      created: created,
      freezes: 1,
      counts: (day) => Day.key(day) == '2026-10-11',
    );
    expect(gaps.map(Day.key).toList(), ['2026-10-12']);
    final streak = habitStreak(
      weekdays: const [],
      checkIns: {'2026-10-11', '2026-10-10'},
      frozen: {'2026-10-12'},
      today: today,
    );
    expect(streak, 3);
  });

  test('rarity rolls are weighted and duplicates pay Clarity', () {
    expect(rarityFromRoll(0), Rarity.common);
    expect(rarityFromRoll(46), Rarity.uncommon);
    expect(rarityFromRoll(71), Rarity.rare);
    expect(rarityFromRoll(86), Rarity.epic);
    expect(rarityFromRoll(94), Rarity.legendary);
    expect(rarityFromRoll(98), Rarity.mythic);
    final picture = pictures.first;
    final owned = {
      picture.id: {for (var i = 0; i < picture.pieceCount; i++) i},
    };
    final drop = rollDrop(rarityRoll: 0, pictureRoll: 0, pieceRoll: 2, owned: owned);
    expect(drop.duplicate, isTrue);
    expect(drop.clarityAwarded, duplicateClarity(Rarity.common));
    final fresh = rollDrop(rarityRoll: 0, pictureRoll: 0, pieceRoll: 2, owned: const {});
    expect(fresh.duplicate, isFalse);
    expect(fresh.pieceIndex, 2);
  });

  test('word recall and pairwell stars', () {
    expect(recallHits(['tideglass', 'anchor'], 'Anchor, tideglass'), 2);
    expect(recallStars(2, 2), 3);
    expect(recallStars(1, 3), 0);
    expect(pairwellStars(pairs: 4, moves: 4, cleared: true), 3);
    expect(pairwellStars(pairs: 4, moves: 9, cleared: true), 1);
    expect(pairwellStars(pairs: 4, moves: 4, cleared: false), 0);
  });

  test('daily kind is stable for a date and lives refill', () {
    final day = DateTime(2026, 10, 13);
    expect(dailyKind(day), dailyKind(day));
    expect(const ['oddling', 'digits', 'lexicon', 'waymark'], contains(dailyKind(day)));
    final filled = LifeClock.reconcile(3, 1000, 1000 + 30 * 60 * 1000);
    expect(filled.lives, 4);
    expect(makePath(grid: 3, length: 4, seed: 2), hasLength(4));
  });

  test('shop refuses a purchase you cannot afford and blocks real money', () async {
    final now = DateTime(2026, 10, 13, 9);
    final store = MemoryStore();
    final state = AppState(
      store,
      const PurchaseGateway(),
      const CrewGateway(),
      clock: () => now,
      nextInt: (max) => 0,
    );
    await state.load();
    state.data.profile.onboarded = true;
    state.data.profile.clarity = 10;
    expect(state.buyWithPoints('avatar_emberfox'), isNotNull);
    expect(state.owns('avatar_emberfox'), isFalse);
    state.data.profile.clarity = 80;
    expect(state.buyWithPoints('avatar_emberfox'), isNull);
    expect(state.data.profile.avatarId, 'avatar_emberfox');
    expect(state.buyWithPoints('pouch_small'), contains('real-money'));
    final money = await state.startRealMoney('clarity_pouch_80');
    expect(money.ok, isFalse);
    expect(money.channel, 'real_money');
  });

  test('check-in grants XP and a game win drops a piece', () async {
    final now = DateTime(2026, 10, 13, 9);
    final state = AppState(
      MemoryStore(),
      const PurchaseGateway(),
      const CrewGateway(),
      clock: () => now,
      nextInt: (max) => 0,
    );
    await state.load();
    state.finishOnboarding(name: 'Ada', habitName: 'Drink water', glyph: '💧');
    final habit = state.data.habits.single;
    expect(state.checkIn(habit.id), isNull);
    expect(state.data.profile.xp, XpRules.checkInXp(1));
    expect(state.accountStreak, 1);
    final reward = state.settleWin(gameId: 'pairwell', levelNumber: 1, stars: 3);
    expect(reward.drop.duplicate, isFalse);
    expect(state.data.pieces[reward.drop.picture.id], contains(reward.drop.pieceIndex));
    expect(state.starsFor('pairwell', 1), 3);
    final again = AppData.fromJson(jsonDecode(jsonEncode(state.exportJson())) as Map<String, dynamic>);
    expect(again.habits.single.name, 'Drink water');
    expect(again.profile.xp, state.data.profile.xp);
  });

  test('sandcastle pieces spend Clarity in order', () async {
    final state = AppState(
      MemoryStore(),
      const PurchaseGateway(),
      const CrewGateway(),
      clock: () => DateTime(2026, 10, 13),
    );
    await state.load();
    state.data.profile.clarity = SandcastlePlan.cost(0);
    expect(state.buyNextCastlePiece(), isNull);
    expect(state.data.profile.castlePieces, 1);
    expect(state.data.profile.clarity, 0);
    expect(state.buyNextCastlePiece(), isNotNull);
    state.washCastle();
    expect(state.data.profile.castlePieces, 0);
  });

  test('a missed day consumes a stored freeze on load', () async {
    final store = MemoryStore();
    final created = DateTime(2026, 10, 11, 8);
    final first = AppState(
      store,
      const PurchaseGateway(),
      const CrewGateway(),
      clock: () => created,
    );
    await first.load();
    first.finishOnboarding(name: 'Ada', habitName: 'Read', glyph: '📖');
    first.checkIn(first.data.habits.single.id);
    first.data.profile.freezes = 1;
    await store.save(first.data);

    final later = AppState(
      store,
      const PurchaseGateway(),
      const CrewGateway(),
      clock: () => DateTime(2026, 10, 13, 8),
    );
    await later.load();
    expect(later.data.profile.frozenDays, contains('2026-10-12'));
    expect(later.data.profile.freezes, 0);
    expect(later.streakFor(later.data.habits.single), greaterThan(0));
  });
}
