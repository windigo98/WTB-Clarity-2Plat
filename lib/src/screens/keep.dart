import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/clarity_logic.dart';
import '../painters/painters.dart';
import '../state/app_state.dart';
import '../widgets/board.dart';
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
    final pieces = state.data.profile.castlePieces;
    final owned = state.data.pieces.values.fold<int>(0, (sum, list) => sum + list.length);
    final albumTotal = pictures.fold<int>(0, (sum, picture) => sum + picture.cols * picture.rows);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 560;
        final links = [
          _link(context, Icons.beach_access, 'Sandcastle', 'Spend Clarity, then take a selfie before the tide.', const CastlePage()),
          _link(context, Icons.apartment, 'Memory Tower', 'Photos you are proud of, plus finished pictures.', const TowerPage()),
          _link(context, Icons.grid_view, 'Picture albums', 'Pieces won from memory games.', const CollectionPage()),
          _link(context, Icons.storefront, 'Shop', 'Freezes, lives, boosters, and premium looks.', const ShopPage()),
          _link(context, Icons.person, 'Character', 'Level, streaks, and the calendar.', const StatsPage()),
          _link(context, Icons.groups, 'Crew', 'Friends arrive in a later voyage.', const CrewPage()),
          _link(context, Icons.settings, 'Settings', 'Reminders, export, and about.', const SettingsPage()),
        ];
        return FillPage(
          top: [
            BannerCard(
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 108,
                      height: 80,
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
                        const Text('Your keep', style: TextStyle(fontFamily: 'Cinzel', fontWeight: FontWeight.w700, fontSize: 22)),
                        Text('$pieces of ${SandcastlePlan.pieceCount} castle pieces'),
                        Text('Tower ${state.data.tower.length} high · $owned/$albumTotal picture pieces'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          bottom: [
            if (wide)
              Wrap(spacing: 8, runSpacing: 0, children: [for (final link in links) SizedBox(width: (constraints.maxWidth - 48) / 2, child: link)])
            else
              ...links,
          ],
        );
      },
    );
  }

  Widget _link(BuildContext context, IconData icon, String title, String body, Widget page) {
    return SoftCard(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Color(0xFF5EEAD4), Color(0xFF0F766E)]),
            ),
            child: Icon(icon, color: const Color(0xFFFFF8EF), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(body),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
