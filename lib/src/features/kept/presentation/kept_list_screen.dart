import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:picme/l10n/app_localizations.dart';
import 'package:picme/src/core/models/media_item.dart';

/// A screen for browsing and individually managing kept (right-swiped) items.
/// Removing an item here puts it back into the swipe deck on next category load.
class KeptListScreen extends StatefulWidget {
  const KeptListScreen({
    super.key,
    required this.initialItems,
    required this.onUnkeep,
  });

  final List<MediaItem> initialItems;
  final Future<void> Function(MediaItem item) onUnkeep;

  @override
  State<KeptListScreen> createState() => _KeptListScreenState();
}

class _KeptListScreenState extends State<KeptListScreen> {
  late List<MediaItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List<MediaItem>.from(widget.initialItems);
  }

  Future<void> _handleUnkeep(MediaItem item) async {
    setState(() {
      _items.removeWhere((m) => m.id == item.id);
    });
    await widget.onUnkeep(item);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.keptListTitle(_items.length))),
      body: _items.isEmpty
          ? Center(child: Text(l10n.keptListEmpty))
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => _KeptPreviewScreen(item: item),
                      ),
                    );
                  },
                  child: _KeptTile(
                    item: item,
                    unkeepTooltip: l10n.unkeepTooltip,
                    onUnkeep: () => _handleUnkeep(item),
                  ),
                );
              },
            ),
    );
  }
}

class _KeptPreviewScreen extends StatelessWidget {
  const _KeptPreviewScreen({required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: InteractiveViewer(
              maxScale: 4,
              child: Image(
                image: AssetEntityImageProvider(item.asset, isOriginal: true),
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.broken_image_outlined, size: 80),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KeptTile extends StatelessWidget {
  const _KeptTile({
    required this.item,
    required this.unkeepTooltip,
    required this.onUnkeep,
  });

  final MediaItem item;
  final String unkeepTooltip;
  final VoidCallback onUnkeep;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: const Color(0xFF1A1D28),
            child: Image(
              image: AssetEntityImageProvider(
                item.asset,
                isOriginal: false,
                thumbnailSize: const ThumbnailSize.square(300),
              ),
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => Center(
                child: Icon(
                  item.type == MediaType.video
                      ? Icons.videocam_outlined
                      : Icons.photo_outlined,
                  color: Colors.white60,
                ),
              ),
            ),
          ),
          if (item.type == MediaType.video)
            const Center(
              child: Icon(
                Icons.play_circle_outline_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          const Positioned(
            top: 4,
            left: 4,
            child: Icon(
              Icons.favorite_rounded,
              size: 16,
              color: Colors.white,
              shadows: [
                Shadow(color: Colors.black54, blurRadius: 4),
              ],
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onUnkeep,
                child: Tooltip(
                  message: unkeepTooltip,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
