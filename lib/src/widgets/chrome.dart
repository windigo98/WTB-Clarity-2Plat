import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/clarity_theme.dart';
import 'brand.dart';

class SceneBackdrop extends StatefulWidget {
  const SceneBackdrop({super.key, required this.scene, required this.child});

  final Scene scene;
  final Widget child;

  @override
  State<SceneBackdrop> createState() => _SceneBackdropState();
}

class _SceneBackdropState extends State<SceneBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _drift,
      builder: (context, child) {
        final t = _drift.value;
        return Stack(
          fit: StackFit.expand,
          children: [
            Transform.translate(
              offset: Offset(sin(t * pi * 2) * 10, cos(t * pi * 2) * 6),
              child: Transform.scale(
                scale: 1.08,
                child: Image.asset(sceneAsset(widget.scene), fit: BoxFit.cover),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x220B1C24), Color(0x000B1C24), Color(0x440B1C24)],
                ),
              ),
            ),
            CustomPaint(painter: _AmbientPainter(t), child: const SizedBox.expand()),
            child!,
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _AmbientPainter extends CustomPainter {
  _AmbientPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final spark = Paint()..color = const Color(0xCCFFF6D8);
    final rng = Random(4);
    for (var i = 0; i < 18; i++) {
      final x = rng.nextDouble() * size.width;
      final y = (rng.nextDouble() * size.height + t * 80 + i * 12) % size.height;
      final radius = 1.2 + rng.nextDouble() * 1.8;
      spark.color = Color.fromARGB((140 + (sin(t * pi * 2 + i) * 80).round()), 255, 244, 214);
      canvas.drawCircle(Offset(x, y), radius, spark);
    }
    final cloud = Paint()..color = const Color(0x33FFFFFF);
    final drift = sin(t * pi * 2) * 24;
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.2 + drift, 36), width: 140, height: 28), cloud);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.72 - drift, 58), width: 180, height: 32), cloud);
  }

  @override
  bool shouldRepaint(_AmbientPainter oldDelegate) => oldDelegate.t != t;
}

class FrostedSheet extends StatelessWidget {
  const FrostedSheet({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 6),
      decoration: BoxDecoration(
        color: const Color(0xEEFFF8EF),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF0D7A4), width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x660B1C24), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class WingsCrewLogo extends StatelessWidget {
  const WingsCrewLogo({super.key, this.height = 72});

  final double height;

  @override
  Widget build(BuildContext context) {
    return WingsCrewHomeLink(
      child: Image.asset('assets/art/logo.jpg', height: height, fit: BoxFit.contain),
    );
  }
}

class CountingText extends StatefulWidget {
  const CountingText({super.key, required this.value, required this.style, this.prefix = '', this.suffix = ''});

  final int value;
  final TextStyle? style;
  final String prefix;
  final String suffix;

  @override
  State<CountingText> createState() => _CountingTextState();
}

class _CountingTextState extends State<CountingText> {
  late int _from;

  @override
  void initState() {
    super.initState();
    _from = widget.value;
  }

  @override
  void didUpdateWidget(CountingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    _from = oldWidget.value;
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: _from, end: widget.value),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) => Text('${widget.prefix}$animated${widget.suffix}', style: widget.style),
    );
  }
}

class RarityFrame extends StatefulWidget {
  const RarityFrame({super.key, required this.name, required this.child, this.radius = 18});

  final String name;
  final Widget child;
  final double radius;

  @override
  State<RarityFrame> createState() => _RarityFrameState();
}

class _RarityFrameState extends State<RarityFrame> with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mythic = widget.name == 'Mythic';
    final color = rarityColor(widget.name);
    return AnimatedBuilder(
      animation: _spin,
      builder: (context, child) {
        final glow = mythic
            ? SweepGradient(
                transform: GradientRotation(_spin.value * pi * 2),
                colors: const [
                  Color(0xFFFF4D8D),
                  Color(0xFFE6A317),
                  Color(0xFF3B82F6),
                  Color(0xFF9B5DE5),
                  Color(0xFF2F9E6B),
                  Color(0xFFFF4D8D),
                ],
              )
            : LinearGradient(colors: [color, color.withValues(alpha: 0.45)]);
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: glow,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: mythic ? 0.85 : 0.55), blurRadius: mythic ? 22 : 14),
            ],
          ),
          padding: const EdgeInsets.all(3),
          child: child,
        );
      },
      child: ClipRRect(borderRadius: BorderRadius.circular(widget.radius - 2), child: widget.child),
    );
  }
}

class ConfettiBurst {
  static void show(BuildContext context) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ConfettiLayer(onDone: () => entry.remove()),
    );
    overlay.insert(entry);
  }
}

class _ConfettiLayer extends StatefulWidget {
  const _ConfettiLayer({required this.onDone});

  final VoidCallback onDone;

  @override
  State<_ConfettiLayer> createState() => _ConfettiLayerState();
}

class _ConfettiLayerState extends State<_ConfettiLayer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Bit> _bits;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _bits = [
      for (var i = 0; i < 48; i++)
        _Bit(
          x: rng.nextDouble(),
          hue: rng.nextInt(6),
          drift: rng.nextDouble() * 0.3 - 0.15,
          spin: rng.nextDouble() * 6,
          size: 6 + rng.nextDouble() * 8,
        ),
    ];
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..forward().whenComplete(() {
        if (mounted) widget.onDone();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _ConfettiPainter(_controller.value, _bits),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _Bit {
  const _Bit({required this.x, required this.hue, required this.drift, required this.spin, required this.size});
  final double x;
  final int hue;
  final double drift;
  final double spin;
  final double size;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t, this.bits);
  final double t;
  final List<_Bit> bits;
  static const _colors = [
    Color(0xFF8B95A7),
    Color(0xFF2F9E6B),
    Color(0xFF3B82F6),
    Color(0xFF9B5DE5),
    Color(0xFFE6A317),
    Color(0xFFFF4D8D),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final bit in bits) {
      final y = -20 + t * (size.height + 40);
      final x = bit.x * size.width + sin(t * bit.spin) * 24 + bit.drift * 40;
      final paint = Paint()..color = _colors[bit.hue].withValues(alpha: 1 - t * 0.35);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * bit.spin);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: bit.size, height: bit.size * 0.6), const Radius.circular(2)),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => oldDelegate.t != t;
}

class GameDock extends StatelessWidget {
  const GameDock({super.key, required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.wb_sunny, 'Today'),
      (Icons.checklist_rtl, 'Routines'),
      (Icons.timer, 'Focus'),
      (Icons.sports_esports, 'Arcade'),
      (Icons.castle, 'Keep'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xF0121C22),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFF1FA7A0), width: 1.4),
          boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 16, offset: Offset(0, 6))],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _DockButton(
                    icon: items[i].$1,
                    label: items[i].$2,
                    selected: index == i,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockButton extends StatefulWidget {
  const _DockButton({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_DockButton> createState() => _DockButtonState();
}

class _DockButtonState extends State<_DockButton> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    final color = widget.selected ? const Color(0xFFFFE7A3) : const Color(0xFFD7EDE8);
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.92),
      onTapUp: (_) => setState(() => _scale = 1),
      onTapCancel: () => setState(() => _scale = 1),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 90),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: widget.selected ? const Color(0xFF0F766E) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: widget.selected
                ? const [BoxShadow(color: Color(0x66064E3B), offset: Offset(0, 3), blurRadius: 0)]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: color, size: 22),
              Text(widget.label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}
