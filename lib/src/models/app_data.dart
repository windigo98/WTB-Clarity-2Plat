import '../logic/clarity_logic.dart';

int _int(Object? v, [int d = 0]) =>
    v is int ? v : v is num ? v.toInt() : d;

bool _bool(Object? v, [bool d = false]) => v is bool ? v : d;

String _str(Object? v, [String d = '']) => v is String ? v : d;

List<String> _strs(Object? v) =>
    v is List ? v.map((e) => e.toString()).toList() : <String>[];

List<int> _ints(Object? v) => v is List
    ? v.map((e) => e is int ? e : e is num ? e.toInt() : 0).toList()
    : <int>[];

class Habit {
  Habit({
    required this.id,
    required this.name,
    required this.glyph,
    required this.weekdays,
    List<String>? checkIns,
    this.bestStreak = 0,
  }) : checkIns = checkIns ?? <String>[];

  String id;
  String name;
  String glyph;
  List<int> weekdays;
  List<String> checkIns;
  int bestStreak;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'glyph': glyph,
    'weekdays': weekdays,
    'checkIns': checkIns,
    'bestStreak': bestStreak,
  };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
    id: _str(json['id']),
    name: _str(json['name'], 'Habit'),
    glyph: _str(json['glyph'], '✨'),
    weekdays: _ints(json['weekdays']),
    checkIns: _strs(json['checkIns']),
    bestStreak: _int(json['bestStreak']),
  );
}

class RoutineStep {
  RoutineStep({required this.id, required this.label, this.habitId});

  String id;
  String label;
  String? habitId;

  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'habitId': habitId,
  };

  factory RoutineStep.fromJson(Map<String, dynamic> json) => RoutineStep(
    id: _str(json['id']),
    label: _str(json['label'], 'Step'),
    habitId: json['habitId'] is String ? json['habitId'] as String : null,
  );
}

class Routine {
  Routine({required this.id, required this.slot, List<RoutineStep>? steps})
    : steps = steps ?? <RoutineStep>[];

  String id;
  String slot;
  List<RoutineStep> steps;

  Map<String, Object?> toJson() => {
    'id': id,
    'slot': slot,
    'steps': steps.map((s) => s.toJson()).toList(),
  };

  factory Routine.fromJson(Map<String, dynamic> json) => Routine(
    id: _str(json['id']),
    slot: _str(json['slot'], 'morning'),
    steps: json['steps'] is List
        ? (json['steps'] as List)
              .whereType<Map>()
              .map((e) => RoutineStep.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : <RoutineStep>[],
  );
}

class FocusSession {
  FocusSession({
    required this.id,
    required this.minutes,
    required this.xp,
    required this.createdMs,
  });

  String id;
  int minutes;
  int xp;
  int createdMs;

  Map<String, Object?> toJson() => {
    'id': id,
    'minutes': minutes,
    'xp': xp,
    'createdMs': createdMs,
  };

  factory FocusSession.fromJson(Map<String, dynamic> json) => FocusSession(
    id: _str(json['id']),
    minutes: _int(json['minutes']),
    xp: _int(json['xp']),
    createdMs: _int(json['createdMs']),
  );
}

class XpEvent {
  XpEvent({required this.xp, required this.reason, required this.createdMs});

  int xp;
  String reason;
  int createdMs;

  Map<String, Object?> toJson() => {
    'xp': xp,
    'reason': reason,
    'createdMs': createdMs,
  };

  factory XpEvent.fromJson(Map<String, dynamic> json) => XpEvent(
    xp: _int(json['xp']),
    reason: _str(json['reason']),
    createdMs: _int(json['createdMs']),
  );
}

class TowerEntry {
  TowerEntry({
    required this.id,
    required this.kind,
    required this.caption,
    required this.createdMs,
    this.imageId,
    this.pictureId,
  });

  String id;
  String kind;
  String caption;
  String? imageId;
  String? pictureId;
  int createdMs;

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind,
    'caption': caption,
    'imageId': imageId,
    'pictureId': pictureId,
    'createdMs': createdMs,
  };

  factory TowerEntry.fromJson(Map<String, dynamic> json) => TowerEntry(
    id: _str(json['id']),
    kind: _str(json['kind'], 'photo'),
    caption: _str(json['caption']),
    imageId: json['imageId'] is String ? json['imageId'] as String : null,
    pictureId: json['pictureId'] is String ? json['pictureId'] as String : null,
    createdMs: _int(json['createdMs']),
  );
}

class CastleSelfie {
  CastleSelfie({
    required this.id,
    required this.imageId,
    required this.createdMs,
  });

  String id;
  String imageId;
  int createdMs;

  Map<String, Object?> toJson() => {
    'id': id,
    'imageId': imageId,
    'createdMs': createdMs,
  };

  factory CastleSelfie.fromJson(Map<String, dynamic> json) => CastleSelfie(
    id: _str(json['id']),
    imageId: _str(json['imageId']),
    createdMs: _int(json['createdMs']),
  );
}

class CrewNote {
  CrewNote({required this.type, required this.summary, required this.createdMs});

  String type;
  String summary;
  int createdMs;

  Map<String, Object?> toJson() => {
    'type': type,
    'summary': summary,
    'createdMs': createdMs,
  };

  factory CrewNote.fromJson(Map<String, dynamic> json) => CrewNote(
    type: _str(json['type']),
    summary: _str(json['summary']),
    createdMs: _int(json['createdMs']),
  );
}

class Profile {
  Profile({
    required this.name,
    required this.xp,
    required this.clarity,
    required this.avatarId,
    required this.themeId,
    required this.cardBackId,
    required this.boardId,
    required this.freezes,
    required this.lives,
    required this.livesAnchorMs,
    required this.onboarded,
    required this.castlePieces,
    required this.castlesFinished,
    required this.mindDays,
    required this.frozenDays,
    required this.focusWorkMinutes,
    required this.focusBreakMinutes,
    required this.remindHabits,
    required this.reminderTime,
    required this.createdMs,
  });

  String name;
  int xp;
  int clarity;
  String avatarId;
  String themeId;
  String cardBackId;
  String boardId;
  int freezes;
  int lives;
  int livesAnchorMs;
  bool onboarded;
  int castlePieces;
  int castlesFinished;
  List<String> mindDays;
  List<String> frozenDays;
  int focusWorkMinutes;
  int focusBreakMinutes;
  bool remindHabits;
  String reminderTime;
  int createdMs;

  factory Profile.fresh(int nowMs) => Profile(
    name: 'Traveler',
    xp: 0,
    clarity: 20,
    avatarId: 'avatar_scout',
    themeId: 'theme_tideglass',
    cardBackId: 'card_classic',
    boardId: 'board_sand',
    freezes: 0,
    lives: LifeClock.maxLives,
    livesAnchorMs: nowMs,
    onboarded: false,
    castlePieces: 0,
    castlesFinished: 0,
    mindDays: [],
    frozenDays: [],
    focusWorkMinutes: 25,
    focusBreakMinutes: 5,
    remindHabits: false,
    reminderTime: '08:00',
    createdMs: nowMs,
  );

  Map<String, Object?> toJson() => {
    'name': name,
    'xp': xp,
    'clarity': clarity,
    'avatarId': avatarId,
    'themeId': themeId,
    'cardBackId': cardBackId,
    'boardId': boardId,
    'freezes': freezes,
    'lives': lives,
    'livesAnchorMs': livesAnchorMs,
    'onboarded': onboarded,
    'castlePieces': castlePieces,
    'castlesFinished': castlesFinished,
    'mindDays': mindDays,
    'frozenDays': frozenDays,
    'focusWorkMinutes': focusWorkMinutes,
    'focusBreakMinutes': focusBreakMinutes,
    'remindHabits': remindHabits,
    'reminderTime': reminderTime,
    'createdMs': createdMs,
  };

  factory Profile.fromJson(Map<String, dynamic> json, int nowMs) => Profile(
    name: _str(json['name'], 'Traveler'),
    xp: _int(json['xp']),
    clarity: _int(json['clarity']),
    avatarId: _str(json['avatarId'], 'avatar_scout'),
    themeId: _str(json['themeId'], 'theme_tideglass'),
    cardBackId: _str(json['cardBackId'], 'card_classic'),
    boardId: _str(json['boardId'], 'board_sand'),
    freezes: _int(json['freezes']),
    lives: _int(json['lives'], LifeClock.maxLives),
    livesAnchorMs: _int(json['livesAnchorMs'], nowMs),
    onboarded: _bool(json['onboarded']),
    castlePieces: _int(json['castlePieces']),
    castlesFinished: _int(json['castlesFinished']),
    mindDays: _strs(json['mindDays']),
    frozenDays: _strs(json['frozenDays']),
    focusWorkMinutes: _int(json['focusWorkMinutes'], 25),
    focusBreakMinutes: _int(json['focusBreakMinutes'], 5),
    remindHabits: _bool(json['remindHabits']),
    reminderTime: _str(json['reminderTime'], '08:00'),
    createdMs: _int(json['createdMs'], nowMs),
  );
}

class AppData {
  AppData({
    required this.profile,
    required this.habits,
    required this.routines,
    required this.sessions,
    required this.xpLog,
    required this.tower,
    required this.selfies,
    required this.pieces,
    required this.stars,
    required this.boosters,
    required this.owned,
    required this.crewNotes,
  });

  Profile profile;
  List<Habit> habits;
  List<Routine> routines;
  List<FocusSession> sessions;
  List<XpEvent> xpLog;
  List<TowerEntry> tower;
  List<CastleSelfie> selfies;
  Map<String, List<int>> pieces;
  Map<String, int> stars;
  Map<String, int> boosters;
  List<String> owned;
  List<CrewNote> crewNotes;

  factory AppData.fresh(int nowMs) => AppData(
    profile: Profile.fresh(nowMs),
    habits: [],
    routines: [
      Routine(id: 'morning', slot: 'morning'),
      Routine(id: 'evening', slot: 'evening'),
    ],
    sessions: [],
    xpLog: [],
    tower: [],
    selfies: [],
    pieces: {},
    stars: {},
    boosters: {'peek': 1, 'hint': 1, 'time': 1, 'shuffle': 0},
    owned: [
      'avatar_scout',
      'theme_tideglass',
      'card_classic',
      'board_sand',
    ],
    crewNotes: [],
  );

  Map<String, Object?> toJson() => {
    'schema': 1,
    'profile': profile.toJson(),
    'habits': habits.map((h) => h.toJson()).toList(),
    'routines': routines.map((r) => r.toJson()).toList(),
    'sessions': sessions.map((s) => s.toJson()).toList(),
    'xpLog': xpLog.map((e) => e.toJson()).toList(),
    'tower': tower.map((t) => t.toJson()).toList(),
    'selfies': selfies.map((s) => s.toJson()).toList(),
    'pieces': pieces,
    'stars': stars,
    'boosters': boosters,
    'owned': owned,
    'crewNotes': crewNotes.map((n) => n.toJson()).toList(),
  };

  factory AppData.fromJson(Map<String, dynamic> json, {int? nowMs}) {
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    final data = AppData(
      profile: json['profile'] is Map
          ? Profile.fromJson(
              Map<String, dynamic>.from(json['profile'] as Map),
              now,
            )
          : Profile.fresh(now),
      habits: json['habits'] is List
          ? (json['habits'] as List)
                .whereType<Map>()
                .map((e) => Habit.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : <Habit>[],
      routines: json['routines'] is List
          ? (json['routines'] as List)
                .whereType<Map>()
                .map((e) => Routine.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : <Routine>[],
      sessions: json['sessions'] is List
          ? (json['sessions'] as List)
                .whereType<Map>()
                .map((e) => FocusSession.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : <FocusSession>[],
      xpLog: json['xpLog'] is List
          ? (json['xpLog'] as List)
                .whereType<Map>()
                .map((e) => XpEvent.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : <XpEvent>[],
      tower: json['tower'] is List
          ? (json['tower'] as List)
                .whereType<Map>()
                .map((e) => TowerEntry.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : <TowerEntry>[],
      selfies: json['selfies'] is List
          ? (json['selfies'] as List)
                .whereType<Map>()
                .map((e) => CastleSelfie.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : <CastleSelfie>[],
      pieces: {},
      stars: {},
      boosters: {},
      owned: _strs(json['owned']),
      crewNotes: json['crewNotes'] is List
          ? (json['crewNotes'] as List)
                .whereType<Map>()
                .map((e) => CrewNote.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : <CrewNote>[],
    );
    if (json['pieces'] is Map) {
      (json['pieces'] as Map).forEach((key, value) {
        data.pieces[key.toString()] = _ints(value);
      });
    }
    if (json['stars'] is Map) {
      (json['stars'] as Map).forEach((key, value) {
        data.stars[key.toString()] = _int(value);
      });
    }
    if (json['boosters'] is Map) {
      (json['boosters'] as Map).forEach((key, value) {
        data.boosters[key.toString()] = _int(value);
      });
    }
    if (data.routines.every((r) => r.slot != 'morning')) {
      data.routines.insert(0, Routine(id: 'morning', slot: 'morning'));
    }
    if (data.routines.every((r) => r.slot != 'evening')) {
      data.routines.add(Routine(id: 'evening', slot: 'evening'));
    }
    if (data.owned.isEmpty) {
      data.owned.addAll(const [
        'avatar_scout',
        'theme_tideglass',
        'card_classic',
        'board_sand',
      ]);
    }
    return data;
  }
}

class Reward {
  const Reward({
    required this.xp,
    required this.clarity,
    required this.levelsGained,
    required this.newLevel,
    required this.title,
    required this.drop,
    required this.stars,
    required this.albumCompleted,
  });

  final int xp;
  final int clarity;
  final int levelsGained;
  final int newLevel;
  final String title;
  final DropOutcome drop;
  final int stars;
  final bool albumCompleted;
}
