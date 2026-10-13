import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_data.dart';
import '../state/app_state.dart';
import '../widgets/board.dart';
import '../widgets/common.dart';

class RoutinesPage extends StatelessWidget {
  const RoutinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(tabs: [Tab(text: 'Morning'), Tab(text: 'Evening')]),
          Expanded(
            child: TabBarView(
              children: [
                _RoutineList(slot: 'morning'),
                _RoutineList(slot: 'evening'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineList extends StatelessWidget {
  const _RoutineList({required this.slot});

  final String slot;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final routine = state.data.routines.where((r) => r.slot == slot).firstOrNull;
    final steps = routine?.steps ?? const <RoutineStep>[];
    return FillPage(
      top: [
        BannerCard(
          child: Row(
            children: [
              ProgressRing(
                progress: steps.isEmpty ? 0 : 1,
                label: '${steps.length}',
                caption: 'steps',
                color: const Color(0xFFFFE7A3),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slot == 'morning' ? 'Morning run' : 'Evening run',
                      style: const TextStyle(fontFamily: 'Cinzel', fontWeight: FontWeight.w700, fontSize: 20),
                    ),
                    Text(
                      steps.isEmpty
                          ? 'Add water, a stretch, or one quiet minute.'
                          : 'Up next: ${steps.first.label}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(slot == 'morning' ? 'Set the shape of the morning.' : 'Close the day in order.'),
        if (steps.isEmpty)
          const SoftCard(child: Text('No steps yet. Add a habit or a custom line.')),
        for (var i = 0; i < steps.length; i++)
          SoftCard(
            child: Row(
              children: [
                Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(width: 12),
                Expanded(child: Text(steps[i].label)),
                IconButton(
                  onPressed: () => state.moveStep(slot, i, -1),
                  icon: const Icon(Icons.arrow_upward),
                ),
                IconButton(
                  onPressed: () => state.moveStep(slot, i, 1),
                  icon: const Icon(Icons.arrow_downward),
                ),
                IconButton(
                  onPressed: () => state.removeStep(slot, steps[i].id),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
      ],
      bottom: [
        OutlinedButton.icon(
          onPressed: () => _add(context, slot),
          icon: const Icon(Icons.add),
          label: const Text('Add a step'),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: steps.isEmpty
              ? null
              : () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RoutineRunPage(slot: slot)),
                  ),
          child: const Text('Run this routine'),
        ),
      ],
    );
  }

  Future<void> _add(BuildContext context, String slot) async {
    final state = context.read<AppState>();
    final custom = TextEditingController();
    String? habitId;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add a step'),
        content: StatefulBuilder(
          builder: (context, setLocal) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String?>(
                initialValue: habitId,
                decoration: const InputDecoration(labelText: 'Habit'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Custom step')),
                  for (final habit in state.data.habits)
                    DropdownMenuItem(value: habit.id, child: Text('${habit.glyph} ${habit.name}')),
                ],
                onChanged: (value) => setLocal(() => habitId = value),
              ),
              if (habitId == null) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: custom,
                  decoration: const InputDecoration(labelText: 'Step'),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final habit = state.data.habits.where((h) => h.id == habitId).firstOrNull;
              final label = habit?.name ?? custom.text.trim();
              if (label.isEmpty) return;
              state.addStep(slot, label, habitId: habit?.id);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    custom.dispose();
  }
}

class RoutineRunPage extends StatefulWidget {
  const RoutineRunPage({super.key, required this.slot});

  final String slot;

  @override
  State<RoutineRunPage> createState() => _RoutineRunPageState();
}

class _RoutineRunPageState extends State<RoutineRunPage> {
  int _index = 0;
  final _done = <String>{};

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final steps = state.data.routines.where((r) => r.slot == widget.slot).firstOrNull?.steps ?? [];
    if (steps.isEmpty) {
      return const ClarityPage(title: 'Routine', body: Center(child: Text('This routine is empty.')));
    }
    final step = steps[_index.clamp(0, steps.length - 1)];
    final finished = _done.length == steps.length;
    return ClarityPage(
      title: widget.slot == 'morning' ? 'Morning run' : 'Evening run',
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Step ${_index + 1} of ${steps.length}', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 12),
            Text(step.label, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            const Spacer(),
            if (finished)
              const Text('Routine complete. The day has a shape.')
            else
              FilledButton(
                onPressed: () {
                  if (step.habitId != null) state.checkIn(step.habitId!);
                  setState(() {
                    _done.add(step.id);
                    if (_index < steps.length - 1) _index += 1;
                  });
                },
                child: Text(_done.contains(step.id) ? 'Next' : 'Mark done'),
              ),
          ],
        ),
      ),
    );
  }
}
