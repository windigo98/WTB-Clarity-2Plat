import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../painters/painters.dart';
import 'photos.dart';

Future<Uint8List> renderCastleSelfie(Uint8List photo, int pieces) async {
  final codec = await ui.instantiateImageCodec(photo);
  final frame = await codec.getNextFrame();
  const width = 900;
  const height = 1200;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  paintImage(
    canvas: canvas,
    rect: const Rect.fromLTWH(0, 0, 900, 1200),
    image: frame.image,
    fit: BoxFit.cover,
    filterQuality: FilterQuality.medium,
  );
  canvas.drawRect(
    const Rect.fromLTWH(0, 620, 900, 580),
    Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 620),
        const Offset(0, 1200),
        [const Color(0x00000000), const Color(0xCC123044)],
      ),
  );
  canvas.save();
  canvas.translate(36, 560);
  SandcastlePainter(pieces: pieces, bob: 0.2, wave: 0).paint(canvas, const Size(828, 600));
  canvas.restore();
  final caption = TextPainter(
    text: const TextSpan(
      text: 'WTB Clarity 2plat',
      style: TextStyle(
        color: Colors.white,
        fontSize: 40,
        fontWeight: FontWeight.w800,
        fontFamily: 'Nunito',
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: 800);
  caption.paint(canvas, const Offset(40, 36));
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  frame.image.dispose();
  image.dispose();
  final png = data!.buffer.asUint8List();
  return shrinkJpeg(png, maxSide: 1200, quality: 86);
}
