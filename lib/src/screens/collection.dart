import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/clarity_logic.dart';
import '../state/app_state.dart';
import '../theme/clarity_theme.dart';
import '../widgets/common.dart';

class CollectionPage extends StatelessWidget {
  const CollectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return ClarityPage(
      title: 'Picture albums',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Win a memory game and a random piece drops. Duplicates melt into Clarity. A finished picture hangs in the Memory Tower.'),
          for (final picture in pictures)
            _Album(picture: picture, owned: state.data.pieces[picture.id] ?? const []),
        ],
      ),
    );
  }
}

class _Album extends StatelessWidget {
  const _Album({required this.picture, required this.owned});

  final PictureDef picture;
  final List<int> owned;

  @override
  Widget build(BuildContext context) {
    final color = rarityColor(rarityName(picture.rarity));
    final have = owned.toSet();
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(picture.title, style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 8)],
                ),
                child: Text(rarityName(picture.rarity), style: TextStyle(color: color, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          Text(picture.blurb),
          Text('${have.length}/${picture.pieceCount} pieces'),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: picture.cols,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: picture.pieceCount,
            itemBuilder: (context, index) => PicturePiece(
              asset: picture.asset,
              cols: picture.cols,
              rows: picture.rows,
              index: index,
              owned: have.contains(index),
              glow: color,
            ),
          ),
        ],
      ),
    );
  }
}
