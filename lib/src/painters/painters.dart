import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class SandcastlePainter extends CustomPainter {
  SandcastlePainter({required this.pieces, required this.bob, required this.wave});

  final int pieces;
  final double bob;
  final double wave;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sky = Paint()
      ..shader = ui.Gradient.linear(Offset.zero, Offset(0, h), const [
        Color(0xFF8ED4E8),
        Color(0xFFF7D7A8),
      ]);
    canvas.drawRect(Offset.zero & size, sky);

    final sun = Paint()..color = const Color(0xFFFFE08A);
    canvas.drawCircle(Offset(w * 0.78, h * 0.18), w * 0.08, sun);

    _gull(canvas, Offset(w * (0.18 + bob * 0.04), h * 0.16), w * 0.03);
    _gull(canvas, Offset(w * (0.28 + bob * 0.02), h * 0.22), w * 0.02);

    final seaTop = h * 0.46;
    final sea = Paint()
      ..shader = ui.Gradient.linear(Offset(0, seaTop), Offset(0, h * 0.68), const [
        Color(0xFF2BB3C7),
        Color(0xFF0E7490),
      ]);
    canvas.drawRect(Rect.fromLTWH(0, seaTop, w, h * 0.24), sea);
    final wavePaint = Paint()
      ..color = const Color(0x88FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < 3; i++) {
      final path = Path();
      final y = seaTop + 18 + i * 22;
      path.moveTo(0, y);
      for (var x = 0.0; x <= w; x += 12) {
        path.lineTo(x, y + sin((x / 28) + bob * 6 + i) * 4);
      }
      canvas.drawPath(path, wavePaint);
    }

    final sand = Paint()..color = const Color(0xFFF3D2A2);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.66, w, h * 0.34), sand);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.68), width: w * 1.1, height: h * 0.12),
      Paint()..color = const Color(0xFFF8E0B8),
    );

    final ground = h * 0.78;
    if (pieces >= 8) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(w * 0.5, ground + 8), width: w * 0.72, height: h * 0.08),
        Paint()..color = const Color(0xFF7EC8D6),
      );
    }
    if (pieces >= 1) {
      final mound = Rect.fromCenter(center: Offset(w * 0.5, ground), width: w * 0.62, height: h * 0.16);
      canvas.drawOval(
        mound,
        Paint()
          ..shader = ui.Gradient.linear(
            mound.topCenter,
            mound.bottomCenter,
            const [Color(0xFFFFE1B0), Color(0xFFD0893E)],
          ),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(w * 0.42, ground - h * 0.02), width: w * 0.22, height: h * 0.04),
        Paint()..color = const Color(0x66FFFFFF),
      );
    }
    if (pieces >= 4) {
      final wall = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.5, ground - h * 0.08), width: w * 0.46, height: h * 0.1),
        const Radius.circular(8),
      );
      canvas.drawRRect(wall, Paint()..color = const Color(0xFFF0C98A));
    }
    if (pieces >= 2) _tower(canvas, Offset(w * 0.34, ground - h * 0.02), w * 0.12, h * 0.22);
    if (pieces >= 3) _tower(canvas, Offset(w * 0.66, ground - h * 0.02), w * 0.12, h * 0.22);
    if (pieces >= 10) _tower(canvas, Offset(w * 0.5, ground - h * 0.04), w * 0.14, h * 0.3);
    if (pieces >= 5) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(w * 0.5, ground - h * 0.03), width: w * 0.1, height: h * 0.1),
          const Radius.circular(6),
        ),
        Paint()..color = const Color(0xFF8D5A3B),
      );
    }
    if (pieces >= 6) _flag(canvas, Offset(w * 0.34, ground - h * 0.24), const Color(0xFFE85D4C));
    if (pieces >= 7) _flag(canvas, Offset(w * 0.66, ground - h * 0.24), const Color(0xFF1F8A84));
    if (pieces >= 11) _flag(canvas, Offset(w * 0.5, ground - h * 0.36), const Color(0xFFFFD15C), tall: true);
    if (pieces >= 9) {
      _shell(canvas, Offset(w * 0.22, ground + h * 0.05));
      _shell(canvas, Offset(w * 0.8, ground + h * 0.04));
    }
    if (pieces >= 12) {
      _star(canvas, Offset(w * 0.62, ground + h * 0.08), w * 0.03, const Color(0xFFFF8A5B));
    }

    if (wave > 0) {
      final cover = h * (1.05 - wave * 0.9);
      final wash = Path();
      wash.moveTo(0, h);
      wash.lineTo(0, cover);
      for (var x = 0.0; x <= w; x += 16) {
        wash.lineTo(x, cover + sin((x / 40) + wave * 8) * 14);
      }
      wash.lineTo(w, h);
      wash.close();
      canvas.drawPath(
        wash,
        Paint()..color = Color.lerp(const Color(0xAA1D8CA3), const Color(0xEE0B4F6C), wave)!,
      );
    }
  }

  void _tower(Canvas canvas, Offset base, double width, double height) {
    final rect = Rect.fromCenter(
      center: Offset(base.dx, base.dy - height / 2),
      width: width,
      height: height,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()..color = const Color(0xFFF6D7A4),
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.left - 4, rect.top, rect.width + 8, 10),
      Paint()..color = const Color(0xFFE2B56A),
    );
    canvas.drawCircle(
      Offset(rect.center.dx, rect.center.dy),
      4,
      Paint()..color = const Color(0xFF8D5A3B),
    );
  }

  void _flag(Canvas canvas, Offset poleBase, Color color, {bool tall = false}) {
    final poleTop = poleBase.dy - (tall ? 36 : 28);
    canvas.drawLine(poleBase, Offset(poleBase.dx, poleTop), Paint()..strokeWidth = 2..color = const Color(0xFF6B4A32));
    final path = Path()
      ..moveTo(poleBase.dx, poleTop)
      ..lineTo(poleBase.dx + 22, poleTop + 7)
      ..lineTo(poleBase.dx, poleTop + 14)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _shell(Canvas canvas, Offset c) {
    canvas.drawArc(
      Rect.fromCenter(center: c, width: 16, height: 12),
      pi,
      pi,
      true,
      Paint()..color = const Color(0xFFFFF6EA),
    );
  }

  void _star(Canvas canvas, Offset c, double r, Color color) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? r : r * 0.45;
      final a = -pi / 2 + i * pi / 5;
      final p = Offset(c.dx + cos(a) * radius, c.dy + sin(a) * radius);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _gull(Canvas canvas, Offset c, double s) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - s, c.dy)
        ..quadraticBezierTo(c.dx - s / 2, c.dy - s, c.dx, c.dy)
        ..quadraticBezierTo(c.dx + s / 2, c.dy - s, c.dx + s, c.dy),
      paint,
    );
  }

  @override
  bool shouldRepaint(SandcastlePainter oldDelegate) =>
      oldDelegate.pieces != pieces || oldDelegate.bob != bob || oldDelegate.wave != wave;
}

class GlancePainter extends CustomPainter {
  GlancePainter({required this.showAlts, required this.alts});

  final bool showAlts;
  final Set<int> alts;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7EC8E3), Color(0xFFF6D7A8)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawCircle(Offset(w * 0.8, h * 0.2), w * 0.08, Paint()..color = const Color(0xFFFFE29A));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.3, h * 0.28), width: w * 0.28, height: h * 0.1),
      Paint()..color = const Color(0xCCFFFFFF),
    );
    if (showAlts && alts.contains(3)) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(w * 0.48, h * 0.2), width: w * 0.2, height: h * 0.08),
        Paint()..color = const Color(0xEEFFFFFF),
      );
    }
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.78), width: w, height: h * 0.4),
      Paint()..color = const Color(0xFF69B7A8),
    );
    final tower = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.48, h * 0.52), width: w * 0.18, height: h * 0.34),
      const Radius.circular(4),
    );
    canvas.drawRRect(tower, Paint()..color = const Color(0xFFF3D2A0));
    final window = Paint()
      ..color = showAlts && alts.contains(1) ? const Color(0xFFFFD15C) : const Color(0xFF6B4A32);
    canvas.drawCircle(Offset(w * 0.48, h * 0.48), w * 0.025, window);
    final flag = showAlts && alts.contains(2) ? const Color(0xFF3B82F6) : const Color(0xFFE85D4C);
    final pole = Offset(w * 0.48, h * 0.34);
    canvas.drawLine(pole, Offset(pole.dx, pole.dy - 18), Paint()..strokeWidth = 2..color = const Color(0xFF6B4A32));
    canvas.drawPath(
      Path()
        ..moveTo(pole.dx, pole.dy - 18)
        ..lineTo(pole.dx + 16, pole.dy - 12)
        ..lineTo(pole.dx, pole.dy - 6)
        ..close(),
      Paint()..color = flag,
    );
    _bird(canvas, Offset(w * 0.18, h * 0.22));
    if (showAlts && alts.contains(0)) _bird(canvas, Offset(w * 0.26, h * 0.16));
    if (showAlts && alts.contains(4)) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(w * 0.78, h * 0.7), width: w * 0.16, height: h * 0.05),
        Paint()..color = const Color(0xFF8D5A3B),
      );
    }
  }

  void _bird(Canvas canvas, Offset c) {
    final paint = Paint()
      ..color = const Color(0xFF1C1917)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - 8, c.dy)
        ..quadraticBezierTo(c.dx - 4, c.dy - 6, c.dx, c.dy)
        ..quadraticBezierTo(c.dx + 4, c.dy - 6, c.dx + 8, c.dy),
      paint,
    );
  }

  @override
  bool shouldRepaint(GlancePainter oldDelegate) =>
      oldDelegate.showAlts != showAlts || oldDelegate.alts.length != alts.length;
}

class AvatarPainter extends CustomPainter {
  AvatarPainter(this.id);
  final String id;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    switch (id) {
      case 'avatar_emberfox':
        canvas.drawCircle(c, r, Paint()..color = const Color(0xFFFF8A3D));
        canvas.drawCircle(Offset(c.dx - r * 0.45, c.dy - r * 0.7), r * 0.28, Paint()..color = const Color(0xFFFFB347));
        canvas.drawCircle(Offset(c.dx + r * 0.45, c.dy - r * 0.7), r * 0.28, Paint()..color = const Color(0xFFFFB347));
      case 'avatar_moonmoth':
        canvas.drawCircle(c, r * 0.55, Paint()..color = const Color(0xFFF4E7FF));
        canvas.drawOval(Rect.fromCenter(center: Offset(c.dx - r * 0.55, c.dy), width: r, height: r * 1.3), Paint()..color = const Color(0xFFD7C4FF));
        canvas.drawOval(Rect.fromCenter(center: Offset(c.dx + r * 0.55, c.dy), width: r, height: r * 1.3), Paint()..color = const Color(0xFFD7C4FF));
      case 'avatar_kelpknight':
        canvas.drawCircle(c, r, Paint()..color = const Color(0xFF1F8A70));
        canvas.drawRect(Rect.fromCenter(center: Offset(c.dx, c.dy - r * 0.15), width: r * 1.1, height: r * 0.7), Paint()..color = const Color(0xFF146152));
      case 'avatar_starwren':
        canvas.drawCircle(c, r, Paint()..color = const Color(0xFF243B67));
        final path = Path()
          ..moveTo(c.dx, c.dy - r * 0.2)
          ..lineTo(c.dx + r * 0.45, c.dy + r * 0.15)
          ..lineTo(c.dx, c.dy + r * 0.05)
          ..close();
        canvas.drawPath(path, Paint()..color = const Color(0xFFFFD15C));
      default:
        canvas.drawCircle(c, r, Paint()..color = const Color(0xFF14B8A6));
        canvas.drawArc(
          Rect.fromCircle(center: Offset(c.dx, c.dy + r * 0.15), radius: r * 0.72),
          pi,
          pi,
          true,
          Paint()..color = const Color(0xFF0F766E),
        );
    }
    canvas.drawCircle(Offset(c.dx - r * 0.22, c.dy - r * 0.05), r * 0.08, Paint()..color = const Color(0xFF1C1917));
    canvas.drawCircle(Offset(c.dx + r * 0.22, c.dy - r * 0.05), r * 0.08, Paint()..color = const Color(0xFF1C1917));
  }

  @override
  bool shouldRepaint(AvatarPainter oldDelegate) => oldDelegate.id != id;
}

class CardBackPainter extends CustomPainter {
  CardBackPainter(this.id);
  final String id;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final base = switch (id) {
      'card_constellation' => const Color(0xFF1E2A4A),
      'card_coral' => const Color(0xFFB94B4B),
      'card_rune' => const Color(0xFF245C55),
      _ => const Color(0xFF0F766E),
    };
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(12)),
      Paint()..color = base,
    );
    final paint = Paint()
      ..color = const Color(0x66FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    if (id == 'card_constellation') {
      final rng = Random(4);
      for (var i = 0; i < 18; i++) {
        canvas.drawCircle(
          Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
          1.5,
          Paint()..color = const Color(0xFFFFE7A3),
        );
      }
    } else if (id == 'card_coral') {
      for (var y = 8.0; y < size.height; y += 8) {
        final path = Path()..moveTo(0, y);
        for (var x = 0.0; x <= size.width; x += 8) {
          path.lineTo(x, y + sin(x / 6) * 3);
        }
        canvas.drawPath(path, paint);
      }
    } else if (id == 'card_rune') {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(10), const Radius.circular(8)),
        paint,
      );
      canvas.drawCircle(size.center(Offset.zero), 8, paint);
    } else {
      for (var i = -size.height; i < size.width; i += 10) {
        canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
      }
    }
  }

  @override
  bool shouldRepaint(CardBackPainter oldDelegate) => oldDelegate.id != id;
}

const glanceSpots = <Offset>[
  Offset(0.26, 0.16),
  Offset(0.48, 0.48),
  Offset(0.56, 0.30),
  Offset(0.48, 0.20),
  Offset(0.78, 0.70),
];
