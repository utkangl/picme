import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:picme/src/core/models/media_item.dart';

class DeleteQueueScreen extends StatelessWidget {
  const DeleteQueueScreen({
    super.key,
    required this.queue,
    required this.onRemove,
    required this.onConfirmDelete,
    required this.onClose,
  });

  final List<MediaItem> queue;
  final ValueChanged<MediaItem> onRemove;
  final Future<void> Function() onConfirmDelete;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded),
                  ),
                  Expanded(
                    child: Text(
                      'Review Queue (${queue.length})',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: queue.isEmpty
                  ? const Center(child: Text('Queue is empty.'))
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 130),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 4,
                          ),
                      itemCount: queue.length,
                      itemBuilder: (context, index) {
                        final item = queue[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => _QueuePreviewScreen(item: item),
                              ),
                            );
                          },
                          child: _QueueTile(
                            item: item,
                            onRemove: () => onRemove(item),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 22,
          child: FilledButton.icon(
            onPressed: queue.isEmpty
                ? null
                : () => _confirmAndDelete(context, queue.length),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text('Delete ${queue.length} Items'),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmAndDelete(BuildContext context, int itemCount) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('$itemCount item(s) will be deleted permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await onConfirmDelete();
    }
  }
}

class _QueuePreviewScreen extends StatelessWidget {
  const _QueuePreviewScreen({required this.item});

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

class _QueueTile extends StatelessWidget {
  const _QueueTile({required this.item, required this.onRemove});

  final MediaItem item;
  final VoidCallback onRemove;

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
          Positioned(
            top: 2,
            right: 2,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
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
        ],
      ),
    );
  }
}
