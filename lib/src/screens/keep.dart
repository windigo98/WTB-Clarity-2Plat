import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../widgets/common.dart';
import 'castle.dart';
import 'collection.dart';
import 'crew.dart';
import 'settings.dart';
import 'shop.dart';
import 'stats.dart';
import 'tower.dart';

class KeepPage extends StatelessWidget {
  const KeepPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Your keep', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        Text('${state.data.profile.castlePieces} castle pieces · tower ${state.data.tower.length} high'),
        _link(context, 'Sandcastle', 'Spend Clarity, then take a selfie before the tide.', const CastlePage()),
        _link(context, 'Memory Tower', 'Photos you are proud of, plus finished pictures.', const TowerPage()),
        _link(context, 'Picture albums', 'Pieces won from memory games.', const CollectionPage()),
        _link(context, 'Shop', 'Freezes, lives, boosters, and premium looks.', const ShopPage()),
        _link(context, 'Character', 'Level, streaks, and the calendar.', const StatsPage()),
        _link(context, 'Crew', 'Friends arrive in a later voyage.', const CrewPage()),
        _link(context, 'Settings', 'Reminders, export, and about.', const SettingsPage()),
      ],
    );
  }

  Widget _link(BuildContext context, String title, String body, Widget page) {
    return SoftCard(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(body),
        ],
      ),
    );
  }
}
