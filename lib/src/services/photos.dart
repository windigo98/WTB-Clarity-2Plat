import 'dart:typed_data';

import 'package:image/image.dart' as im;

Uint8List shrinkJpeg(Uint8List bytes, {int maxSide = 960, int quality = 82}) {
  final decoded = im.decodeImage(bytes);
  if (decoded == null) return bytes;
  final longest = decoded.width > decoded.height ? decoded.width : decoded.height;
  final next = longest > maxSide
      ? im.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? maxSide : null,
          height: decoded.height > decoded.width ? maxSide : null,
        )
      : decoded;
  return Uint8List.fromList(im.encodeJpg(next, quality: quality));
}
