import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../widgets/common.dart';
import 'arcade.dart';
import 'focus.dart';
import 'keep.dart';
import 'routines.dart';
import 'today.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;

  static const _titles = ['Today', 'Routines', 'Focus', 'Arcade', 'Keep'];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final pages = const [
      TodayPage(),
      RoutinesPage(),
      FocusPage(),
      ArcadePage(),
      KeepPage(),
    ];
    final body = Column(
      children: [
        const Hud(),
        Expanded(child: PageFrame(child: IndexedStack(index: _index, children: pages))),
        const CopyrightFooter(),
      ],
    );
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (value) => setState(() => _index = value),
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Clarity', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.wb_sunny_outlined), selectedIcon: Icon(Icons.wb_sunny), label: Text('Today')),
                NavigationRailDestination(icon: Icon(Icons.checklist), label: Text('Routines')),
                NavigationRailDestination(icon: Icon(Icons.timer_outlined), selectedIcon: Icon(Icons.timer), label: Text('Focus')),
                NavigationRailDestination(icon: Icon(Icons.sports_esports_outlined), selectedIcon: Icon(Icons.sports_esports), label: Text('Arcade')),
                NavigationRailDestination(icon: Icon(Icons.castle_outlined), selectedIcon: Icon(Icons.castle), label: Text('Keep')),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }
    return Scaffold(
      body: SafeArea(child: body),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          for (var i = 0; i < _titles.length; i++)
            NavigationDestination(
              icon: Icon(_icon(i, false)),
              selectedIcon: Icon(_icon(i, true)),
              label: _titles[i],
            ),
        ],
      ),
    );
  }

  IconData _icon(int index, bool selected) {
    return switch (index) {
      0 => selected ? Icons.wb_sunny : Icons.wb_sunny_outlined,
      1 => Icons.checklist,
      2 => selected ? Icons.timer : Icons.timer_outlined,
      3 => selected ? Icons.sports_esports : Icons.sports_esports_outlined,
      _ => selected ? Icons.castle : Icons.castle_outlined,
    };
  }
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _page = PageController();
  final _name = TextEditingController();
  final _habit = TextEditingController(text: 'Drink water');
  String _glyph = '💧';
  int _index = 0;

  @override
  void dispose() {
    _page.dispose();
    _name.dispose();
    _habit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _page,
                onPageChanged: (value) => setState(() => _index = value),
                children: [
                  const _Pitch(
                    title: 'WTB Clarity 2plat',
                    body:
                        'A habit game from WingsCrew. Check in, keep a streak, earn XP, and climb levels. The name nods to old trade-chat shorthand. The game is ours.',
                  ),
                  const _Pitch(
                    title: 'Build the day',
                    body:
                        'Run a morning and evening routine, sit a focus timer, and spend Clarity on a sandcastle. Win memory games to collect fantasy pictures for your tower.',
                  ),
                  _Pitch(
                    title: 'Name your traveler',
                    body: 'Pick a first habit. You can add more once you are on the beach.',
                    extra: Column(
                      children: [
                        TextField(
                          controller: _name,
                          decoration: const InputDecoration(labelText: 'What should we call you?'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _habit,
                          decoration: const InputDecoration(labelText: 'First habit'),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.circle, size: 8, color: i == _index ? Theme.of(context).colorScheme.primary : Colors.grey),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: () {
                  if (_index < 2) {
                    _page.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
                    return;
                  }
                  context.read<AppState>().finishOnboarding(
                    name: _name.text,
                    habitName: _habit.text,
                    glyph: _glyph,
                  );
                },
                child: Text(_index < 2 ? 'Next' : 'Step onto the sand'),
              ),
            ),
            const CopyrightFooter(),
          ],
        ),
      ),
    );
  }
}

class _Pitch extends StatelessWidget {
  const _Pitch({required this.title, required this.body, this.extra});

  final String title;
  final String body;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text(body, style: Theme.of(context).textTheme.titleMedium),
          if (extra != null) ...[const SizedBox(height: 20), extra!],
        ],
      ),
    );
  }
}

const habitGlyphs = ['💧', '📖', '🚶', '🧘', '🥗', '💤', '✍️', '🎵', '🧹', '💪', '🌿', '☀️', '🧠'];
