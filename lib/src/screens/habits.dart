import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../widgets/common.dart';
import 'shell.dart';

class HabitEditor extends StatefulWidget {
  const HabitEditor({super.key, this.habitId});

  final String? habitId;

  @override
  State<HabitEditor> createState() => _HabitEditorState();
}

class _HabitEditorState extends State<HabitEditor> {
  late final TextEditingController _name;
  String _glyph = '💧';
  final _days = <int>{};
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    final state = context.read<AppState>();
    final habit = state.data.habits.where((h) => h.id == widget.habitId).firstOrNull;
    _name = TextEditingController(text: habit?.name ?? '');
    _glyph = habit?.glyph ?? '💧';
    _days.addAll(habit?.weekdays ?? const []);
    _ready = true;
  }

  @override
  void dispose() {
    if (_ready) _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final editing = widget.habitId != null;
    return ClarityPage(
      title: editing ? 'Edit habit' : 'New habit',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Habit name'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final glyph in habitGlyphs)
                ChoiceChip(
                  label: Text(glyph),
                  selected: _glyph == glyph,
                  onSelected: (_) => setState(() => _glyph = glyph),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Schedule', style: TextStyle(fontWeight: FontWeight.w800)),
          const Text('Leave every day clear to repeat daily.'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (var day = 1; day <= 7; day++)
                FilterChip(
                  label: Text(const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day - 1]),
                  selected: _days.contains(day),
                  onSelected: (selected) => setState(() {
                    if (selected) {
                      _days.add(day);
                    } else {
                      _days.remove(day);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              final state = context.read<AppState>();
              final name = _name.text.trim();
              if (name.isEmpty) return;
              if (editing) {
                state.updateHabit(widget.habitId!, name, _glyph, _days.toList());
              } else {
                state.addHabit(name, _glyph, _days.toList());
              }
              Navigator.pop(context);
            },
            child: Text(editing ? 'Save habit' : 'Add habit'),
          ),
          if (editing)
            TextButton(
              onPressed: () {
                context.read<AppState>().deleteHabit(widget.habitId!);
                Navigator.pop(context);
              },
              child: const Text('Delete habit'),
            ),
        ],
      ),
    );
  }
}
