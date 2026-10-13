import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/clarity_logic.dart';
import '../models/app_data.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'games.dart';
import 'habits.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final due = state.data.habits.where(state.dueToday).toList();
    final kind = dailyKind(state.now);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text('Today', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        Text('Streak ${state.accountStreak} · Mind ${state.mindStreakCount} · Freezes ${state.data.profile.freezes}'),
        const SizedBox(height: 8),
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
                    Text(
                      state.dailyDoneToday ? 'Daily riddle cleared' : 'Daily riddle',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text('${gameName(kind)} · level ${state.featuredDaily}. It counts toward your streak.'),
                  ],
                ),
              ),
              if (state.dailyDoneToday) const Icon(Icons.check_circle, color: Color(0xFF0F766E)),
            ],
          ),
        ),
        if (due.isEmpty)
          const SoftCard(
            child: Text('Nothing is scheduled today. Add a habit, or mark one for these weekdays.'),
          )
        else
          for (final habit in due)
            SoftCard(
              child: Row(
                children: [
                  Text(habit.glyph, style: const TextStyle(fontSize: 28)),
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
                    tooltip: state.checkedToday(habit) ? 'Checked in' : 'Check in',
                    onPressed: state.checkedToday(habit)
                        ? null
                        : () {
                            final beforeXp = state.data.profile.xp;
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
                    icon: Icon(state.checkedToday(habit) ? Icons.check_circle : Icons.circle_outlined),
                  ),
                ],
              ),
            ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HabitEditor())),
          icon: const Icon(Icons.add),
          label: const Text('Add a habit'),
        ),
      ],
    );
  }
}
