import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/clarity_logic.dart';
import '../models/app_data.dart';
import '../painters/painters.dart';
import '../state/app_state.dart';
import '../theme/clarity_theme.dart';
import 'chrome.dart';

class CopyrightFooter extends StatelessWidget {
  const CopyrightFooter({super.key, this.onArt = false});

  final bool onArt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
      child: Text(
        '© 2026 WingsCrew. All rights reserved.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: onArt ? const Color(0xFFFFF6EA) : const Color(0xFF57534E),
          shadows: onArt ? const [Shadow(color: Color(0xAA000000), blurRadius: 6)] : null,
        ),
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
    this.scene = Scene.night,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floating;
  final Scene scene;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(title), actions: actions),
      floatingActionButton: floating,
      body: SceneBackdrop(
        scene: scene,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 120),
                child: FrostedSheet(child: PageFrame(child: body)),
              ),
            ),
            const CopyrightFooter(onArt: true),
          ],
        ),
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
    final asset = avatarAsset(id);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFFE7A3), width: 2),
        boxShadow: const [BoxShadow(color: Color(0x660F766E), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: ClipOval(
        child: asset == null
            ? CustomPaint(size: Size.square(size), painter: AvatarPainter(id))
            : Image.asset(asset, fit: BoxFit.cover),
      ),
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
    final card = Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7C98A), width: 1.6),
        boxShadow: const [
          BoxShadow(color: Color(0x33064E3B), offset: Offset(0, 5), blurRadius: 0),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: Color(0xFF1C1917), fontFamily: 'Nunito'),
          child: IconTheme.merge(
            data: const IconThemeData(color: Color(0xFF134E4A)),
            child: child,
          ),
        ),
      ),
    );
    if (onTap == null) return card;
    return _Pressable(onTap: onTap!, child: card);
  }
}

class _Pressable extends StatefulWidget {
  const _Pressable({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.98),
      onTapUp: (_) => setState(() => _scale = 1),
      onTapCancel: () => setState(() => _scale = 1),
      onTap: widget.onTap,
      child: AnimatedScale(scale: _scale, duration: const Duration(milliseconds: 90), child: widget.child),
    );
  }
}

class Hud extends StatelessWidget {
  const Hud({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final progress = state.xpNeed == 0 ? 0.0 : state.xpInto / state.xpNeed;
    const cream = Color(0xFFFFF6EA);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AvatarBadge(id: state.data.profile.avatarId, size: 52),
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6A317),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: cream, width: 1.4),
                    boxShadow: const [BoxShadow(color: Color(0xAAE6A317), blurRadius: 8)],
                  ),
                  child: Text(
                    '${state.level}',
                    style: const TextStyle(fontFamily: 'Cinzel', fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF1C1917)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.data.profile.name,
                  style: const TextStyle(fontFamily: 'Cinzel', fontWeight: FontWeight.w700, color: cream, fontSize: 16, shadows: [Shadow(color: Color(0xAA000000), blurRadius: 6)]),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0x66121C22),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: const Color(0xFFFFE7A3)),
                    boxShadow: const [BoxShadow(color: Color(0xAA1FA7A0), blurRadius: 8)],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progress.clamp(0, 1),
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Color(0xFF5EEAD4), Color(0xFFE6A317)]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  '${state.title} · ${state.xpInto}/${state.xpNeed} XP',
                  style: const TextStyle(color: cream, fontSize: 12, fontWeight: FontWeight.w700, shadows: [Shadow(color: Color(0xAA000000), blurRadius: 4)]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CountingText(
                value: state.data.profile.clarity,
                suffix: ' Clarity',
                style: const TextStyle(fontFamily: 'Cinzel', fontWeight: FontWeight.w700, color: Color(0xFFFFE7A3), shadows: [Shadow(color: Color(0xAA000000), blurRadius: 6)]),
              ),
              Text(
                'Streak ${state.accountStreak}',
                style: const TextStyle(color: cream, fontSize: 12, fontWeight: FontWeight.w800),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: glow, width: 2),
        boxShadow: [BoxShadow(color: glow.withValues(alpha: 0.55), blurRadius: 8)],
      ),
      child: ClipRRect(
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
  ConfettiBurst.show(context);
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
  ConfettiBurst.show(context);
  final drop = reward.drop;
  final name = rarityName(drop.rarity);
  final color = rarityColor(name);
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(drop.duplicate ? 'Duplicate piece' : '$name piece'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 180,
            height: 180,
            child: RarityFrame(
              name: name,
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
  ConfettiBurst.show(context);
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
