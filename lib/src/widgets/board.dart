import 'dart:math';

import 'package:flutter/material.dart';

import '../logic/clarity_logic.dart';

/// Scrolls when needed, and stretches to the sheet when the list is short.
class FillPage extends StatelessWidget {
  const FillPage({super.key, required this.top, required this.bottom});

  final List<Widget> top;
  final List<Widget> bottom;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minHeight = max(0.0, constraints.maxHeight - 28);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: top),
                Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: bottom),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 2),
      child: Text(
        text,
        style: const TextStyle(fontFamily: 'Cinzel', fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF134E4A)),
      ),
    );
  }
}

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    required this.label,
    this.caption,
    this.size = 92,
    this.color = const Color(0xFFFFE7A3),
    this.track = const Color(0x44FFFFFF),
    this.labelColor = const Color(0xFFFFF6EA),
    this.captionColor = const Color(0xFFD7EDE8),
    this.labelSize = 18,
  });

  final double progress;
  final String label;
  final String? caption;
  final double size;
  final Color color;
  final Color track;
  final Color labelColor;
  final Color captionColor;
  final double labelSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(progress.clamp(0, 1), color, track),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(fontFamily: 'Cinzel', fontWeight: FontWeight.w700, fontSize: labelSize, color: labelColor, height: 1),
              ),
              if (caption != null)
                Text(caption!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: captionColor)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress, this.color, this.track);

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = max(8.0, size.width * 0.09);
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = track;
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawArc(rect, -pi / 2, pi * 2, false, trackPaint);
    if (progress <= 0) return;
    canvas.drawArc(rect, -pi / 2, pi * 2 * progress, false, glow);
    canvas.drawArc(
      rect,
      -pi / 2,
      pi * 2 * progress,
      false,
      glow..maskFilter = null,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color || oldDelegate.track != track;
}

class BannerCard extends StatelessWidget {
  const BannerCard({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF115E59), Color(0xFF0F766E), Color(0xFF1F6B4A)],
        ),
        border: Border.all(color: const Color(0xFFFFE7A3), width: 1.6),
        boxShadow: const [BoxShadow(color: Color(0x66064E3B), offset: Offset(0, 5), blurRadius: 0)],
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Color(0xFFFFF8EF), fontFamily: 'Nunito'),
        child: IconTheme.merge(
          data: const IconThemeData(color: Color(0xFFFFE7A3)),
          child: child,
        ),
      ),
    );
    if (onTap == null) return card;
    return _BannerPress(onTap: onTap!, child: card);
  }
}

class _BannerPress extends StatefulWidget {
  const _BannerPress({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_BannerPress> createState() => _BannerPressState();
}

class _BannerPressState extends State<_BannerPress> {
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

class TideChip extends StatelessWidget {
  const TideChip(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6, top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0x33FFF6EA),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0x66FFE7A3)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFFFF6EA))),
    );
  }
}

String tideGreeting(int hour) {
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

String featuredArcadeId(DateTime day) => arcadeGameIds[dateSeed(day) % arcadeGameIds.length];

String nextRoutineSlot(DateTime now) => now.hour < 15 ? 'morning' : 'evening';

int nextOpenLevel({
  required int count,
  required bool Function(int level) unlocked,
  required int Function(int level) stars,
}) {
  for (var level = 1; level <= count; level++) {
    if (!unlocked(level)) break;
    if (stars(level) == 0) return level;
  }
  return 1;
}
