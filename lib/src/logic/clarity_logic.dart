import 'dart:math';

enum Rarity { common, uncommon, rare, epic, legendary, mythic }

class PictureDef {
  const PictureDef({
    required this.id,
    required this.title,
    required this.blurb,
    required this.rarity,
    required this.cols,
    required this.rows,
    required this.asset,
  });

  final String id;
  final String title;
  final String blurb;
  final Rarity rarity;
  final int cols;
  final int rows;
  final String asset;

  int get pieceCount => cols * rows;
}

const pictures = <PictureDef>[
  PictureDef(
    id: 'hatchling_cove',
    title: 'Hatchling Cove',
    blurb: 'A small teal dragon warms itself beside a tide-pool lantern.',
    rarity: Rarity.common,
    cols: 3,
    rows: 3,
    asset: 'assets/pictures/hatchling_cove.jpg',
  ),
  PictureDef(
    id: 'glass_tide',
    title: 'Glass Tide',
    blurb: 'A kelp-caped knight meets a pearl-scaled sea dragon at moonrise.',
    rarity: Rarity.uncommon,
    cols: 3,
    rows: 3,
    asset: 'assets/pictures/glass_tide.jpg',
  ),
  PictureDef(
    id: 'spellstorm',
    title: 'Spellstorm Duel',
    blurb: 'An amber-staff wizard faces a crimson dragon above the cliffs.',
    rarity: Rarity.rare,
    cols: 4,
    rows: 3,
    asset: 'assets/pictures/spellstorm.jpg',
  ),
  PictureDef(
    id: 'skykeeps',
    title: 'Skykeeps',
    blurb: 'Floating castles linked by ribbon bridges over a sunset sea of cloud.',
    rarity: Rarity.epic,
    cols: 4,
    rows: 4,
    asset: 'assets/pictures/skykeeps.jpg',
  ),
  PictureDef(
    id: 'astral_harbor',
    title: 'Astral Harbor',
    blurb: 'Glass ships dock at a crescent pier under twin moons.',
    rarity: Rarity.legendary,
    cols: 4,
    rows: 4,
    asset: 'assets/pictures/astral_harbor.jpg',
  ),
  PictureDef(
    id: 'two_suns',
    title: 'Crown of Two Suns',
    blurb: 'A cosmic dragon and a wizard braid starlight around two suns.',
    rarity: Rarity.mythic,
    cols: 4,
    rows: 4,
    asset: 'assets/pictures/two_suns.jpg',
  ),
];

PictureDef pictureById(String id) =>
    pictures.firstWhere((p) => p.id == id, orElse: () => pictures.first);

const rarityWeights = <Rarity, int>{
  Rarity.common: 46,
  Rarity.uncommon: 25,
  Rarity.rare: 15,
  Rarity.epic: 8,
  Rarity.legendary: 4,
  Rarity.mythic: 2,
};

int duplicateClarity(Rarity rarity) => switch (rarity) {
  Rarity.common => 5,
  Rarity.uncommon => 12,
  Rarity.rare => 25,
  Rarity.epic => 50,
  Rarity.legendary => 100,
  Rarity.mythic => 200,
};

String rarityName(Rarity rarity) => switch (rarity) {
  Rarity.common => 'Common',
  Rarity.uncommon => 'Uncommon',
  Rarity.rare => 'Rare',
  Rarity.epic => 'Epic',
  Rarity.legendary => 'Legendary',
  Rarity.mythic => 'Mythic',
};

class DropOutcome {
  const DropOutcome({
    required this.picture,
    required this.pieceIndex,
    required this.duplicate,
    required this.clarityAwarded,
  });

  final PictureDef picture;
  final int pieceIndex;
  final bool duplicate;
  final int clarityAwarded;

  Rarity get rarity => picture.rarity;
}

Rarity rarityFromRoll(int roll0to99) {
  var cursor = 0;
  for (final entry in rarityWeights.entries) {
    cursor += entry.value;
    if (roll0to99 < cursor) return entry.key;
  }
  return Rarity.mythic;
}

DropOutcome rollDrop({
  required int rarityRoll,
  required int pictureRoll,
  required int pieceRoll,
  required Map<String, Set<int>> owned,
}) {
  final rarity = rarityFromRoll(rarityRoll.clamp(0, 99));
  final pool = pictures.where((p) => p.rarity == rarity).toList();
  final picture = pool[pictureRoll.abs() % pool.length];
  final piece = pieceRoll.abs() % picture.pieceCount;
  final have = owned[picture.id] ?? const <int>{};
  final duplicate = have.contains(piece);
  return DropOutcome(
    picture: picture,
    pieceIndex: piece,
    duplicate: duplicate,
    clarityAwarded: duplicate ? duplicateClarity(rarity) : 0,
  );
}

class Day {
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static String key(DateTime d) {
    final day = dateOnly(d);
    final m = day.month.toString().padLeft(2, '0');
    final dd = day.day.toString().padLeft(2, '0');
    return '${day.year}-$m-$dd';
  }
}

class XpRules {
  static int xpToAdvance(int level) => 40 + (level - 1) * 25;

  static int levelFor(int xp) {
    var level = 1;
    var left = xp;
    while (left >= xpToAdvance(level)) {
      left -= xpToAdvance(level);
      level += 1;
    }
    return level;
  }

  static int xpIntoLevel(int xp) {
    var level = 1;
    var left = xp;
    while (left >= xpToAdvance(level)) {
      left -= xpToAdvance(level);
      level += 1;
    }
    return left;
  }

  static int streakBonus(int streak) => min(max(streak, 0), 10) * 2;

  static int checkInXp(int streakAfter) => 10 + streakBonus(streakAfter);

  static const checkInClarity = 2;

  static int focusXp(int minutes) => max(1, minutes);

  static int focusClarity(int minutes) => 3 + minutes ~/ 10;

  static int gameXp(int stars, {required bool firstClear}) {
    const table = [0, 8, 14, 22];
    final base = table[stars.clamp(0, 3)];
    if (firstClear) return base;
    return (base * 0.4).round();
  }

  static int gameClarity(int stars) => const [0, 4, 6, 8][stars.clamp(0, 3)];

  static const dailyXp = 20;
  static const dailyClarity = 6;
  static const breathXp = 6;
  static const breathClarity = 2;

  static const titles = [
    'Tide Scout',
    'Spark Runner',
    'Lantern Hand',
    'Dune Walker',
    'Keep Apprentice',
    'Banner Mate',
    'Shellwright',
    'Quay Captain',
    'Starwright',
    'Mythic Mariner',
  ];

  static String titleFor(int level) =>
      titles[min(max(level, 1) - 1, titles.length - 1)];
}

bool habitDue(List<int> weekdays, DateTime day) {
  if (weekdays.isEmpty) return true;
  return weekdays.contains(day.weekday);
}

int habitStreak({
  required List<int> weekdays,
  required Set<String> checkIns,
  required Set<String> frozen,
  required DateTime today,
}) {
  var streak = 0;
  var cursor = Day.dateOnly(today);
  if (habitDue(weekdays, cursor) && !checkIns.contains(Day.key(cursor))) {
    cursor = cursor.subtract(const Duration(days: 1));
  }
  for (var i = 0; i < 500; i++) {
    if (habitDue(weekdays, cursor)) {
      final key = Day.key(cursor);
      if (checkIns.contains(key) || frozen.contains(key)) {
        streak += 1;
      } else {
        break;
      }
    }
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

int chainStreak({
  required DateTime today,
  required bool doneToday,
  required bool Function(DateTime day) counts,
}) {
  var streak = 0;
  var cursor = Day.dateOnly(today);
  if (!doneToday) cursor = cursor.subtract(const Duration(days: 1));
  for (var i = 0; i < 500; i++) {
    if (counts(cursor)) {
      streak += 1;
    } else {
      break;
    }
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

class FreezePlan {
  static List<DateTime> coverGaps({
    required DateTime today,
    required DateTime created,
    required int freezes,
    required bool Function(DateTime day) counts,
  }) {
    final covered = <DateTime>[];
    var left = freezes;
    var cursor = Day.dateOnly(today).subtract(const Duration(days: 1));
    final first = Day.dateOnly(created);
    for (var i = 0; i < 21 && left > 0; i++) {
      if (cursor.isBefore(first)) break;
      if (counts(cursor)) break;
      covered.add(cursor);
      left -= 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return covered;
  }
}

class LifeClock {
  static const maxLives = 5;
  static const refillMs = 30 * 60 * 1000;

  static ({int lives, int anchor}) reconcile(
    int lives,
    int anchorMs,
    int nowMs,
  ) {
    if (lives >= maxLives) return (lives: maxLives, anchor: nowMs);
    final anchor = anchorMs <= 0 ? nowMs : anchorMs;
    final gained = (nowMs - anchor) ~/ refillMs;
    if (gained <= 0) return (lives: lives, anchor: anchor);
    final newLives = min(maxLives, lives + gained);
    final newAnchor = newLives >= maxLives
        ? nowMs
        : anchor + gained * refillMs;
    return (lives: newLives, anchor: newAnchor);
  }

  static int msUntilNext(int lives, int anchorMs, int nowMs) {
    if (lives >= maxLives) return 0;
    final anchor = anchorMs <= 0 ? nowMs : anchorMs;
    final elapsed = max(0, nowMs - anchor);
    return refillMs - (elapsed % refillMs);
  }
}

class SandcastlePlan {
  static const pieceCount = 12;

  static const names = [
    'Base mound',
    'Left tower',
    'Right tower',
    'Curtain wall',
    'Gate',
    'West flag',
    'East flag',
    'Moat',
    'Shell garden',
    'Center keep',
    'High banner',
    'Starfish walk',
  ];

  static int cost(int index) => 12 + index * 6;

  static int totalCost() {
    var sum = 0;
    for (var i = 0; i < pieceCount; i++) {
      sum += cost(i);
    }
    return sum;
  }
}

class ShopItem {
  const ShopItem({
    required this.id,
    required this.name,
    required this.blurb,
    required this.category,
    required this.cost,
    required this.premium,
    this.repeatable = false,
    this.sku,
  });

  final String id;
  final String name;
  final String blurb;
  final String category;
  final int cost;
  final bool premium;
  final bool repeatable;
  final String? sku;

  bool get realMoney => sku != null;
}

const shopItems = <ShopItem>[
  ShopItem(
    id: 'avatar_scout',
    name: 'Tide Scout',
    blurb: 'The free traveler everyone starts as.',
    category: 'avatar',
    cost: 0,
    premium: false,
  ),
  ShopItem(
    id: 'avatar_emberfox',
    name: 'Ember Fox',
    blurb: 'A small fox with coal-bright ears.',
    category: 'avatar',
    cost: 80,
    premium: true,
  ),
  ShopItem(
    id: 'avatar_moonmoth',
    name: 'Moon Moth',
    blurb: 'Pale wings and a quiet grin.',
    category: 'avatar',
    cost: 80,
    premium: true,
  ),
  ShopItem(
    id: 'avatar_kelpknight',
    name: 'Kelp Knight',
    blurb: 'A helm grown from green kelp.',
    category: 'avatar',
    cost: 120,
    premium: true,
  ),
  ShopItem(
    id: 'avatar_starwren',
    name: 'Star Wren',
    blurb: 'A bird-mask dusted with sparks.',
    category: 'avatar',
    cost: 120,
    premium: true,
  ),
  ShopItem(
    id: 'theme_tideglass',
    name: 'Tideglass',
    blurb: 'Warm sand and teal. Free for everyone.',
    category: 'theme',
    cost: 0,
    premium: false,
  ),
  ShopItem(
    id: 'theme_starwharf',
    name: 'Starwharf',
    blurb: 'Night docks and lantern gold.',
    category: 'theme',
    cost: 100,
    premium: true,
  ),
  ShopItem(
    id: 'theme_emberkeep',
    name: 'Ember Keep',
    blurb: 'Hearth red and charcoal.',
    category: 'theme',
    cost: 100,
    premium: true,
  ),
  ShopItem(
    id: 'theme_moonlace',
    name: 'Moonlace',
    blurb: 'Dusk plum and seafoam.',
    category: 'theme',
    cost: 140,
    premium: true,
  ),
  ShopItem(
    id: 'card_classic',
    name: 'Classic Sail',
    blurb: 'The free card back.',
    category: 'card',
    cost: 0,
    premium: false,
  ),
  ShopItem(
    id: 'card_constellation',
    name: 'Constellation',
    blurb: 'A star map on deep cloth.',
    category: 'card',
    cost: 60,
    premium: true,
  ),
  ShopItem(
    id: 'card_coral',
    name: 'Coral Crest',
    blurb: 'Ridges like a reef.',
    category: 'card',
    cost: 60,
    premium: true,
  ),
  ShopItem(
    id: 'card_rune',
    name: 'Rune Weave',
    blurb: 'Soft geometry on linen.',
    category: 'card',
    cost: 90,
    premium: true,
  ),
  ShopItem(
    id: 'board_sand',
    name: 'Sand Table',
    blurb: 'The free play mat.',
    category: 'board',
    cost: 0,
    premium: false,
  ),
  ShopItem(
    id: 'board_midnight',
    name: 'Midnight Felt',
    blurb: 'A dark mat for late games.',
    category: 'board',
    cost: 70,
    premium: true,
  ),
  ShopItem(
    id: 'board_blossom',
    name: 'Blossom Mat',
    blurb: 'Petals around the grid.',
    category: 'board',
    cost: 70,
    premium: true,
  ),
  ShopItem(
    id: 'freeze',
    name: 'Streak Freeze',
    blurb: 'Protects your streaks for one missed day. Hold up to 5.',
    category: 'freeze',
    cost: 50,
    premium: true,
    repeatable: true,
  ),
  ShopItem(
    id: 'life',
    name: 'Extra Life',
    blurb: 'Refills one arcade life immediately.',
    category: 'life',
    cost: 40,
    premium: true,
    repeatable: true,
  ),
  ShopItem(
    id: 'peek',
    name: 'Peek',
    blurb: 'A short look at the hidden answer.',
    category: 'booster',
    cost: 30,
    premium: true,
    repeatable: true,
  ),
  ShopItem(
    id: 'time',
    name: 'Extra Time',
    blurb: 'Adds seconds on a timed challenge.',
    category: 'booster',
    cost: 25,
    premium: true,
    repeatable: true,
  ),
  ShopItem(
    id: 'hint',
    name: 'Hint',
    blurb: 'Reveals one step of the answer.',
    category: 'booster',
    cost: 20,
    premium: true,
    repeatable: true,
  ),
  ShopItem(
    id: 'shuffle',
    name: 'Shuffle',
    blurb: 'Remixes unmatched cards in Pairwell.',
    category: 'booster',
    cost: 20,
    premium: true,
    repeatable: true,
  ),
  ShopItem(
    id: 'pouch_small',
    name: 'Clarity Pouch',
    blurb: 'Reserved for a later real-money purchase. Nothing is charged now.',
    category: 'pouch',
    cost: 0,
    premium: true,
    sku: 'clarity_pouch_80',
  ),
  ShopItem(
    id: 'chest_large',
    name: 'Clarity Chest',
    blurb: 'A larger pouch, also reserved. Payments are not enabled.',
    category: 'pouch',
    cost: 0,
    premium: true,
    sku: 'clarity_chest_500',
  ),
];

ShopItem? shopItemById(String id) {
  for (final item in shopItems) {
    if (item.id == id) return item;
  }
  return null;
}

class LevelSpec {
  const LevelSpec(this.seconds, this.a, [this.b = 0]);

  final int seconds;
  final int a;
  final int b;
}

const arcadeGameIds = [
  'pairwell',
  'beacon',
  'lattice',
  'glance',
  'lexicon',
  'digits',
  'oddling',
  'inkwise',
  'waymark',
];

bool usesLives(String gameId) => gameId != 'daily' && gameId != 'tidebreath';

int levelCount(String gameId) => gameId == 'tidebreath' ? 6 : 8;

LevelSpec levelSpec(String gameId, int level) {
  final i = level.clamp(1, 8) - 1;
  switch (gameId) {
    case 'pairwell':
      return LevelSpec(
        [70, 80, 90, 80, 100, 90, 110, 120][i],
        [3, 4, 6, 6, 8, 8, 10, 12][i],
      );
    case 'beacon':
      return LevelSpec(
        [40, 45, 50, 55, 60, 60, 70, 75][i],
        [3, 4, 5, 5, 6, 7, 8, 9][i],
      );
    case 'lattice':
      return LevelSpec(
        [30, 30, 35, 35, 40, 40, 45, 45][i],
        [3, 3, 3, 4, 4, 4, 4, 5][i],
        [3, 4, 4, 4, 5, 6, 7, 8][i],
      );
    case 'glance':
      return LevelSpec(
        [50, 45, 45, 40, 40, 35, 35, 30][i],
        [3, 3, 4, 4, 4, 5, 5, 5][i],
      );
    case 'lexicon':
      return LevelSpec(
        [45, 45, 50, 50, 55, 55, 60, 60][i],
        [3, 4, 4, 5, 5, 6, 7, 8][i],
        [6, 6, 5, 5, 5, 4, 4, 4][i],
      );
    case 'digits':
      return LevelSpec(
        [20, 22, 24, 26, 28, 30, 32, 34][i],
        [3, 4, 4, 5, 5, 6, 7, 8][i],
        [3, 3, 2, 2, 2, 2, 2, 2][i],
      );
    case 'oddling':
      return LevelSpec(
        [40, 40, 45, 45, 50, 50, 55, 55][i],
        [3, 3, 4, 4, 4, 5, 5, 5][i],
        [2, 3, 3, 3, 4, 4, 4, 5][i],
      );
    case 'inkwise':
      return LevelSpec(
        [30, 32, 34, 36, 40, 42, 46, 50][i],
        [6, 8, 8, 10, 10, 12, 12, 14][i],
      );
    case 'waymark':
      return LevelSpec(
        [30, 35, 35, 40, 40, 45, 45, 50][i],
        [3, 3, 4, 4, 4, 5, 5, 5][i],
        [3, 4, 4, 5, 6, 6, 7, 8][i],
      );
    case 'tidebreath':
      return LevelSpec(60, (level.clamp(1, 6)) - 1);
    case 'daily':
      return levelSpec(dailyKind(DateTime.now()), level);
    default:
      return const LevelSpec(30, 3);
  }
}

int pairwellStars({
  required int pairs,
  required int moves,
  required bool cleared,
}) {
  if (!cleared || pairs <= 0) return 0;
  if (moves <= pairs) return 3;
  if (moves <= pairs * 2) return 2;
  return 1;
}

int boosterStars(int boostersUsed, {required bool cleared}) {
  if (!cleared) return 0;
  if (boostersUsed <= 0) return 3;
  if (boostersUsed == 1) return 2;
  return 1;
}

int mistakeStars(int mistakes, {required bool cleared}) {
  if (!cleared) return 0;
  if (mistakes <= 0) return 3;
  if (mistakes == 1) return 2;
  return 1;
}

int glanceStars({
  required bool cleared,
  required int hints,
  required double timeLeftRatio,
}) {
  if (!cleared) return 0;
  var stars = timeLeftRatio > 0.45
      ? 3
      : timeLeftRatio > 0.2
      ? 2
      : 1;
  if (hints >= 2) {
    stars = min(stars, 1);
  } else if (hints == 1) {
    stars = min(stars, 2);
  }
  return stars;
}

const wordBank = [
  'tideglass',
  'emberfox',
  'moonlace',
  'starwharf',
  'lantern',
  'driftwood',
  'beacon',
  'lattice',
  'waymark',
  'hatchling',
  'skykeep',
  'coral',
  'anchor',
  'glimmer',
  'thistle',
  'harbor',
  'comet',
  'willow',
  'quartz',
  'bramble',
  'cinder',
  'pearl',
  'saffron',
  'mariner',
  'oasis',
  'spire',
  'quay',
  'dune',
  'foam',
  'ripple',
  'nimbus',
  'falcon',
  'copper',
  'velvet',
  'keepsake',
  'marigold',
  'pebble',
  'kindling',
  'aurora',
  'cairn',
];

List<String> wordsFor({required int count, required int seed}) {
  final copy = [...wordBank]..shuffle(Random(seed));
  return copy.take(min(count, copy.length)).toList();
}

int recallHits(List<String> shown, String typed) {
  final wanted = shown.map((e) => e.toLowerCase()).toSet();
  final tokens = typed
      .toLowerCase()
      .split(RegExp(r'[^a-z]+'))
      .where((w) => w.isNotEmpty)
      .toSet();
  return tokens.where(wanted.contains).length;
}

int recallStars(int hits, int total) {
  if (total <= 0 || hits <= 0) return 0;
  final pct = hits / total;
  if (pct >= 0.999) return 3;
  if (pct >= 0.7) return 2;
  if (pct >= 0.4) return 1;
  return 0;
}

int dateSeed(DateTime day) => day.year * 10000 + day.month * 100 + day.day;

String dailyKind(DateTime day) {
  const kinds = ['oddling', 'digits', 'lexicon', 'waymark'];
  return kinds[dateSeed(day) % kinds.length];
}

int featuredDailyLevel({
  required int streak,
  required bool doneToday,
  required bool Function(int level) unlocked,
}) {
  var level = doneToday ? streak : streak + 1;
  if (level < 1) level = 1;
  if (level > 8) level = 8;
  while (level > 1 && !unlocked(level)) {
    level -= 1;
  }
  return level;
}

List<int> makeSequence(int length, int seed) {
  final rng = Random(seed);
  return [for (var i = 0; i < length; i++) rng.nextInt(4)];
}

List<int> makeLit(int grid, int count, int seed) {
  final rng = Random(seed);
  final all = [for (var i = 0; i < grid * grid; i++) i]..shuffle(rng);
  final n = min(count, all.length);
  return all.take(n).toList()..sort();
}

List<int> makePath({required int grid, required int length, required int seed}) {
  final rng = Random(seed);
  final cap = min(length, max(1, grid * grid - 1));
  for (var attempt = 0; attempt < 40; attempt++) {
    final cells = <int>[rng.nextInt(grid * grid)];
    var stuck = false;
    while (cells.length < cap) {
      final last = cells.last;
      final r = last ~/ grid;
      final c = last % grid;
      final options = <int>[];
      if (r > 0) options.add(last - grid);
      if (r < grid - 1) options.add(last + grid);
      if (c > 0) options.add(last - 1);
      if (c < grid - 1) options.add(last + 1);
      options.removeWhere(cells.contains);
      if (options.isEmpty) {
        stuck = true;
        break;
      }
      cells.add(options[rng.nextInt(options.length)]);
    }
    if (!stuck && cells.length == cap) return cells;
  }
  return [for (var i = 0; i < cap; i++) i];
}

class BreathPhase {
  const BreathPhase(this.label, this.seconds);
  final String label;
  final int seconds;
}

const breathPatterns = <List<BreathPhase>>[
  [BreathPhase('Breathe in', 4), BreathPhase('Breathe out', 4)],
  [
    BreathPhase('Breathe in', 4),
    BreathPhase('Hold', 4),
    BreathPhase('Breathe out', 4),
    BreathPhase('Hold', 4),
  ],
  [
    BreathPhase('Breathe in', 4),
    BreathPhase('Hold', 2),
    BreathPhase('Breathe out', 6),
  ],
  [BreathPhase('Breathe in', 5), BreathPhase('Breathe out', 5)],
  [
    BreathPhase('Breathe in', 3),
    BreathPhase('Hold', 3),
    BreathPhase('Breathe out', 6),
  ],
  [
    BreathPhase('Breathe in', 6),
    BreathPhase('Hold', 2),
    BreathPhase('Breathe out', 6),
  ],
];

const breathNames = [
  'Easy Tide',
  'Square Tide',
  'Long Exhale',
  'Even Tide',
  'Quiet Count',
  'Deep Harbor',
];

class PurchaseResult {
  const PurchaseResult({
    required this.ok,
    required this.channel,
    required this.message,
  });

  final bool ok;
  final String channel;
  final String message;
}

String formatClock(int ms) {
  final total = max(0, ms) ~/ 1000;
  final m = (total ~/ 60).toString().padLeft(2, '0');
  final s = (total % 60).toString().padLeft(2, '0');
  return '$m:$s';
}
