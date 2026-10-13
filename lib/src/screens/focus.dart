import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../widgets/board.dart';
import '../widgets/common.dart';
import 'games.dart';

class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {
  Timer? _timer;
  int _remaining = 0;
  bool _running = false;
  bool _break = false;
  int _activeMinutes = 25;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining <= 1) {
        _timer?.cancel();
        setState(() {
          _running = false;
          _remaining = 0;
        });
        if (_break) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Break finished.')));
          setState(() => _break = false);
        } else {
          final levels = context.read<AppState>().completeFocus(_activeMinutes);
          _offerAfter(levels);
        }
      } else {
        setState(() => _remaining -= 1);
      }
    });
  }

  Future<void> _offerAfter(int levels) async {
    if (!mounted) return;
    final rest = context.read<AppState>().data.profile.focusBreakMinutes;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Focus bout cleared'),
        content: Text('You earned XP for $_activeMinutes minutes.${levels > 0 ? ' Level up.' : ''}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openGame(context, 'tidebreath', 1);
            },
            child: const Text('Tide breath'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _break = true;
                _remaining = rest * 60;
                _running = true;
              });
              _tick();
            },
            child: Text('$rest min break'),
          ),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final work = state.data.profile.focusWorkMinutes;
    final rest = state.data.profile.focusBreakMinutes;
    final shown = _running || _remaining > 0 ? _remaining : work * 60;
    final minutes = (shown ~/ 60).toString().padLeft(2, '0');
    final seconds = (shown % 60).toString().padLeft(2, '0');
    final total = (_break ? rest : work) * 60;
    final progress = total == 0 ? 0.0 : (shown / total).clamp(0.0, 1.0);
    return FillPage(
      top: [
        const SectionLabel('Focus timer'),
        const Text('A timed work bout, then a short break. Finished bouts earn XP.'),
        const SizedBox(height: 12),
        Center(
          child: ProgressRing(
            progress: progress,
            label: '$minutes:$seconds',
            caption: _break ? 'break' : 'work',
            size: 210,
            labelSize: 36,
            color: const Color(0xFF0F766E),
            track: const Color(0x330F766E),
            labelColor: const Color(0xFF134E4A),
            captionColor: const Color(0xFF57534E),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final choice in [10, 15, 25, 45, 60])
              ChoiceChip(
                label: Text('$choice min'),
                selected: work == choice && !_running,
                onSelected: _running
                    ? null
                    : (_) => state.setFocusLengths(choice, rest),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Break'),
            const SizedBox(width: 8),
            for (final choice in [3, 5, 10])
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text('$choice'),
                  selected: rest == choice,
                  onSelected: _running ? null : (_) => state.setFocusLengths(work, choice),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () {
                  if (_running) {
                    _timer?.cancel();
                    setState(() => _running = false);
                    return;
                  }
                  setState(() {
                    _activeMinutes = work;
                    _remaining = _remaining == 0 ? work * 60 : _remaining;
                    _running = true;
                    _break = false;
                  });
                  _tick();
                },
                child: Text(_running ? 'Pause' : 'Start'),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                _timer?.cancel();
                setState(() {
                  _running = false;
                  _remaining = 0;
                  _break = false;
                });
              },
              child: const Text('Reset'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => openGame(context, 'tidebreath', 1),
          icon: const Icon(Icons.air),
          label: const Text('Tide breath before you start'),
        ),
      ],
      bottom: [
        const SectionLabel('Recent bouts'),
        if (state.data.sessions.isEmpty)
          const SoftCard(child: Text('No finished bouts yet. A cleared bout lands here with its XP.'))
        else
          for (final session in state.data.sessions.take(8))
            SoftCard(child: Text('${session.minutes} min · +${session.xp} XP')),
      ],
    );
  }
}
