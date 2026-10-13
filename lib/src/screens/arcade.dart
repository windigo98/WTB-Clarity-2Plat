import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/clarity_logic.dart';
import '../state/app_state.dart';
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Arcade', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        Text('Lives $lives/${LifeClock.maxLives} · $wait'),
        const Text('Wins earn XP and a picture piece. Boosters and extra lives are in the shop.'),
        SoftCard(
          onTap: () => openGame(context, 'daily', state.featuredDaily),
          child: Text('Daily riddle · ${gameName(dailyKind(state.now))} · level ${state.featuredDaily}'),
        ),
        for (final id in arcadeGameIds) _GameLink(id: id),
        _GameLink(id: 'tidebreath'),
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
