import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/clarity_logic.dart';
import '../models/app_data.dart';
import '../painters/painters.dart';
import '../state/app_state.dart';
import '../widgets/board.dart';
import '../widgets/chrome.dart';
import '../widgets/common.dart';
import 'arcade.dart';
import 'castle.dart';
import 'games.dart';
import 'habits.dart';
import 'routines.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final due = state.data.habits.where(state.dueToday).toList();
    final checked = due.where(state.checkedToday).length;
    final dailyDone = state.dailyDoneToday;
    final total = due.length + 1;
    final done = checked + (dailyDone ? 1 : 0);
    final kind = dailyKind(state.now);
    final featured = featuredArcadeId(state.now);
    final slot = nextRoutineSlot(state.now);
    final routine = state.data.routines.where((r) => r.slot == slot).firstOrNull;
    final steps = routine?.steps ?? const <RoutineStep>[];
    final pieces = state.data.profile.castlePieces;
    final castleDone = pieces >= SandcastlePlan.pieceCount;
    final nextCost = castleDone ? 0 : SandcastlePlan.cost(pieces);
    final level = nextOpenLevel(
      count: levelCount(featured),
      unlocked: (value) => state.levelUnlocked(featured, value),
      stars: (value) => state.starsFor(featured, value),
    );

    return FillPage(
      top: [
        BannerCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ProgressRing(
                    progress: total == 0 ? 0 : done / total,
                    label: '$done/$total',
                    caption: 'today',
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${tideGreeting(state.now.hour)}, ${state.data.profile.name}',
                          style: const TextStyle(fontFamily: 'Cinzel', fontWeight: FontWeight.w700, fontSize: 20, color: Color(0xFFFFF6EA)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          done >= total
                              ? 'The tide is met. The beach is yours.'
                              : '${total - done} still out before the tide turns.',
                        ),
                        Wrap(
                          children: [
                            TideChip('Streak ${state.accountStreak}'),
                            TideChip('Mind ${state.mindStreakCount}'),
                            TideChip('${state.data.profile.freezes} freezes'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => openGame(context, 'daily', state.featuredDaily),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dailyDone
                            ? 'Daily riddle cleared'
                            : 'Daily riddle · ${gameName(kind)} · level ${state.featuredDaily}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Icon(dailyDone ? Icons.check_circle : Icons.play_arrow, color: const Color(0xFFFFE7A3)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SectionLabel('On the sand'),
        if (due.isEmpty)
          const SoftCard(
            child: Text('Nothing is scheduled today. Add a habit, or mark one for these weekdays.'),
          )
        else
          for (final habit in due) _HabitRow(habit: habit),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HabitEditor())),
          icon: const Icon(Icons.add),
          label: const Text('Add a habit'),
        ),
      ],
      bottom: [
        const SectionLabel('Along the shore'),
        SoftCard(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CastlePage())),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 112,
                  height: 84,
                  child: CustomPaint(
                    painter: SandcastlePainter(pieces: pieces, bob: 0, wave: 0),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sandcastle', style: TextStyle(fontWeight: FontWeight.w800)),
                    Text(castleDone ? 'All 12 pieces stand. The tide is waiting.' : '$pieces of ${SandcastlePlan.pieceCount} pieces'),
                    Text(
                      castleDone ? 'Take a selfie before the wash.' : 'Next: ${SandcastlePlan.names[pieces]} · $nextCost Clarity',
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
        SoftCard(
          onTap: steps.isEmpty
              ? null
              : () => Navigator.push(context, MaterialPageRoute(builder: (_) => RoutineRunPage(slot: slot))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(slot == 'morning' ? 'Morning run' : 'Evening run', style: const TextStyle(fontWeight: FontWeight.w800)),
              if (steps.isEmpty)
                const Text('No steps yet. Shape this routine on the Routines tab.')
              else ...[
                Text('${steps.length} steps · up next: ${steps.first.label}'),
                const SizedBox(height: 6),
                for (final step in steps.take(3)) Text('· ${step.label}'),
                if (steps.length > 3) Text('· ${steps.length - 3} more'),
              ],
            ],
          ),
        ),
        SoftCard(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LevelMapPage(gameId: featured))),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Color(0xFF5EEAD4), Color(0xFF0F766E)]),
                ),
                child: const Icon(Icons.sports_esports, color: Color(0xFFFFF8EF)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Featured · ${gameName(featured)}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(gameBlurb(featured)),
                    Text('Level $level · a win drops a picture piece'),
                  ],
                ),
              ),
              const Icon(Icons.play_arrow),
            ],
          ),
        ),
      ],
    );
  }
}

class _HabitRow extends StatelessWidget {
  const _HabitRow({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final checked = state.checkedToday(habit);
    return SoftCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Color(0xFF5EEAD4), Color(0xFF0F766E)]),
              boxShadow: [BoxShadow(color: Color(0x66064E3B), offset: Offset(0, 3), blurRadius: 0)],
            ),
            child: Text(habit.glyph, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(habit.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text('Streak ${state.streakFor(habit)} · best ${habit.bestStreak}'),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit habit',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => HabitEditor(habitId: habit.id)),
            ),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            key: Key('check-${habit.id}'),
            tooltip: checked ? 'Checked in' : 'Check in',
            onPressed: checked
                ? null
                : () {
                    final beforeXp = state.data.profile.xp;
                    ConfettiBurst.show(context);
                    final message = state.checkIn(habit.id);
                    final gained = state.data.profile.xp - beforeXp;
                    if (message != null && message.startsWith('level:')) {
                      showLevelUp(
                        context,
                        Reward(
                          xp: gained,
                          clarity: XpRules.checkInClarity,
                          levelsGained: 1,
                          newLevel: state.level,
                          title: state.title,
                          drop: rollDrop(
                            rarityRoll: 0,
                            pictureRoll: 0,
                            pieceRoll: 0,
                            owned: const {},
                          ),
                          stars: 0,
                          albumCompleted: false,
                        ),
                      );
                    } else if (message != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Checked in. +$gained XP and ${XpRules.checkInClarity} Clarity.')),
                      );
                    }
                  },
            icon: Icon(checked ? Icons.check_circle : Icons.circle_outlined),
          ),
        ],
      ),
    );
  }
}
