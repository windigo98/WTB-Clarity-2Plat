import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/clarity_logic.dart';
import '../models/app_data.dart';
import '../painters/painters.dart';
import '../state/app_state.dart';
import '../theme/clarity_theme.dart';

class CopyrightFooter extends StatelessWidget {
  const CopyrightFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(12, 4, 12, 6),
      child: Text(
        '© 2026 WingsCrew. All rights reserved.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class PageFrame extends StatelessWidget {
  const PageFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880),
        child: child,
      ),
    );
  }
}

class ClarityPage extends StatelessWidget {
  const ClarityPage({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floating,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floating;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      floatingActionButton: floating,
      body: Column(
        children: [
          Expanded(child: PageFrame(child: body)),
          const CopyrightFooter(),
        ],
      ),
    );
  }
}

class AvatarBadge extends StatelessWidget {
  const AvatarBadge({super.key, required this.id, this.size = 44});

  final String id;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: CustomPaint(size: Size.square(size), painter: AvatarPainter(id)),
    );
  }
}

class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.stars, this.size = 16});

  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Icon(
            i < stars ? Icons.star : Icons.star_border,
            size: size,
            color: const Color(0xFFE6A317),
          ),
      ],
    );
  }
}

class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child, this.onTap, this.padding});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
    if (onTap == null) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: card,
    );
  }
}

class Hud extends StatelessWidget {
  const Hud({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          AvatarBadge(id: state.data.profile.avatarId),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${state.data.profile.name} · Lv ${state.level}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: state.xpNeed == 0 ? 0 : state.xpInto / state.xpNeed,
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
                ),
                Text(
                  '${state.title} · ${state.xpInto}/${state.xpNeed} XP',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${state.data.profile.clarity} Clarity',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                'Streak ${state.accountStreak}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PicturePiece extends StatelessWidget {
  const PicturePiece({
    super.key,
    required this.asset,
    required this.cols,
    required this.rows,
    required this.index,
    required this.owned,
    required this.glow,
  });

  final String asset;
  final int cols;
  final int rows;
  final int index;
  final bool owned;
  final Color glow;

  @override
  Widget build(BuildContext context) {
    final col = index % cols;
    final row = index ~/ cols;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.fill,
            child: SizedBox(
              width: cols * 100,
              height: rows * 100,
              child: ClipRect(
                child: Align(
                  alignment: Alignment(
                    cols == 1 ? 0 : -1 + (2 * col) / (cols - 1),
                    rows == 1 ? 0 : -1 + (2 * row) / (rows - 1),
                  ),
                  widthFactor: 1 / cols,
                  heightFactor: 1 / rows,
                  child: Image.asset(
                    asset,
                    width: cols * 100,
                    height: rows * 100,
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
          ),
          if (!owned)
            ColoredBox(
              color: const Color(0xCC111111),
              child: Icon(Icons.help_outline, color: glow.withValues(alpha: 0.9)),
            ),
        ],
      ),
    );
  }
}

class BoosterBar extends StatelessWidget {
  const BoosterBar({super.key, required this.ids, required this.onUse});

  final List<String> ids;
  final void Function(String id) onUse;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Wrap(
      spacing: 8,
      children: [
        for (final id in ids)
          ActionChip(
            label: Text('${shopItemById(id)?.name ?? id} · ${state.boosterCount(id)}'),
            onPressed: state.boosterCount(id) > 0 ? () => onUse(id) : null,
          ),
      ],
    );
  }
}

Future<void> showLevelUp(BuildContext context, Reward reward) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Level ${reward.newLevel}'),
      content: Text('You reached ${reward.title}. The banners go up.'),
      actions: [
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Onward')),
      ],
    ),
  );
}

Future<void> showDrop(BuildContext context, Reward reward) {
  final drop = reward.drop;
  final color = rarityColor(rarityName(drop.rarity));
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(drop.duplicate ? 'Duplicate piece' : '${rarityName(drop.rarity)} piece'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.85), blurRadius: 24),
                ],
              ),
              child: PicturePiece(
                asset: drop.picture.asset,
                cols: drop.picture.cols,
                rows: drop.picture.rows,
                index: drop.pieceIndex,
                owned: true,
                glow: color,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            drop.duplicate
                ? '${drop.picture.title} melted into ${drop.clarityAwarded} Clarity.'
                : '${drop.picture.title} · piece ${drop.pieceIndex + 1}',
            textAlign: TextAlign.center,
          ),
          if (reward.albumCompleted)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('The finished picture now hangs in your Memory Tower.'),
            ),
        ],
      ),
      actions: [
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Nice')),
      ],
    ),
  );
}

Future<void> showRewardFlow(BuildContext context, Reward reward) async {
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Clear'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StarRow(stars: reward.stars, size: 28),
          const SizedBox(height: 8),
          Text('+${reward.xp} XP · +${reward.clarity} Clarity'),
        ],
      ),
      actions: [
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Continue')),
      ],
    ),
  );
  if (!context.mounted) return;
  await showDrop(context, reward);
  if (reward.levelsGained > 0 && context.mounted) {
    await showLevelUp(context, reward);
  }
}
