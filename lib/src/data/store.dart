import 'dart:typed_data';

import '../models/app_data.dart';

abstract class ClarityStore {
  Future<AppData?> load();
  Future<void> save(AppData data);
  Future<void> saveImage(String id, Uint8List bytes);
  Future<Uint8List?> loadImage(String id);
}

class MemoryStore implements ClarityStore {
  AppData? data;
  final images = <String, Uint8List>{};

  @override
  Future<AppData?> load() async => data;

  @override
  Future<void> save(AppData data) async {
    this.data = data;
  }

  @override
  Future<void> saveImage(String id, Uint8List bytes) async {
    images[id] = bytes;
  }

  @override
  Future<Uint8List?> loadImage(String id) async => images[id];
}
