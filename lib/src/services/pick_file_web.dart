import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<String?> pickTextFile() {
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = 'application/json,.json';
  final done = Completer<String?>();
  void finish(String? value) {
    if (!done.isCompleted) done.complete(value);
  }

  input.addEventListener('cancel', ((web.Event _) => finish(null)).toJS);
  input.addEventListener(
    'change',
    ((web.Event _) {
      final file = input.files?.item(0);
      if (file == null) {
        finish(null);
        return;
      }
      final reader = web.FileReader();
      reader.addEventListener('load', ((web.Event _) {
        final result = reader.result;
        if (result.isA<JSString>()) {
          finish((result as JSString).toDart);
        } else {
          finish(null);
        }
      }).toJS);
      reader.addEventListener('error', ((web.Event _) => finish(null)).toJS);
      reader.readAsText(file);
    }).toJS,
  );
  input.click();
  return done.future;
}
