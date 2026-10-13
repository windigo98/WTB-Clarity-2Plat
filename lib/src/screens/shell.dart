import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/clarity_theme.dart';
import '../widgets/chrome.dart';
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
    final scene = switch (_index) {
      0 => Scene.beach,
      3 => Scene.arcade,
      4 => Scene.tower,
      _ => Scene.night,
    };
    final sheet = Column(
      children: [
        const Hud(),
        const SizedBox(height: 88),
        Expanded(child: FrostedSheet(child: PageFrame(child: IndexedStack(index: _index, children: pages)))),
        const CopyrightFooter(onArt: true),
      ],
    );
    final stage = SceneBackdrop(scene: scene, child: SafeArea(child: sheet));
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: const Color(0xF0121C22),
              selectedIndex: _index,
              onDestinationSelected: (value) => setState(() => _index = value),
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  child: Image(image: AssetImage('assets/art/logo.jpg'), width: 56, height: 56, fit: BoxFit.cover),
                ),
              ),
              selectedIconTheme: const IconThemeData(color: Color(0xFFFFE7A3)),
              unselectedIconTheme: const IconThemeData(color: Color(0xFFD7EDE8)),
              selectedLabelTextStyle: const TextStyle(color: Color(0xFFFFE7A3), fontWeight: FontWeight.w800, fontSize: 12),
              unselectedLabelTextStyle: const TextStyle(color: Color(0xFFD7EDE8), fontSize: 12),
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.wb_sunny_outlined), selectedIcon: Icon(Icons.wb_sunny), label: Text('Today')),
                NavigationRailDestination(icon: Icon(Icons.checklist), label: Text('Routines')),
                NavigationRailDestination(icon: Icon(Icons.timer_outlined), selectedIcon: Icon(Icons.timer), label: Text('Focus')),
                NavigationRailDestination(icon: Icon(Icons.sports_esports_outlined), selectedIcon: Icon(Icons.sports_esports), label: Text('Arcade')),
                NavigationRailDestination(icon: Icon(Icons.castle_outlined), selectedIcon: Icon(Icons.castle), label: Text('Keep')),
              ],
            ),
            Expanded(child: stage),
          ],
        ),
      );
    }
    return Scaffold(
      body: stage,
      bottomNavigationBar: GameDock(index: _index, onSelect: (value) => setState(() => _index = value)),
    );
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
      body: SceneBackdrop(
        scene: Scene.beach,
        child: SafeArea(
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
            const CopyrightFooter(onArt: true),
          ],
        ),
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
          if (title.startsWith('WTB')) const Center(child: WingsCrewLogo(height: 96)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xEEFFF8EF),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE7C98A), width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 12),
                Text(body, style: Theme.of(context).textTheme.titleMedium),
                if (extra != null) ...[const SizedBox(height: 20), extra!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const habitGlyphs = ['💧', '📖', '🚶', '🧘', '🥗', '💤', '✍️', '🎵', '🧹', '💪', '🌿', '☀️', '🧠'];
