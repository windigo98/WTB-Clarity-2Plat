import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/clarity_logic.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final today = Day.dateOnly(state.now);
    return ClarityPage(
      title: 'Character',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              AvatarBadge(id: state.data.profile.avatarId, size: 72),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(state.data.profile.name, style: Theme.of(context).textTheme.headlineSmall),
                    Text('${state.title} · level ${state.level}'),
                    Text('${state.xpInto}/${state.xpNeed} XP toward the next level'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('Streak ${state.accountStreak}'),
              _chip('Mind ${state.mindStreakCount}'),
              _chip('Clarity ${state.data.profile.clarity}'),
              _chip('Castles ${state.data.profile.castlesFinished}'),
              _chip('Tower ${state.data.tower.length}'),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Last five weeks', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 6, crossAxisSpacing: 6),
            itemCount: 35,
            itemBuilder: (context, index) {
              final day = today.subtract(Duration(days: 34 - index));
              final on = state.data.habits.any((h) => h.checkIns.contains(Day.key(day))) ||
                  state.data.profile.mindDays.contains(Day.key(day));
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: on ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(child: Text('${day.day}', style: TextStyle(fontSize: 11, color: on ? Colors.white : null))),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text('Habits', style: TextStyle(fontWeight: FontWeight.w800)),
          for (final habit in state.data.habits)
            SoftCard(child: Text('${habit.glyph} ${habit.name} · streak ${state.streakFor(habit)} · best ${habit.bestStreak}')),
          const Text('Recent XP', style: TextStyle(fontWeight: FontWeight.w800)),
          if (state.data.xpLog.isEmpty) const SoftCard(child: Text('XP shows up after the first check-in, focus bout, or game.')),
          for (final event in state.data.xpLog.take(12))
            SoftCard(child: Text('+${event.xp} · ${event.reason}')),
        ],
      ),
    );
  }

  Widget _chip(String text) => Chip(label: Text(text));
}
