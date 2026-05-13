import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:picme/l10n/app_localizations.dart';
import 'package:picme/src/core/models/media_item.dart';
import 'package:picme/src/core/util/bytes_format.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

enum _QueueSort { added, size }

enum _QueueMediaFilter { all, photos, videos }

class DeleteQueueScreen extends StatefulWidget {
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
  State<DeleteQueueScreen> createState() => _DeleteQueueScreenState();
}

class _DeleteQueueScreenState extends State<DeleteQueueScreen> {
  static const String _sortPrefsKey = 'picme_queue_sort';
  static const String _filterPrefsKey = 'picme_queue_media_filter';
  static const String _addedNewestFirstPrefsKey =
      'picme_queue_added_newest_first';

  _QueueSort _sort = _QueueSort.added;
  _QueueMediaFilter _mediaFilter = _QueueMediaFilter.all;
  bool _addedNewestFirst = true;

  @override
  void initState() {
    super.initState();
    unawaited(_restoreControls());
  }

  int get _totalBytes =>
      widget.queue.fold(0, (sum, item) => sum + (item.fileSizeInBytes ?? 0));

  List<MediaItem> get _visibleQueue {
    final filtered = switch (_mediaFilter) {
      _QueueMediaFilter.all => widget.queue,
      _QueueMediaFilter.photos =>
        widget.queue.where((item) => item.type == MediaType.photo).toList(),
      _QueueMediaFilter.videos =>
        widget.queue.where((item) => item.type == MediaType.video).toList(),
    };
    final indexed = filtered.asMap().entries.toList();
    indexed.sort((a, b) {
      final primary = switch (_sort) {
        _QueueSort.added =>
          _addedNewestFirst ? b.key.compareTo(a.key) : a.key.compareTo(b.key),
        _QueueSort.size => _compareBySize(a.value, b.value),
      };
      if (primary != 0) return primary;
      return a.key.compareTo(b.key);
    });
    return indexed.map((entry) => entry.value).toList();
  }

  int _compareBySize(MediaItem a, MediaItem b) {
    final aSize = a.fileSizeInBytes ?? -1;
    final bSize = b.fileSizeInBytes ?? -1;
    return bSize.compareTo(aSize);
  }

  Future<void> _restoreControls() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSort = prefs.getInt(_sortPrefsKey);
    final savedFilter = prefs.getInt(_filterPrefsKey);
    final savedAddedNewestFirst = prefs.getBool(_addedNewestFirstPrefsKey);
    if (!mounted) return;
    setState(() {
      if (savedSort != null &&
          savedSort >= 0 &&
          savedSort < _QueueSort.values.length) {
        _sort = _QueueSort.values[savedSort];
      }
      if (savedFilter != null &&
          savedFilter >= 0 &&
          savedFilter < _QueueMediaFilter.values.length) {
        _mediaFilter = _QueueMediaFilter.values[savedFilter];
      }
      if (savedAddedNewestFirst != null) {
        _addedNewestFirst = savedAddedNewestFirst;
      }
    });
  }

  Future<void> _persistControls() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sortPrefsKey, _sort.index);
    await prefs.setInt(_filterPrefsKey, _mediaFilter.index);
    await prefs.setBool(_addedNewestFirstPrefsKey, _addedNewestFirst);
  }

  void _setSort(_QueueSort sort) {
    setState(() {
      if (sort == _QueueSort.added && _sort == _QueueSort.added) {
        _addedNewestFirst = !_addedNewestFirst;
      } else {
        _sort = sort;
      }
    });
    unawaited(_persistControls());
  }

  void _setFilter(_QueueMediaFilter filter) {
    if (_mediaFilter == filter) return;
    setState(() => _mediaFilter = filter);
    unawaited(_persistControls());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final queue = _visibleQueue;
    final totalBytes = _totalBytes;
    final hasSizeInfo = widget.queue.any((i) => i.fileSizeInBytes != null);
    final photoCount = widget.queue
        .where((item) => item.type == MediaType.photo)
        .length;
    final videoCount = widget.queue
        .where((item) => item.type == MediaType.video)
        .length;
    const stats = <_QueueStat>[];

    return Stack(
      children: [
        Column(
          children: [
            _QueueHeader(
              title: l10n.reviewQueueTitle(widget.queue.length),
              subtitle: hasSizeInfo && totalBytes > 0
                  ? l10n.queueSummary(
                      widget.queue.length,
                      formatBytes(totalBytes),
                    )
                  : null,
              stats: stats,
              selectedSort: _sort,
              selectedFilter: _mediaFilter,
              totalCount: widget.queue.length,
              photoCount: photoCount,
              videoCount: videoCount,
              addedNewestFirst: _addedNewestFirst,
              onSortSelected: _setSort,
              onFilterSelected: _setFilter,
              onClose: widget.onClose,
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
                                builder: (_) => _QueuePreviewScreen(item: item),
                              ),
                            );
                          },
                          child: _QueueTile(
                            item: item,
                            onRemove: () => widget.onRemove(item),
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
                      widget.queue.length,
                      formatBytes(totalBytes),
                    )
                  : l10n.deleteItemsButton(widget.queue.length),
              onTap: () =>
                  _confirmAndDelete(context, widget.queue.length, totalBytes),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.confirmDeleteTitle),
        content: Text(
          hasSizeInfo
              ? l10n.confirmDeleteBodyWithSize(
                  itemCount,
                  formatBytes(totalBytes),
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
      await widget.onConfirmDelete();
    }
  }
}

class _QueueHeader extends StatelessWidget {
  const _QueueHeader({
    required this.title,
    required this.subtitle,
    required this.stats,
    required this.selectedSort,
    required this.selectedFilter,
    required this.totalCount,
    required this.photoCount,
    required this.videoCount,
    required this.addedNewestFirst,
    required this.onSortSelected,
    required this.onFilterSelected,
    required this.onClose,
  });

  final String title;
  final String? subtitle;
  final List<_QueueStat> stats;
  final _QueueSort selectedSort;
  final _QueueMediaFilter selectedFilter;
  final int totalCount;
  final int photoCount;
  final int videoCount;
  final bool addedNewestFirst;
  final ValueChanged<_QueueSort> onSortSelected;
  final ValueChanged<_QueueMediaFilter> onFilterSelected;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Material(
                color: Colors.white.withValues(alpha: 0.72),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onClose,
                  child: const SizedBox(
                    width: 38,
                    height: 38,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 20,
                      color: Color(0xFF1F1F1F),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
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
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF8A8A8A),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (totalCount > 0) ...[
            const SizedBox(height: 12),
            if (stats.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final stat in stats) _QueueStatChip(stat: stat),
                ],
              ),
              const SizedBox(height: 12),
            ],
            _QueueControlsPanel(
              selectedSort: selectedSort,
              selectedFilter: selectedFilter,
              totalCount: totalCount,
              photoCount: photoCount,
              videoCount: videoCount,
              addedNewestFirst: addedNewestFirst,
              onSortSelected: onSortSelected,
              onFilterSelected: onFilterSelected,
            ),
          ],
        ],
      ),
    );
  }
}

class _QueueStat {
  const _QueueStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _QueueStatChip extends StatelessWidget {
  const _QueueStatChip({required this.stat});

  final _QueueStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(stat.icon, size: 16, color: const Color(0xFF6E6E73)),
          const SizedBox(width: 8),
          Text(
            stat.value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F1F1F),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            stat.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6E6E73),
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueControlsPanel extends StatelessWidget {
  const _QueueControlsPanel({
    required this.selectedSort,
    required this.selectedFilter,
    required this.totalCount,
    required this.photoCount,
    required this.videoCount,
    required this.addedNewestFirst,
    required this.onSortSelected,
    required this.onFilterSelected,
  });

  final _QueueSort selectedSort;
  final _QueueMediaFilter selectedFilter;
  final int totalCount;
  final int photoCount;
  final int videoCount;
  final bool addedNewestFirst;
  final ValueChanged<_QueueSort> onSortSelected;
  final ValueChanged<_QueueMediaFilter> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _QueueControlSection(
          label: l10n.queueFilterLabel,
          child: _QueueOptionSelector<_QueueMediaFilter>(
            selected: selectedFilter,
            onSelected: onFilterSelected,
            options: [
              _QueueSelectorOption(
                value: _QueueMediaFilter.all,
                label: '${l10n.queueFilterAll} ($totalCount)',
                icon: Icons.grid_view_rounded,
              ),
              _QueueSelectorOption(
                value: _QueueMediaFilter.photos,
                label: '${l10n.queueFilterPhotos} ($photoCount)',
                icon: Icons.photo_library_rounded,
              ),
              _QueueSelectorOption(
                value: _QueueMediaFilter.videos,
                label: '${l10n.queueFilterVideos} ($videoCount)',
                icon: Icons.videocam_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _QueueControlSection(
          label: l10n.queueSortLabel,
          compact: true,
          child: _QueueSecondarySelector<_QueueSort>(
            selected: selectedSort,
            onSelected: onSortSelected,
            options: [
              _QueueSelectorOption(
                value: _QueueSort.added,
                label: l10n.queueSortAdded,
                icon: addedNewestFirst
                    ? Icons.south_rounded
                    : Icons.north_rounded,
              ),
              _QueueSelectorOption(
                value: _QueueSort.size,
                label: l10n.queueSortSize,
                icon: Icons.align_vertical_bottom_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QueueControlSection extends StatelessWidget {
  const _QueueControlSection({
    required this.label,
    required this.child,
    this.compact = false,
  });

  final String label;
  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: compact ? 11 : 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF6E6E73),
            letterSpacing: compact ? 0 : -0.1,
          ),
        ),
        SizedBox(height: compact ? 6 : 7),
        SizedBox(height: compact ? 34 : 38, child: child),
      ],
    );
  }
}

class _QueueSelectorOption<T> {
  const _QueueSelectorOption({
    required this.value,
    required this.label,
    required this.icon,
  });

  final T value;
  final String label;
  final IconData icon;
}

class _QueueOptionSelector<T> extends StatelessWidget {
  const _QueueOptionSelector({
    required this.selected,
    required this.onSelected,
    required this.options,
  });

  final T selected;
  final ValueChanged<T> onSelected;
  final List<_QueueSelectorOption<T>> options;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.62)),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelected(option.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected == option.value
                        ? const Color(0xFF1F1F1F)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: selected == option.value
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        option.icon,
                        size: 13,
                        color: selected == option.value
                            ? Colors.white
                            : const Color(0xFF6E6E73),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          option.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: selected == option.value
                                ? Colors.white
                                : const Color(0xFF1F1F1F),
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QueueSecondarySelector<T> extends StatelessWidget {
  const _QueueSecondarySelector({
    required this.selected,
    required this.onSelected,
    required this.options,
  });

  final T selected;
  final ValueChanged<T> onSelected;
  final List<_QueueSelectorOption<T>> options;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < options.length; i++) ...[
          _QueueMiniOptionChip<T>(
            option: options[i],
            selected: selected == options[i].value,
            onTap: () => onSelected(options[i].value),
          ),
          if (i < options.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _QueueMiniOptionChip<T> extends StatelessWidget {
  const _QueueMiniOptionChip({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _QueueSelectorOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF1F1F1F)
              : Colors.white.withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.62),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              option.icon,
              size: 12,
              color: selected ? Colors.white : const Color(0xFF6E6E73),
            ),
            const SizedBox(width: 5),
            Text(
              option.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : const Color(0xFF1F1F1F),
              ),
            ),
          ],
        ),
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
    final isVideo = item.type == MediaType.video;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: Center(
              child: GestureDetector(
                onTap: () {},
                child: isVideo
                    ? _QueueFullScreenVideo(asset: item.asset)
                    : InteractiveViewer(
                        maxScale: 4,
                        child: Image(
                          image: AssetEntityImageProvider(
                            item.asset,
                            isOriginal: true,
                          ),
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.broken_image_outlined, size: 80),
                        ),
                      ),
              ),
            ),
          ),
          Positioned(
            top: 18,
            left: 18,
            child: SafeArea(
              child: Material(
                color: Colors.black.withValues(alpha: 0.55),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).pop(),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 22,
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

class _QueueFullScreenVideo extends StatefulWidget {
  const _QueueFullScreenVideo({required this.asset});

  final AssetEntity asset;

  @override
  State<_QueueFullScreenVideo> createState() => _QueueFullScreenVideoState();
}

class _QueueFullScreenVideoState extends State<_QueueFullScreenVideo> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final file = await widget.asset.file;
      if (!mounted || file == null) return;
      final controller = VideoPlayerController.file(file);
      _controller = controller;
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);
      await controller.play();
      setState(() => _ready = true);
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (!_ready || controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        AspectRatio(
          aspectRatio: controller.value.aspectRatio == 0
              ? 16 / 9
              : controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Material(
            color: Colors.black.withValues(alpha: 0.5),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                if (controller.value.isPlaying) {
                  controller.pause();
                } else {
                  controller.play();
                }
                setState(() {});
              },
              child: SizedBox(
                width: 56,
                height: 56,
                child: Icon(
                  controller.value.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
        ),
      ],
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
