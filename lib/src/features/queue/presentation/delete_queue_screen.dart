import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:picme/l10n/app_localizations.dart';
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

  int get _totalBytes =>
      queue.fold(0, (sum, item) => sum + (item.fileSizeInBytes ?? 0));

  String _formatMb(int bytes) =>
      (bytes / (1024 * 1024)).toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final totalBytes = _totalBytes;
    final hasSizeInfo = queue.any((i) => i.fileSizeInBytes != null);

    return Stack(
      children: [
        Column(
          children: [
            _QueueHeader(
              title: l10n.reviewQueueTitle(queue.length),
              subtitle: hasSizeInfo && totalBytes > 0
                  ? l10n.queueSummary(queue.length, _formatMb(totalBytes))
                  : null,
              onClose: onClose,
            ),
            Expanded(
              child: queue.isEmpty
                  ? _EmptyQueue(message: l10n.queueEmpty)
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                      physics: const ClampingScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: queue.length,
                      itemBuilder: (context, index) {
                        final item = queue[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    _QueuePreviewScreen(item: item),
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
        if (queue.isNotEmpty)
          Positioned(
            left: 20,
            right: 20,
            bottom: 22,
            child: _ConfirmDeleteButton(
              label: hasSizeInfo && totalBytes > 0
                  ? l10n.deleteItemsButtonWithSize(
                      queue.length,
                      _formatMb(totalBytes),
                    )
                  : l10n.deleteItemsButton(queue.length),
              onTap: () =>
                  _confirmAndDelete(context, queue.length, totalBytes),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    int itemCount,
    int totalBytes,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final hasSizeInfo = totalBytes > 0;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(l10n.confirmDeleteTitle),
        content: Text(
          hasSizeInfo
              ? l10n.confirmDeleteBodyWithSize(
                  itemCount,
                  _formatMb(totalBytes),
                )
              : l10n.confirmDeleteBody(itemCount),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD45D6E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await onConfirmDelete();
    }
  }
}

class _QueueHeader extends StatelessWidget {
  const _QueueHeader({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      child: Row(
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.7),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onClose,
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: Color(0xFF1F1F1F),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF8A8A8A),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              size: 32,
              color: Color(0xFF8A8A8A),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8A8A8A),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmDeleteButton extends StatelessWidget {
  const _ConfirmDeleteButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFD45D6E),
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD45D6E).withValues(alpha: 0.32),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.delete_sweep_rounded,
                size: 20,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      borderRadius: BorderRadius.circular(14),
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
            top: 6,
            right: 6,
            child: Material(
              color: Colors.black.withValues(alpha: 0.55),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(5),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
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
