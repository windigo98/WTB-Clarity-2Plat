import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/clarity_logic.dart';
import '../state/app_state.dart';
import '../theme/clarity_theme.dart';
import '../widgets/board.dart';
import '../widgets/common.dart';
import 'games.dart';

class ArcadePage extends StatefulWidget {
  const ArcadePage({super.key});

  @override
  State<ArcadePage> createState() => _ArcadePageState();
}

class _ArcadePageState extends State<ArcadePage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      context.read<AppState>().reconcileLives();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lives = state.data.profile.lives;
    final wait = lives >= LifeClock.maxLives ? 'Lives full' : 'Next life ${formatClock(state.msUntilNextLife)}';
    final featured = featuredArcadeId(state.now);
    final level = nextOpenLevel(
      count: levelCount(featured),
      unlocked: (value) => state.levelUnlocked(featured, value),
      stars: (value) => state.starsFor(featured, value),
    );
    final width = MediaQuery.sizeOf(context).width;
    final games = [...arcadeGameIds, 'tidebreath'];
    return FillPage(
      top: [
        BannerCard(
          child: Row(
            children: [
              ProgressRing(
                progress: lives / LifeClock.maxLives,
                label: '$lives',
                caption: 'lives',
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Arcade', style: TextStyle(fontFamily: 'Cinzel', fontWeight: FontWeight.w700, fontSize: 22)),
                    Text('$lives/${LifeClock.maxLives} · $wait'),
                    const Text('Wins earn XP and a picture piece.'),
                  ],
                ),
              ),
            ],
          ),
        ),
        SoftCard(
          onTap: () => openGame(context, 'daily', state.featuredDaily),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Daily riddle', style: TextStyle(fontWeight: FontWeight.w800)),
                    Text('${gameName(dailyKind(state.now))} · level ${state.featuredDaily}. It counts toward your streak.'),
                  ],
                ),
              ),
            ],
          ),
        ),
        SoftCard(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LevelMapPage(gameId: featured))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Featured · ${gameName(featured)}', style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(gameBlurb(featured)),
              Text('Open level $level'),
            ],
          ),
        ),
      ],
      bottom: [
        const SectionLabel('Every game'),
        if (width >= 720)
          Wrap(
            spacing: 8,
            children: [
              for (final id in games) SizedBox(width: 280, child: _GameLink(id: id)),
            ],
          )
        else
          for (final id in games) _GameLink(id: id),
      ],
    );
  }
}

class _GameLink extends StatelessWidget {
  const _GameLink({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    var cleared = 0;
    for (var level = 1; level <= levelCount(id); level++) {
      if (state.starsFor(id, level) > 0) cleared += 1;
    }
    return SoftCard(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LevelMapPage(gameId: id))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(gameName(id), style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(gameBlurb(id)),
          Text('$cleared/${levelCount(id)} levels cleared'),
        ],
      ),
    );
  }
}

class LevelMapPage extends StatelessWidget {
  const LevelMapPage({super.key, required this.gameId});

  final String gameId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final count = levelCount(gameId);
    return ClarityPage(
      title: gameName(gameId),
      scene: Scene.arcade,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(gameBlurb(gameId)),
          const SizedBox(height: 8),
          for (var level = 1; level <= count; level++)
            SoftCard(
              onTap: state.levelUnlocked(gameId, level)
                  ? () => openGame(context, gameId, level)
                  : null,
              child: Row(
                children: [
                  CircleAvatar(child: Text('$level')),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(gameId == 'tidebreath' ? breathNames[level - 1] : 'Level $level'),
                        if (!state.levelUnlocked(gameId, level))
                          const Text('Clear the previous level to open this one.')
                        else
                          StarRow(stars: state.starsFor(gameId, level)),
                      ],
                    ),
                  ),
                  Icon(state.levelUnlocked(gameId, level) ? Icons.play_arrow : Icons.lock),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
