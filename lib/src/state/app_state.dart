import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/store.dart';
import '../logic/clarity_logic.dart';
import '../models/app_data.dart';
import '../services/gateways.dart';
import '../services/photos.dart';

class AppState extends ChangeNotifier {
  AppState(
    this.store,
    this.purchases,
    this.crews, {
    DateTime Function()? clock,
    int Function(int max)? nextInt,
  }) : _clock = clock ?? DateTime.now,
       _nextInt = nextInt ?? Random().nextInt;

  final ClarityStore store;
  final PurchaseGateway purchases;
  final CrewGateway crews;
  final DateTime Function() _clock;
  final int Function(int max) _nextInt;

  AppData data = AppData.fresh(0);
  final images = <String, Uint8List>{};
  int _seq = 0;

  DateTime get now => _clock();

  String _id(String prefix) {
    _seq += 1;
    return '$prefix-${now.microsecondsSinceEpoch.toRadixString(36)}-$_seq';
  }

  Future<void> load() async {
    data = await store.load() ?? AppData.fresh(now.millisecondsSinceEpoch);
    _reconcile();
    await _hydrateImages();
    await store.save(data);
    notifyListeners();
  }

  Future<void> _persist() async {
    await store.save(data);
    notifyListeners();
  }

  void _reconcile() {
    final moment = now;
    final life = LifeClock.reconcile(
      data.profile.lives,
      data.profile.livesAnchorMs,
      moment.millisecondsSinceEpoch,
    );
    data.profile.lives = life.lives;
    data.profile.livesAnchorMs = life.anchor;
    final gaps = FreezePlan.coverGaps(
      today: moment,
      created: DateTime.fromMillisecondsSinceEpoch(data.profile.createdMs),
      freezes: data.profile.freezes,
      counts: (day) => _counts(day),
    );
    for (final day in gaps) {
      data.profile.freezes -= 1;
      final key = Day.key(day);
      if (!data.profile.frozenDays.contains(key)) {
        data.profile.frozenDays.add(key);
      }
    }
    final frozen = data.profile.frozenDays.toSet();
    for (final habit in data.habits) {
      final streak = habitStreak(
        weekdays: habit.weekdays,
        checkIns: habit.checkIns.toSet(),
        frozen: frozen,
        today: moment,
      );
      if (streak > habit.bestStreak) habit.bestStreak = streak;
    }
  }

  bool _counts(DateTime day) {
    final key = Day.key(day);
    if (data.profile.mindDays.contains(key)) return true;
    if (data.profile.frozenDays.contains(key)) return true;
    return data.habits.any((h) => h.checkIns.contains(key));
  }

  Set<String> get _frozen => data.profile.frozenDays.toSet();

  int streakFor(Habit habit) => habitStreak(
    weekdays: habit.weekdays,
    checkIns: habit.checkIns.toSet(),
    frozen: _frozen,
    today: now,
  );

  int get mindStreakCount => chainStreak(
    today: now,
    doneToday: data.profile.mindDays.contains(Day.key(now)),
    counts: (day) {
      final key = Day.key(day);
      return data.profile.mindDays.contains(key) ||
          data.profile.frozenDays.contains(key);
    },
  );

  int get accountStreak => chainStreak(
    today: now,
    doneToday: _counts(now),
    counts: _counts,
  );

  int get level => XpRules.levelFor(data.profile.xp);

  int get xpInto => XpRules.xpIntoLevel(data.profile.xp);

  int get xpNeed => XpRules.xpToAdvance(level);

  String get title => XpRules.titleFor(level);

  bool dueToday(Habit habit) => habitDue(habit.weekdays, now);

  bool checkedToday(Habit habit) => habit.checkIns.contains(Day.key(now));

  int starsFor(String gameId, int level) => data.stars['$gameId:$level'] ?? 0;

  bool levelUnlocked(String gameId, int levelNumber) =>
      levelNumber <= 1 || starsFor(gameId, levelNumber - 1) > 0;

  int get featuredDaily => featuredDailyLevel(
    streak: mindStreakCount,
    doneToday: data.profile.mindDays.contains(Day.key(now)),
    unlocked: (level) => levelUnlocked('daily', level),
  );

  bool get dailyDoneToday => data.profile.mindDays.contains(Day.key(now));

  int boosterCount(String id) => data.boosters[id] ?? 0;

  bool owns(String id) => data.owned.contains(id);

  Future<void> _hydrateImages() async {
    final ids = <String>{
      for (final selfie in data.selfies) selfie.imageId,
      for (final entry in data.tower)
        if (entry.imageId != null) entry.imageId!,
    };
    for (final id in ids) {
      final bytes = await store.loadImage(id);
      if (bytes != null && bytes.isNotEmpty) images[id] = bytes;
    }
  }

  void _note(String type, String summary) {
    data.crewNotes.insert(
      0,
      CrewNote(type: type, summary: summary, createdMs: now.millisecondsSinceEpoch),
    );
    if (data.crewNotes.length > 30) {
      data.crewNotes.removeRange(30, data.crewNotes.length);
    }
    crews.sync(data.crewNotes);
  }

  void _grantXp(int xp, String reason) {
    if (xp <= 0) return;
    data.profile.xp += xp;
    data.xpLog.insert(
      0,
      XpEvent(xp: xp, reason: reason, createdMs: now.millisecondsSinceEpoch),
    );
    if (data.xpLog.length > 40) data.xpLog.removeLast();
  }

  Map<String, Set<int>> _ownedPieces() => {
    for (final entry in data.pieces.entries) entry.key: entry.value.toSet(),
  };

  DropOutcome _roll() => rollDrop(
    rarityRoll: _nextInt(100),
    pictureRoll: _nextInt(6),
    pieceRoll: _nextInt(16),
    owned: _ownedPieces(),
  );

  bool _applyDrop(DropOutcome drop) {
    if (drop.duplicate) {
      data.profile.clarity += drop.clarityAwarded;
      return false;
    }
    final list = data.pieces.putIfAbsent(drop.picture.id, () => <int>[]);
    if (!list.contains(drop.pieceIndex)) list.add(drop.pieceIndex);
    final finished = list.length >= drop.picture.pieceCount;
    final already = data.tower.any((t) => t.pictureId == drop.picture.id);
    if (finished && !already) {
      data.tower.add(
        TowerEntry(
          id: _id('floor'),
          kind: 'picture',
          caption: drop.picture.title,
          createdMs: now.millisecondsSinceEpoch,
          pictureId: drop.picture.id,
        ),
      );
      return true;
    }
    return false;
  }

  void finishOnboarding({
    required String name,
    required String habitName,
    required String glyph,
  }) {
    final trimmed = name.trim();
    data.profile.name = trimmed.isEmpty ? 'Traveler' : trimmed;
    data.profile.onboarded = true;
    addHabit(habitName.trim().isEmpty ? 'Drink water' : habitName.trim(), glyph, const []);
  }

  void addHabit(String name, String glyph, List<int> weekdays) {
    data.habits.add(
      Habit(
        id: _id('habit'),
        name: name,
        glyph: glyph,
        weekdays: [...weekdays]..sort(),
      ),
    );
    _persist();
  }

  void updateHabit(String id, String name, String glyph, List<int> weekdays) {
    final habit = data.habits.where((h) => h.id == id).firstOrNull;
    if (habit == null) return;
    habit.name = name.trim().isEmpty ? habit.name : name.trim();
    habit.glyph = glyph;
    habit.weekdays = [...weekdays]..sort();
    _persist();
  }

  void deleteHabit(String id) {
    data.habits.removeWhere((h) => h.id == id);
    for (final routine in data.routines) {
      for (final step in routine.steps) {
        if (step.habitId == id) step.habitId = null;
      }
    }
    _persist();
  }

  /// Returns a message when the check-in cannot be recorded.
  String? checkIn(String habitId) {
    final habit = data.habits.where((h) => h.id == habitId).firstOrNull;
    if (habit == null) return 'That habit is gone.';
    if (!dueToday(habit)) return 'Not scheduled today.';
    final key = Day.key(now);
    if (habit.checkIns.contains(key)) return 'Already checked in today.';
    habit.checkIns.add(key);
    final streak = streakFor(habit);
    if (streak > habit.bestStreak) habit.bestStreak = streak;
    final xp = XpRules.checkInXp(streak);
    final before = level;
    _grantXp(xp, 'Checked in: ${habit.name}');
    data.profile.clarity += XpRules.checkInClarity;
    _note('check_in', '${habit.name} · day $key');
    _persist();
    return level > before ? 'level:${XpRules.titleFor(level)}' : null;
  }

  void addStep(String slot, String label, {String? habitId}) {
    final routine = data.routines.where((r) => r.slot == slot).firstOrNull;
    if (routine == null) return;
    routine.steps.add(
      RoutineStep(id: _id('step'), label: label, habitId: habitId),
    );
    _persist();
  }

  void removeStep(String slot, String stepId) {
    final routine = data.routines.where((r) => r.slot == slot).firstOrNull;
    routine?.steps.removeWhere((s) => s.id == stepId);
    _persist();
  }

  void moveStep(String slot, int index, int delta) {
    final routine = data.routines.where((r) => r.slot == slot).firstOrNull;
    if (routine == null) return;
    final next = index + delta;
    if (next < 0 || next >= routine.steps.length) return;
    final step = routine.steps.removeAt(index);
    routine.steps.insert(next, step);
    _persist();
  }

  void setFocusLengths(int work, int rest) {
    data.profile.focusWorkMinutes = work.clamp(5, 90);
    data.profile.focusBreakMinutes = rest.clamp(1, 30);
    _persist();
  }

  int completeFocus(int minutes) {
    final xp = XpRules.focusXp(minutes);
    final before = level;
    _grantXp(xp, 'Focus timer, $minutes min');
    data.profile.clarity += XpRules.focusClarity(minutes);
    data.sessions.insert(
      0,
      FocusSession(
        id: _id('focus'),
        minutes: minutes,
        xp: xp,
        createdMs: now.millisecondsSinceEpoch,
      ),
    );
    if (data.sessions.length > 30) data.sessions.removeLast();
    _note('focus', '$minutes minute focus');
    _persist();
    return level - before;
  }

  String? buyNextCastlePiece() {
    if (data.profile.castlePieces >= SandcastlePlan.pieceCount) {
      return 'The castle is already finished.';
    }
    final cost = SandcastlePlan.cost(data.profile.castlePieces);
    if (data.profile.clarity < cost) {
      return 'You need $cost Clarity for the next piece.';
    }
    data.profile.clarity -= cost;
    data.profile.castlePieces += 1;
    _persist();
    return null;
  }

  Future<void> saveSelfie(Uint8List bytes) async {
    final id = _id('selfie');
    final jpeg = shrinkJpeg(bytes, maxSide: 1200);
    images[id] = jpeg;
    await store.saveImage(id, jpeg);
    data.selfies.insert(
      0,
      CastleSelfie(id: id, imageId: id, createdMs: now.millisecondsSinceEpoch),
    );
    data.profile.castlesFinished += 1;
    _note('castle', 'Sandcastle selfie saved');
    await _persist();
  }

  void washCastle() {
    data.profile.castlePieces = 0;
    _persist();
  }

  Future<String?> addMemory(Uint8List bytes, String caption) async {
    try {
      final id = _id('memory');
      final jpeg = shrinkJpeg(bytes);
      images[id] = jpeg;
      await store.saveImage(id, jpeg);
      data.tower.add(
        TowerEntry(
          id: id,
          kind: 'photo',
          caption: caption.trim(),
          createdMs: now.millisecondsSinceEpoch,
          imageId: id,
        ),
      );
      _note('tower', caption.trim().isEmpty ? 'A new memory' : caption.trim());
      await _persist();
      return null;
    } catch (_) {
      return 'That photo could not be saved on this device.';
    }
  }

  void removeMemory(String id) {
    data.tower.removeWhere((t) => t.id == id && t.kind == 'photo');
    _persist();
  }

  bool spendBooster(String id) {
    final count = data.boosters[id] ?? 0;
    if (count <= 0) return false;
    data.boosters[id] = count - 1;
    _persist();
    return true;
  }

  void reconcileLives() {
    final life = LifeClock.reconcile(
      data.profile.lives,
      data.profile.livesAnchorMs,
      now.millisecondsSinceEpoch,
    );
    if (life.lives == data.profile.lives &&
        life.anchor == data.profile.livesAnchorMs) {
      return;
    }
    data.profile.lives = life.lives;
    data.profile.livesAnchorMs = life.anchor;
    _persist();
  }

  int get msUntilNextLife => LifeClock.msUntilNext(
    data.profile.lives,
    data.profile.livesAnchorMs,
    now.millisecondsSinceEpoch,
  );

  void failArcade(String gameId) {
    if (!usesLives(gameId)) return;
    if (data.profile.lives >= LifeClock.maxLives) {
      data.profile.livesAnchorMs = now.millisecondsSinceEpoch;
    }
    if (data.profile.lives > 0) data.profile.lives -= 1;
    _persist();
  }

  Reward settleWin({
    required String gameId,
    required int levelNumber,
    required int stars,
  }) {
    final safeStars = stars.clamp(0, 3);
    final starKey = '$gameId:$levelNumber';
    final previous = data.stars[starKey] ?? 0;
    final first = previous == 0;
    if (safeStars > previous) data.stars[starKey] = safeStars;
    final before = level;
    var xp = XpRules.gameXp(safeStars, firstClear: first);
    var clarity = XpRules.gameClarity(safeStars);
    if (gameId == 'daily') {
      final key = Day.key(now);
      final already = data.profile.mindDays.contains(key);
      if (!already) data.profile.mindDays.add(key);
      if (!already) {
        final streak = mindStreakCount;
        xp = XpRules.dailyXp + XpRules.streakBonus(streak);
        clarity = XpRules.dailyClarity;
      }
    } else if (gameId == 'tidebreath') {
      xp = first ? XpRules.breathXp : max(2, (XpRules.breathXp * 0.4).round());
      clarity = XpRules.breathClarity;
    }
    _grantXp(xp, _winReason(gameId, levelNumber, safeStars));
    data.profile.clarity += clarity;
    final drop = _roll();
    final album = _applyDrop(drop);
    _note('game', '${gameName(gameId)} level $levelNumber · $safeStars stars');
    _persist();
    return Reward(
      xp: xp,
      clarity: clarity,
      levelsGained: level - before,
      newLevel: level,
      title: title,
      drop: drop,
      stars: safeStars,
      albumCompleted: album,
    );
  }

  String? buyWithPoints(String itemId) {
    final item = shopItemById(itemId);
    if (item == null) return 'Unknown item.';
    if (item.realMoney) {
      return 'That item is reserved for real-money purchase later.';
    }
    if (!item.repeatable && owns(item.id)) return 'You already own this.';
    if (item.category == 'freeze' && data.profile.freezes >= 5) {
      return 'You can hold 5 streak freezes.';
    }
    if (item.category == 'life' && data.profile.lives >= LifeClock.maxLives) {
      return 'Lives are already full.';
    }
    if (data.profile.clarity < item.cost) {
      return 'You need ${item.cost} Clarity.';
    }
    data.profile.clarity -= item.cost;
    switch (item.category) {
      case 'freeze':
        data.profile.freezes += 1;
      case 'life':
        data.profile.lives += 1;
        if (data.profile.lives >= LifeClock.maxLives) {
          data.profile.livesAnchorMs = now.millisecondsSinceEpoch;
        }
      case 'booster':
        data.boosters[item.id] = (data.boosters[item.id] ?? 0) + 1;
      default:
        if (!data.owned.contains(item.id)) data.owned.add(item.id);
        equip(item.id);
    }
    _persist();
    return null;
  }

  Future<PurchaseResult> startRealMoney(String sku) =>
      purchases.buyWithRealMoney(sku);

  void equip(String itemId) {
    final item = shopItemById(itemId);
    if (item == null || !owns(item.id)) return;
    switch (item.category) {
      case 'avatar':
        data.profile.avatarId = item.id;
      case 'theme':
        data.profile.themeId = item.id;
      case 'card':
        data.profile.cardBackId = item.id;
      case 'board':
        data.profile.boardId = item.id;
      default:
        return;
    }
    _persist();
  }

  void setName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    data.profile.name = trimmed;
    _persist();
  }

  void setReminder({required bool enabled, required String time}) {
    data.profile.remindHabits = enabled;
    data.profile.reminderTime = time;
    _persist();
  }

  Map<String, Object?> exportJson() => data.toJson();
}

String gameName(String id) => switch (id) {
  'pairwell' => 'Pairwell',
  'beacon' => 'Beacon Relay',
  'lattice' => 'Rune Lattice',
  'glance' => 'Twice Lit',
  'lexicon' => 'Wordwell',
  'digits' => 'Digit Drift',
  'oddling' => 'Oddling',
  'inkwise' => 'Inkwise',
  'waymark' => 'Waymark',
  'daily' => 'Daily Riddle',
  'tidebreath' => 'Tide Breath',
  _ => 'Challenge',
};

String gameBlurb(String id) => switch (id) {
  'pairwell' => 'Flip cards and match the pairs.',
  'beacon' => 'Watch the beacons, then tap them back in order.',
  'lattice' => 'A pattern flashes. Tap every lit rune.',
  'glance' => 'Two scenes. Find what the tide changed.',
  'lexicon' => 'Study the words, then type the ones you remember.',
  'digits' => 'Hold a growing string of digits, then type it back.',
  'oddling' => 'Find the one tile that does not belong.',
  'inkwise' => 'Tap the ink color, not the word.',
  'waymark' => 'A route lights up. Walk it again.',
  'daily' => 'One mixed puzzle for today. It counts toward your streak.',
  'tidebreath' => 'A one-minute guided breath before or after focus.',
  _ => '',
};

String _winReason(String gameId, int level, int stars) =>
    '${gameName(gameId)} level $level · $stars stars';
