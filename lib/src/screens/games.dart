import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/clarity_logic.dart';
import '../painters/painters.dart';
import '../state/app_state.dart';
import '../theme/clarity_theme.dart';
import '../widgets/common.dart';

Future<void> openGame(BuildContext context, String gameId, int level) async {
  final state = context.read<AppState>();
  state.reconcileLives();
  if (usesLives(gameId) && state.data.profile.lives <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'No lives left. Next life in ${formatClock(state.msUntilNextLife)}, or buy one in the shop.',
        ),
      ),
    );
    return;
  }
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => PlayScreen(gameId: gameId, level: level)),
  );
}

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key, required this.gameId, required this.level});

  final String gameId;
  final int level;

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  bool _done = false;

  Future<void> _finish(int stars) async {
    if (_done) return;
    _done = true;
    final state = context.read<AppState>();
    if (stars <= 0) {
      state.failArcade(widget.gameId);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Not this time'),
          content: Text(
            usesLives(widget.gameId)
                ? 'A life slips away. You can try again when you are ready.'
                : 'No life lost. You can try this one again.',
          ),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Back')),
          ],
        ),
      );
    } else {
      final reward = state.settleWin(
        gameId: widget.gameId,
        levelNumber: widget.level,
        stars: stars,
      );
      if (!mounted) return;
      await showRewardFlow(context, reward);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.gameId == 'daily' ? dailyKind(DateTime.now()) : widget.gameId;
    final spec = levelSpec(kind, widget.level);
    final board = context.watch<AppState>().data.profile.boardId;
    final tint = switch (board) {
      'board_midnight' => const Color(0x66000000),
      'board_blossom' => const Color(0x33FF8AD4),
      _ => null,
    };
    return ClarityPage(
      title: '${gameName(widget.gameId)} · ${widget.level}',
      scene: Scene.arcade,
      body: DecoratedBox(
        decoration: BoxDecoration(color: tint),
        child: switch (kind) {
          'pairwell' => PairwellBoard(
              pairs: spec.a,
              seconds: spec.seconds,
              seed: widget.level * 17,
              onFinished: _finish,
            ),
          'beacon' => BeaconBoard(length: spec.a, seed: widget.level * 19, onFinished: _finish),
          'lattice' => LatticeBoard(
              grid: spec.a,
              count: spec.b,
              seconds: spec.seconds,
              seed: widget.level * 23,
              onFinished: _finish,
            ),
          'glance' => GlanceBoard(count: spec.a, seconds: spec.seconds, onFinished: _finish),
          'lexicon' => LexiconBoard(
              count: spec.a,
              studySeconds: spec.b,
              seconds: spec.seconds,
              seed: widget.level * 29,
              onFinished: _finish,
            ),
          'digits' => DigitBoard(
              length: spec.a,
              showSeconds: spec.b,
              seconds: spec.seconds,
              seed: widget.level * 31,
              onFinished: _finish,
            ),
          'oddling' => OddlingBoard(
              grid: spec.a,
              rounds: spec.b,
              seconds: spec.seconds,
              level: widget.level,
              onFinished: _finish,
            ),
          'inkwise' => InkwiseBoard(trials: spec.a, seconds: spec.seconds, seed: widget.level * 37, onFinished: _finish),
          'waymark' => WaymarkBoard(
              grid: spec.a,
              length: spec.b,
              seconds: spec.seconds,
              seed: widget.level * 41,
              onFinished: _finish,
            ),
          'tidebreath' => BreathBoard(pattern: spec.a, onFinished: _finish),
          _ => const Center(child: Text('That challenge is not ready.')),
        },
      ),
    );
  }
}

const _faceIcons = [
  Icons.water_drop,
  Icons.local_fire_department,
  Icons.nightlight,
  Icons.spa,
  Icons.anchor,
  Icons.star,
  Icons.favorite,
  Icons.wb_sunny,
  Icons.park,
  Icons.sailing,
  Icons.diamond,
  Icons.music_note,
];

class PairwellBoard extends StatefulWidget {
  const PairwellBoard({
    super.key,
    required this.pairs,
    required this.seconds,
    required this.seed,
    required this.onFinished,
  });

  final int pairs;
  final int seconds;
  final int seed;
  final Future<void> Function(int stars) onFinished;

  @override
  State<PairwellBoard> createState() => _PairwellBoardState();
}

class _PairwellBoardState extends State<PairwellBoard> {
  late List<int> _faces;
  late List<bool> _up;
  late List<bool> _matched;
  int? _first;
  int _moves = 0;
  int _boosters = 0;
  bool _lock = false;
  bool _peek = false;
  int? _hint;
  late int _left;
  Timer? _timer;
  bool _ended = false;

  @override
  void initState() {
    super.initState();
    _faces = [for (var i = 0; i < widget.pairs; i++) ...[i, i]]..shuffle(Random(widget.seed));
    _up = List.filled(_faces.length, false);
    _matched = List.filled(_faces.length, false);
    _left = widget.seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _ended) return;
      if (_left <= 1) {
        _end(0);
      } else {
        setState(() => _left -= 1);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _end(int stars) {
    if (_ended) return;
    _ended = true;
    _timer?.cancel();
    widget.onFinished(stars);
  }

  void _tap(int index) {
    if (_ended || _lock || _matched[index] || _up[index]) return;
    setState(() => _up[index] = true);
    final first = _first;
    if (first == null) {
      _first = index;
      return;
    }
    _moves += 1;
    _first = null;
    if (_faces[first] == _faces[index]) {
      setState(() {
        _matched[first] = true;
        _matched[index] = true;
      });
      if (_matched.every((m) => m)) {
        _end(pairwellStars(pairs: widget.pairs, moves: _moves, cleared: true));
      }
    } else {
      _lock = true;
      Future<void>.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        setState(() {
          _up[first] = false;
          _up[index] = false;
          _lock = false;
        });
      });
    }
  }

  void _use(String id) {
    final state = context.read<AppState>();
    if (!state.spendBooster(id)) return;
    _boosters += 1;
    if (id == 'time') {
      setState(() => _left += 20);
    } else if (id == 'peek') {
      setState(() => _peek = true);
      Future<void>.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _peek = false);
      });
    } else if (id == 'hint') {
      int? a;
      int? b;
      for (var i = 0; i < _faces.length; i++) {
        if (_matched[i]) continue;
        for (var j = i + 1; j < _faces.length; j++) {
          if (!_matched[j] && _faces[i] == _faces[j]) {
            a = i;
            b = j;
            break;
          }
        }
        if (a != null) break;
      }
      if (a != null && b != null) {
        setState(() => _hint = a);
        _tap(a);
        _tap(b);
      }
    } else if (id == 'shuffle') {
      final open = [for (var i = 0; i < _faces.length; i++) if (!_matched[i]) i];
      final values = open.map((i) => _faces[i]).toList()..shuffle(Random());
      setState(() {
        for (var i = 0; i < open.length; i++) {
          _faces[open[i]] = values[i];
          _up[open[i]] = false;
        }
        _first = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final back = context.watch<AppState>().data.profile.cardBackId;
    final cols = _faces.length <= 6 ? 3 : 4;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Time ${_left}s · guesses $_moves'),
        BoosterBar(ids: const ['peek', 'hint', 'shuffle', 'time'], onUse: _use),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: 8, crossAxisSpacing: 8),
          itemCount: _faces.length,
          itemBuilder: (context, index) {
            final show = _peek || _up[index] || _matched[index];
            return InkWell(
              onTap: () => _tap(index),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _hint == index ? const Color(0xFFE6A317) : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: show
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_faceIcons[_faces[index] % _faceIcons.length], size: 32),
                      )
                    : CustomPaint(painter: CardBackPainter(back), child: const SizedBox.expand()),
              ),
            );
          },
        ),
        if (_boosters > 0) Text('Boosters used: $_boosters'),
      ],
    );
  }
}

class BeaconBoard extends StatefulWidget {
  const BeaconBoard({super.key, required this.length, required this.seed, required this.onFinished});

  final int length;
  final int seed;
  final Future<void> Function(int stars) onFinished;

  @override
  State<BeaconBoard> createState() => _BeaconBoardState();
}

class _BeaconBoardState extends State<BeaconBoard> {
  late final List<int> _sequence;
  int _gen = 0;
  int _lit = -1;
  int _cursor = 0;
  bool _input = false;
  int _boosters = 0;
  bool _ended = false;

  static const _colors = [
    Color(0xFFE85D4C),
    Color(0xFF0F766E),
    Color(0xFFE6A317),
    Color(0xFF3B82F6),
  ];

  @override
  void initState() {
    super.initState();
    _sequence = makeSequence(widget.length, widget.seed);
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  Future<void> _play() async {
    final gen = ++_gen;
    setState(() {
      _input = false;
      _cursor = 0;
    });
    for (final step in _sequence) {
      if (!mounted || gen != _gen) return;
      setState(() => _lit = step);
      await Future<void>.delayed(const Duration(milliseconds: 520));
      if (!mounted || gen != _gen) return;
      setState(() => _lit = -1);
      await Future<void>.delayed(const Duration(milliseconds: 180));
    }
    if (!mounted || gen != _gen) return;
    setState(() => _input = true);
  }

  void _end(int stars) {
    if (_ended) return;
    _ended = true;
    widget.onFinished(stars);
  }

  void _tap(int index) {
    if (!_input || _ended) return;
    if (_sequence[_cursor] != index) {
      _end(0);
      return;
    }
    setState(() => _lit = index);
    Future<void>.delayed(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => _lit = -1);
    });
    _cursor += 1;
    if (_cursor >= _sequence.length) {
      _end(boosterStars(_boosters, cleared: true));
    }
  }

  void _use(String id) {
    if (!context.read<AppState>().spendBooster(id)) return;
    _boosters += 1;
    if (id == 'peek') _play();
    if (id == 'hint' && _input && _cursor < _sequence.length) _tap(_sequence[_cursor]);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(_input ? 'Your turn' : 'Watch the beacons'),
          BoosterBar(ids: const ['peek', 'hint'], onUse: _use),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                for (var i = 0; i < 4; i++)
                  InkWell(
                    onTap: () => _tap(i),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _lit == i ? _colors[i] : _colors[i].withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LatticeBoard extends StatefulWidget {
  const LatticeBoard({
    super.key,
    required this.grid,
    required this.count,
    required this.seconds,
    required this.seed,
    required this.onFinished,
  });

  final int grid;
  final int count;
  final int seconds;
  final int seed;
  final Future<void> Function(int stars) onFinished;

  @override
  State<LatticeBoard> createState() => _LatticeBoardState();
}

class _LatticeBoardState extends State<LatticeBoard> {
  late final Set<int> _lit;
  final _picked = <int>{};
  bool _show = true;
  int _mistakes = 0;
  int _boosters = 0;
  late int _left;
  Timer? _timer;
  bool _ended = false;

  @override
  void initState() {
    super.initState();
    _lit = makeLit(widget.grid, widget.count, widget.seed).toSet();
    _left = widget.seconds;
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() => _show = false);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _ended) return;
        if (_left <= 1) {
          _end(0);
        } else {
          setState(() => _left -= 1);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _end(int stars) {
    if (_ended) return;
    _ended = true;
    _timer?.cancel();
    widget.onFinished(stars);
  }

  void _tap(int index) {
    if (_show || _ended || _picked.contains(index)) return;
    if (_lit.contains(index)) {
      setState(() => _picked.add(index));
      if (_picked.containsAll(_lit)) {
        _end(mistakeStars(_mistakes, cleared: true));
      }
    } else {
      setState(() => _mistakes += 1);
      if (_mistakes >= 3) _end(0);
    }
  }

  void _use(String id) {
    if (!context.read<AppState>().spendBooster(id)) return;
    _boosters += 1;
    if (id == 'time') setState(() => _left += 15);
    if (id == 'peek') {
      setState(() => _show = true);
      Future<void>.delayed(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _show = false);
      });
    }
    if (id == 'hint') {
      final next = _lit.difference(_picked);
      if (next.isNotEmpty) _tap(next.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(_show ? 'Memorize the lit runes' : 'Time ${_left}s · misses $_mistakes'),
          BoosterBar(ids: const ['peek', 'hint', 'time'], onUse: _use),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: widget.grid,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: widget.grid * widget.grid,
              itemBuilder: (context, index) {
                final on = (_show && _lit.contains(index)) || _picked.contains(index);
                return InkWell(
                  onTap: () => _tap(index),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: on ? const Color(0xFF0F766E) : const Color(0xFFE7E0D6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_boosters > 0) const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class GlanceBoard extends StatefulWidget {
  const GlanceBoard({super.key, required this.count, required this.seconds, required this.onFinished});

  final int count;
  final int seconds;
  final Future<void> Function(int stars) onFinished;

  @override
  State<GlanceBoard> createState() => _GlanceBoardState();
}

class _GlanceBoardState extends State<GlanceBoard> {
  final _found = <int>{};
  int _hints = 0;
  late int _left;
  late int _total;
  Timer? _timer;
  bool _ended = false;

  @override
  void initState() {
    super.initState();
    _total = widget.seconds;
    _left = widget.seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _ended) return;
      if (_left <= 1) {
        _end(0);
      } else {
        setState(() => _left -= 1);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Set<int> get _alts => {for (var i = 0; i < widget.count; i++) i}.difference(_found);

  void _end(int stars) {
    if (_ended) return;
    _ended = true;
    _timer?.cancel();
    widget.onFinished(stars);
  }

  void _hit(Offset local, Size size) {
    if (_ended) return;
    final point = Offset(local.dx / size.width, local.dy / size.height);
    for (var i = 0; i < widget.count; i++) {
      if (_found.contains(i)) continue;
      if ((point - glanceSpots[i]).distance < 0.1) {
        setState(() => _found.add(i));
        if (_found.length >= widget.count) {
          _end(glanceStars(cleared: true, hints: _hints, timeLeftRatio: _left / _total));
        }
        return;
      }
    }
  }

  void _use(String id) {
    if (!context.read<AppState>().spendBooster(id)) return;
    if (id == 'time') setState(() => _left += 20);
    if (id == 'hint') {
      _hints += 1;
      for (var i = 0; i < widget.count; i++) {
        if (!_found.contains(i)) {
          setState(() => _found.add(i));
          if (_found.length >= widget.count) {
            _end(glanceStars(cleared: true, hints: _hints, timeLeftRatio: _left / _total));
          }
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('Time ${_left}s · found ${_found.length}/${widget.count}. Tap the changed scene.'),
          BoosterBar(ids: const ['hint', 'time'], onUse: _use),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _panel(false)),
                const SizedBox(width: 8),
                Expanded(child: _panel(true)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel(bool changed) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onTapUp: changed ? (details) => _hit(details.localPosition, size) : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CustomPaint(
              painter: GlancePainter(showAlts: changed, alts: _alts),
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
    );
  }
}

class LexiconBoard extends StatefulWidget {
  const LexiconBoard({
    super.key,
    required this.count,
    required this.studySeconds,
    required this.seconds,
    required this.seed,
    required this.onFinished,
  });

  final int count;
  final int studySeconds;
  final int seconds;
  final int seed;
  final Future<void> Function(int stars) onFinished;

  @override
  State<LexiconBoard> createState() => _LexiconBoardState();
}

class _LexiconBoardState extends State<LexiconBoard> {
  late final List<String> _words;
  late int _left;
  bool _study = true;
  int _boosters = 0;
  bool _ended = false;
  Timer? _timer;
  final _input = TextEditingController();

  @override
  void initState() {
    super.initState();
    _words = wordsFor(count: widget.count, seed: widget.seed);
    _left = widget.studySeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted || _ended) return;
    if (_left <= 1) {
      if (_study) {
        setState(() {
          _study = false;
          _left = widget.seconds;
        });
      } else {
        _submit();
      }
    } else {
      setState(() => _left -= 1);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _input.dispose();
    super.dispose();
  }

  void _submit() {
    if (_ended) return;
    _ended = true;
    _timer?.cancel();
    final hits = recallHits(_words, _input.text);
    var stars = recallStars(hits, _words.length);
    if (_boosters >= 2) {
      stars = min(stars, 1);
    } else if (_boosters == 1) {
      stars = min(stars, 2);
    }
    widget.onFinished(stars);
  }

  void _use(String id) {
    if (!context.read<AppState>().spendBooster(id)) return;
    _boosters += 1;
    if (id == 'time') setState(() => _left += _study ? 4 : 15);
    if (id == 'peek') setState(() => _study = true);
    if (id == 'hint' && !_study) {
      final have = _input.text.toLowerCase();
      for (final word in _words) {
        if (!have.contains(word)) {
          _input.text = '${_input.text} $word'.trim();
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(_study ? 'Study · ${_left}s' : 'Type them back · ${_left}s'),
        BoosterBar(ids: const ['peek', 'hint', 'time'], onUse: _use),
        const SizedBox(height: 12),
        if (_study)
          Wrap(spacing: 8, runSpacing: 8, children: [for (final word in _words) Chip(label: Text(word))])
        else ...[
          TextField(
            controller: _input,
            decoration: const InputDecoration(labelText: 'Words, in any order'),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _submit, child: const Text('Submit')),
        ],
      ],
    );
  }
}

class DigitBoard extends StatefulWidget {
  const DigitBoard({
    super.key,
    required this.length,
    required this.showSeconds,
    required this.seconds,
    required this.seed,
    required this.onFinished,
  });

  final int length;
  final int showSeconds;
  final int seconds;
  final int seed;
  final Future<void> Function(int stars) onFinished;

  @override
  State<DigitBoard> createState() => _DigitBoardState();
}

class _DigitBoardState extends State<DigitBoard> {
  late final String _code;
  late int _left;
  bool _show = true;
  int _boosters = 0;
  bool _ended = false;
  Timer? _timer;
  final _input = TextEditingController();

  @override
  void initState() {
    super.initState();
    final rng = Random(widget.seed);
    _code = [for (var i = 0; i < widget.length; i++) rng.nextInt(10)].join();
    _left = widget.showSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted || _ended) return;
    if (_left <= 1) {
      if (_show) {
        setState(() {
          _show = false;
          _left = widget.seconds;
        });
      } else {
        _submit();
      }
    } else {
      setState(() => _left -= 1);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _input.dispose();
    super.dispose();
  }

  void _submit() {
    if (_ended) return;
    _ended = true;
    _timer?.cancel();
    final typed = _input.text.replaceAll(RegExp(r'\D'), '');
    var stars = typed == _code ? 3 : 0;
    if (stars > 0 && _boosters > 0) stars = max(1, 3 - _boosters);
    widget.onFinished(stars);
  }

  void _use(String id) {
    if (!context.read<AppState>().spendBooster(id)) return;
    _boosters += 1;
    if (id == 'peek') setState(() => _show = true);
    if (id == 'time') setState(() => _left += 10);
    if (id == 'hint' && _input.text.isEmpty) _input.text = _code[0];
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(_show ? 'Look · ${_left}s' : 'Type the digits · ${_left}s'),
        BoosterBar(ids: const ['peek', 'hint', 'time'], onUse: _use),
        const SizedBox(height: 24),
        if (_show)
          Text(_code, textAlign: TextAlign.center, style: Theme.of(context).textTheme.displaySmall)
        else ...[
          TextField(
            controller: _input,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Digits'),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _submit, child: const Text('Submit')),
        ],
      ],
    );
  }
}

class OddlingBoard extends StatefulWidget {
  const OddlingBoard({
    super.key,
    required this.grid,
    required this.rounds,
    required this.seconds,
    required this.level,
    required this.onFinished,
  });

  final int grid;
  final int rounds;
  final int seconds;
  final int level;
  final Future<void> Function(int stars) onFinished;

  @override
  State<OddlingBoard> createState() => _OddlingBoardState();
}

class _OddlingBoardState extends State<OddlingBoard> {
  late int _round;
  late int _odd;
  late int _icon;
  int _mistakes = 0;
  late int _left;
  Timer? _timer;
  bool _ended = false;
  final _rng = Random(7);

  static const _icons = [
    Icons.water_drop,
    Icons.star,
    Icons.anchor,
    Icons.spa,
    Icons.nightlight,
    Icons.wb_sunny,
    Icons.favorite,
    Icons.park,
  ];

  @override
  void initState() {
    super.initState();
    _round = 0;
    _left = widget.seconds;
    _roll();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _ended) return;
      if (_left <= 1) {
        _end(0);
      } else {
        setState(() => _left -= 1);
      }
    });
  }

  void _roll() {
    final cells = widget.grid * widget.grid;
    _odd = _rng.nextInt(cells);
    _icon = _rng.nextInt(_icons.length);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _end(int stars) {
    if (_ended) return;
    _ended = true;
    _timer?.cancel();
    widget.onFinished(stars);
  }

  void _tap(int index) {
    if (_ended) return;
    if (index == _odd) {
      if (_round + 1 >= widget.rounds) {
        _end(mistakeStars(_mistakes, cleared: true));
      } else {
        setState(() {
          _round += 1;
          _roll();
        });
      }
    } else {
      setState(() => _mistakes += 1);
      if (_mistakes >= 3) _end(0);
    }
  }

  void _use(String id) {
    if (!context.read<AppState>().spendBooster(id)) return;
    if (id == 'time') setState(() => _left += 15);
    if (id == 'hint') _tap(_odd);
  }

  @override
  Widget build(BuildContext context) {
    final hard = widget.level >= 7;
    final colorShift = widget.level >= 4;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('Round ${_round + 1}/${widget.rounds} · ${_left}s · misses $_mistakes'),
          BoosterBar(ids: const ['hint', 'time'], onUse: _use),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: widget.grid,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: widget.grid * widget.grid,
              itemBuilder: (context, index) {
                final odd = index == _odd;
                final icon = odd && !colorShift && !hard ? _icons[(_icon + 1) % _icons.length] : _icons[_icon];
                final color = odd && (colorShift || hard) ? const Color(0xFFE85D4C) : const Color(0xFF0F766E);
                return InkWell(
                  onTap: () => _tap(index),
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: const Color(0xFFFFF8EF), borderRadius: BorderRadius.circular(12)),
                    child: Transform.rotate(
                      angle: odd && hard ? 0.5 : 0,
                      child: Icon(icon, color: color),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class InkwiseBoard extends StatefulWidget {
  const InkwiseBoard({super.key, required this.trials, required this.seconds, required this.seed, required this.onFinished});

  final int trials;
  final int seconds;
  final int seed;
  final Future<void> Function(int stars) onFinished;

  @override
  State<InkwiseBoard> createState() => _InkwiseBoardState();
}

class _InkwiseBoardState extends State<InkwiseBoard> {
  static const _names = ['Coral', 'Tide', 'Gold', 'Leaf'];
  static const _colors = [Color(0xFFE85D4C), Color(0xFF0F766E), Color(0xFFE6A317), Color(0xFF3E8E4D)];

  late final List<(int, int)> _trials;
  int _index = 0;
  int _correct = 0;
  int _boosters = 0;
  int? _hint;
  late int _left;
  Timer? _timer;
  bool _ended = false;

  @override
  void initState() {
    super.initState();
    final rng = Random(widget.seed);
    _trials = [
      for (var i = 0; i < widget.trials; i++)
        () {
          final word = rng.nextInt(4);
          var ink = rng.nextInt(4);
          if (ink == word) ink = (ink + 1) % 4;
          return (word, ink);
        }(),
    ];
    _left = widget.seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _ended) return;
      if (_left <= 1) {
        _end();
      } else {
        setState(() => _left -= 1);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _end() {
    if (_ended) return;
    _ended = true;
    _timer?.cancel();
    var stars = recallStars(_correct, widget.trials);
    if (_boosters > 0) stars = min(stars, max(0, 3 - _boosters));
    widget.onFinished(stars);
  }

  void _choose(int ink) {
    if (_ended) return;
    if (ink == _trials[_index].$2) _correct += 1;
    if (_index + 1 >= _trials.length) {
      _end();
    } else {
      setState(() {
        _index += 1;
        _hint = null;
      });
    }
  }

  void _use(String id) {
    if (!context.read<AppState>().spendBooster(id)) return;
    _boosters += 1;
    if (id == 'time') setState(() => _left += 12);
    if (id == 'hint') setState(() => _hint = _trials[_index].$2);
  }

  @override
  Widget build(BuildContext context) {
    final trial = _trials[_index];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('Tap the ink color, not the word · ${_left}s · ${_index + 1}/${widget.trials}'),
          BoosterBar(ids: const ['hint', 'time'], onUse: _use),
          const Spacer(),
          Text(
            _names[trial.$1],
            style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: _colors[trial.$2]),
          ),
          const Spacer(),
          Wrap(
            spacing: 8,
            children: [
              for (var i = 0; i < 4; i++)
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _colors[i],
                    side: _hint == i ? const BorderSide(color: Colors.white, width: 3) : null,
                  ),
                  onPressed: () => _choose(i),
                  child: Text(_names[i]),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class WaymarkBoard extends StatefulWidget {
  const WaymarkBoard({
    super.key,
    required this.grid,
    required this.length,
    required this.seconds,
    required this.seed,
    required this.onFinished,
  });

  final int grid;
  final int length;
  final int seconds;
  final int seed;
  final Future<void> Function(int stars) onFinished;

  @override
  State<WaymarkBoard> createState() => _WaymarkBoardState();
}

class _WaymarkBoardState extends State<WaymarkBoard> {
  late final List<int> _path;
  int _show = -1;
  int _cursor = 0;
  bool _input = false;
  int _mistakes = 0;
  int _boosters = 0;
  late int _left;
  Timer? _timer;
  bool _ended = false;
  int _gen = 0;

  @override
  void initState() {
    super.initState();
    _path = makePath(grid: widget.grid, length: widget.length, seed: widget.seed);
    _left = widget.seconds;
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _play() async {
    final gen = ++_gen;
    _timer?.cancel();
    setState(() => _input = false);
    for (final cell in _path) {
      if (!mounted || gen != _gen) return;
      setState(() => _show = cell);
      await Future<void>.delayed(const Duration(milliseconds: 420));
    }
    if (!mounted || gen != _gen) return;
    setState(() {
      _show = -1;
      _input = true;
      _cursor = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _ended) return;
      if (_left <= 1) {
        _end(0);
      } else {
        setState(() => _left -= 1);
      }
    });
  }

  void _end(int stars) {
    if (_ended) return;
    _ended = true;
    _timer?.cancel();
    var adjusted = stars;
    if (stars > 0 && _boosters > 0) adjusted = min(stars, max(1, 3 - _boosters));
    widget.onFinished(adjusted);
  }

  void _tap(int index) {
    if (!_input || _ended) return;
    if (_path[_cursor] != index) {
      setState(() => _mistakes += 1);
      if (_mistakes >= 3) _end(0);
      return;
    }
    setState(() => _show = index);
    _cursor += 1;
    if (_cursor >= _path.length) {
      _end(mistakeStars(_mistakes, cleared: true));
    }
  }

  void _use(String id) {
    if (!context.read<AppState>().spendBooster(id)) return;
    _boosters += 1;
    if (id == 'peek') _play();
    if (id == 'time') setState(() => _left += 15);
    if (id == 'hint' && _input && _cursor < _path.length) _tap(_path[_cursor]);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(_input ? 'Retrace the route · ${_left}s' : 'Watch the route'),
          BoosterBar(ids: const ['peek', 'hint', 'time'], onUse: _use),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: widget.grid,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: widget.grid * widget.grid,
              itemBuilder: (context, index) {
                final on = _show == index || (_input && _path.take(_cursor).contains(index));
                return InkWell(
                  onTap: () => _tap(index),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: on ? const Color(0xFFE6A317) : const Color(0xFFD7EDE8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class BreathBoard extends StatefulWidget {
  const BreathBoard({super.key, required this.pattern, required this.onFinished});

  final int pattern;
  final Future<void> Function(int stars) onFinished;

  @override
  State<BreathBoard> createState() => _BreathBoardState();
}

class _BreathBoardState extends State<BreathBoard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _ended = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 60))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finish();
      })
      ..forward();
  }

  void _finish() {
    if (_ended) return;
    _ended = true;
    widget.onFinished(3);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  BreathPhase _phase(double seconds) {
    final pattern = breathPatterns[widget.pattern.clamp(0, breathPatterns.length - 1)];
    final cycle = pattern.fold<int>(0, (sum, phase) => sum + phase.seconds);
    var t = seconds % cycle;
    for (final phase in pattern) {
      if (t < phase.seconds) return phase;
      t -= phase.seconds;
    }
    return pattern.last;
  }

  double _scale(double seconds) {
    final pattern = breathPatterns[widget.pattern.clamp(0, breathPatterns.length - 1)];
    final cycle = pattern.fold<int>(0, (sum, phase) => sum + phase.seconds);
    var t = seconds % cycle;
    for (final phase in pattern) {
      if (t <= phase.seconds) {
        final u = phase.seconds == 0 ? 1.0 : t / phase.seconds;
        if (phase.label == 'Breathe in') return 0.62 + 0.38 * u;
        if (phase.label == 'Breathe out') return 1 - 0.38 * u;
        return 1;
      }
      t -= phase.seconds;
    }
    return 0.8;
  }

  @override
  Widget build(BuildContext context) {
    final name = breathNames[widget.pattern.clamp(0, breathNames.length - 1)];
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final seconds = _controller.value * 60;
        final phase = _phase(seconds);
        final left = max(0, 60 - seconds).ceil();
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text('$left seconds left'),
              const Spacer(),
              Transform.scale(
                scale: _scale(seconds),
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF8ED4E8),
                  ),
                  alignment: Alignment.center,
                  child: Text(phase.label, style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const Spacer(),
              const Text('Stay with the circle for a full minute. Leaving early skips the reward.'),
            ],
          ),
        );
      },
    );
  }
}
