import 'dart:convert';
import 'dart:typed_data';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/app_data.dart';
import 'store.dart';

class HiveStore implements ClarityStore {
  HiveStore(this._data, this._images);

  final Box<dynamic> _data;
  final Box<dynamic> _images;

  static Future<HiveStore> open() async {
    await Hive.initFlutter();
    final data = await Hive.openBox<dynamic>('clarity_data');
    final images = await Hive.openBox<dynamic>('clarity_images');
    return HiveStore(data, images);
  }

  @override
  Future<AppData?> load() async {
    final raw = _data.get('state');
    if (raw is! String) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return AppData.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(AppData data) async {
    await _data.put('state', jsonEncode(data.toJson()));
  }

  @override
  Future<void> saveImage(String id, Uint8List bytes) async {
    await _images.put(id, bytes);
  }

  @override
  Future<Uint8List?> loadImage(String id) async {
    final value = _images.get(id);
    if (value is Uint8List) return value;
    if (value is List<int>) return Uint8List.fromList(value);
    return null;
  }
}
