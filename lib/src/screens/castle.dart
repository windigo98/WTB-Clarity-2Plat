import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../logic/clarity_logic.dart';
import '../painters/painters.dart';
import '../services/composite.dart';
import '../services/download.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class CastlePage extends StatefulWidget {
  const CastlePage({super.key});

  @override
  State<CastlePage> createState() => _CastlePageState();
}

class _CastlePageState extends State<CastlePage> with TickerProviderStateMixin {
  late final AnimationController _bob;
  late final AnimationController _wave;
  bool _washing = false;

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _wave = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
  }

  @override
  void dispose() {
    _bob.dispose();
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pieces = state.data.profile.castlePieces;
    final done = pieces >= SandcastlePlan.pieceCount;
    final nextCost = done ? 0 : SandcastlePlan.cost(pieces);
    return ClarityPage(
      title: 'Sandcastle',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_bob, _wave]),
            builder: (context, _) => ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CustomPaint(
                painter: SandcastlePainter(
                  pieces: pieces,
                  bob: _bob.value,
                  wave: _washing ? _wave.value : 0,
                ),
                child: const SizedBox(height: 280, width: double.infinity),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            done
                ? 'The castle is finished. Take a selfie before the tide comes in.'
                : 'Next: ${SandcastlePlan.names[pieces]} · $nextCost Clarity',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          Text('Castles finished: ${state.data.profile.castlesFinished}. Selfies stay in the gallery.'),
          const SizedBox(height: 8),
          if (!done)
            FilledButton(
              onPressed: () {
                final message = state.buyNextCastlePiece();
                if (message != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                }
              },
              child: Text('Raise the next piece · $nextCost Clarity'),
            )
          else
            FilledButton(
              onPressed: _washing ? null : () => _selfie(state),
              child: const Text('Take a selfie in front of it'),
            ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CastleGalleryPage())),
            child: Text('Gallery · ${state.data.selfies.length}'),
          ),
          const SizedBox(height: 8),
          const Text('Pieces'),
          for (var i = 0; i < SandcastlePlan.pieceCount; i++)
            ListTile(
              dense: true,
              leading: Icon(i < pieces ? Icons.check_circle : Icons.circle_outlined),
              title: Text(SandcastlePlan.names[i]),
              trailing: Text('${SandcastlePlan.cost(i)}'),
            ),
        ],
      ),
    );
  }

  Future<void> _selfie(AppState state) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Use the camera'),
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
    if (source == null || !mounted) return;
    Uint8List? bytes;
    try {
      final file = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 85);
      if (file != null) bytes = await file.readAsBytes();
    } catch (_) {
      bytes = null;
    }
    if (!mounted) return;
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No photo yet. Try the camera, or upload a file.')),
      );
      return;
    }
    final pieces = state.data.profile.castlePieces;
    final before = state.data.selfies.length;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelfiePreviewPage(photo: bytes!, pieces: pieces),
      ),
    );
    if (!mounted) return;
    final current = context.read<AppState>();
    if (current.data.selfies.length <= before) return;
    setState(() => _washing = true);
    await _wave.forward(from: 0);
    if (!mounted) return;
    current.washCastle();
    setState(() => _washing = false);
    _wave.reset();
  }
}

class SelfiePreviewPage extends StatelessWidget {
  const SelfiePreviewPage({super.key, required this.photo, required this.pieces});

  final Uint8List photo;
  final int pieces;

  @override
  Widget build(BuildContext context) {
    return ClarityPage(
      title: 'Selfie',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 420,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(photo, fit: BoxFit.cover),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: CustomPaint(
                      painter: SandcastlePainter(pieces: pieces, bob: 0.2, wave: 0),
                      child: const SizedBox(height: 220, width: double.infinity),
                    ),
                  ),
                  const Positioned(
                    left: 16,
                    top: 16,
                    child: Text(
                      'WTB Clarity 2plat',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () async {
              final state = context.read<AppState>();
              final rendered = await renderCastleSelfie(photo, pieces);
              await state.saveSelfie(rendered);
              await downloadBytes(rendered, 'clarity-sandcastle.jpg', 'image/jpeg');
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saved to your gallery and downloaded. Here comes the tide.')),
              );
            },
            child: const Text('Save and download'),
          ),
        ],
      ),
    );
  }
}

class CastleGalleryPage extends StatelessWidget {
  const CastleGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return ClarityPage(
      title: 'Castle gallery',
      body: state.data.selfies.isEmpty
          ? const Center(child: Text('Finished castles wash away. Selfies stay here.'))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: state.data.selfies.length,
              itemBuilder: (context, index) {
                final selfie = state.data.selfies[index];
                final bytes = state.images[selfie.imageId];
                return InkWell(
                  onTap: bytes == null
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => _SelfieView(bytes: bytes, id: selfie.id)),
                          ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: bytes == null
                        ? const ColoredBox(color: Color(0xFFE7E0D6), child: Icon(Icons.image_not_supported))
                        : Image.memory(bytes, fit: BoxFit.cover),
                  ),
                );
              },
            ),
    );
  }
}

class _SelfieView extends StatelessWidget {
  const _SelfieView({required this.bytes, required this.id});

  final Uint8List bytes;
  final String id;

  @override
  Widget build(BuildContext context) {
    return ClarityPage(
      title: 'Saved selfie',
      actions: [
        IconButton(
          tooltip: 'Download',
          onPressed: () => downloadBytes(bytes, 'clarity-$id.jpg', 'image/jpeg'),
          icon: const Icon(Icons.download),
        ),
      ],
      body: Center(child: Image.memory(bytes)),
    );
  }
}
