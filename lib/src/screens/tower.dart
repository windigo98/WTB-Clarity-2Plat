import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../logic/clarity_logic.dart';
import '../state/app_state.dart';
import '../theme/clarity_theme.dart';
import '../widgets/common.dart';

class TowerPage extends StatelessWidget {
  const TowerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final entries = state.data.tower.reversed.toList();
    return ClarityPage(
      title: 'Memory Tower',
      scene: Scene.tower,
      floating: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Add a memory'),
      ),
      body: entries.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Your tower is a ring of stones waiting for the first memory. Photos stay on this device. Sharing with a crew comes later.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final height = entries.length - index;
                if (entry.kind == 'picture' && entry.pictureId != null) {
                  final picture = pictureById(entry.pictureId!);
                  return SoftCard(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _PictureFloor(pictureId: picture.id, caption: entry.caption),
                      ),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(picture.asset, width: 72, height: 72, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Floor $height · display', style: const TextStyle(fontWeight: FontWeight.w800)),
                              Text(picture.title),
                              Text(rarityName(picture.rarity)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final bytes = entry.imageId == null ? null : state.images[entry.imageId!];
                return SoftCard(
                  onTap: bytes == null
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _MemoryView(
                                bytes: bytes,
                                caption: entry.caption,
                                floor: height,
                              ),
                            ),
                          ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 72,
                          height: 72,
                          child: bytes == null
                              ? const ColoredBox(color: Color(0xFFE7E0D6), child: Icon(Icons.photo))
                              : Image.memory(bytes, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Floor $height', style: const TextStyle(fontWeight: FontWeight.w800)),
                            Text(entry.caption.isEmpty ? 'No caption' : entry.caption),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> _add(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Upload a photo'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !context.mounted) return;
    Uint8List? bytes;
    try {
      final file = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 85);
      if (file != null) bytes = await file.readAsBytes();
    } catch (_) {
      bytes = null;
    }
    if (!context.mounted || bytes == null) return;
    final caption = TextEditingController();
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Caption'),
        content: TextField(
          controller: caption,
          decoration: const InputDecoration(labelText: 'Optional caption'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add floor')),
        ],
      ),
    );
    if (save != true || !context.mounted) {
      caption.dispose();
      return;
    }
    final error = await context.read<AppState>().addMemory(bytes, caption.text);
    caption.dispose();
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }
}

class _MemoryView extends StatelessWidget {
  const _MemoryView({required this.bytes, required this.caption, required this.floor});

  final Uint8List bytes;
  final String caption;
  final int floor;

  @override
  Widget build(BuildContext context) {
    return ClarityPage(
      title: 'Floor $floor',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.memory(bytes),
          ),
          const SizedBox(height: 12),
          Text(caption.isEmpty ? 'No caption' : caption, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _PictureFloor extends StatelessWidget {
  const _PictureFloor({required this.pictureId, required this.caption});

  final String pictureId;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final picture = pictureById(pictureId);
    return ClarityPage(
      title: caption,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(picture.asset),
          ),
          const SizedBox(height: 12),
          Text(picture.blurb),
          Text('${rarityName(picture.rarity)} display floor. This one stays.'),
        ],
      ),
    );
  }
}
