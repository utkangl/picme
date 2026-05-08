import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:picme/src/core/models/media_item.dart';
import 'package:picme/src/core/models/swipe_action_record.dart';
import 'package:picme/src/core/ui/app_coach.dart';
import 'package:picme/src/features/swipe/domain/swipe_filters.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({
    super.key,
    required this.media,
    required this.category,
    required this.isLoading,
    required this.errorMessage,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.onRevertLast,
    required this.canRevert,
    required this.onRetry,
    required this.onBack,
    required this.onOpenQueue,
    required this.queueCount,
    required this.tourPrefsKey,
  });

  final List<MediaItem> media;
  final GalleryCategory category;
  final bool isLoading;
  final String? errorMessage;
  final ValueChanged<MediaItem> onSwipeLeft;
  final ValueChanged<MediaItem> onSwipeRight;
  final SwipeAction? Function() onRevertLast;
  final bool canRevert;
  final VoidCallback onRetry;
  final VoidCallback onBack;
  final VoidCallback onOpenQueue;
  final int queueCount;
  final String tourPrefsKey;

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen>
    with SingleTickerProviderStateMixin {
  static const double _swipeThresholdRatio = 0.22;

  Offset _dragOffset = Offset.zero;
  late final AnimationController _controller;
  Animation<Offset>? _offsetAnimation;
  _SwipeAction? _pendingAction;
  bool _isAnimatingOut = false;
  bool _pendingUndoEnter = false;
  bool _isUndoEntering = false;
  SwipeAction? _pendingUndoAction;

  /// Progress bar için: kategori ilk yüklendiğindeki toplam item sayısı.
  int _initialTotal = 0;

  bool _tourChecked = false;
  final GlobalKey _cardKey = GlobalKey(debugLabel: 'swipe-card');
  final GlobalKey _revertKey = GlobalKey(debugLabel: 'swipe-revert');
  final GlobalKey _queueKey = GlobalKey(debugLabel: 'swipe-queue');

  @override
  void initState() {
    super.initState();
    _initialTotal = widget.media.length;
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 260),
        )..addListener(() {
          final animation = _offsetAnimation;
          if (animation != null) {
            setState(() => _dragOffset = animation.value);
          }
        });
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_pendingAction != null) {
          _completeSwipe(_pendingAction!);
        } else if (_isUndoEntering) {
          setState(() {
            _isUndoEntering = false;
            _dragOffset = Offset.zero;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    AppCoach.dismiss();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _maybeStartTour() async {
    if (_tourChecked) return;
    _tourChecked = true;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(widget.tourPrefsKey) ?? false) return;
    if (!mounted || widget.media.isEmpty) {
      _tourChecked = false;
      return;
    }
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await AppCoach.show(
      context,
      steps: [
        CoachStep(
          targetKey: _cardKey,
          title: 'Karar ver',
          description:
              'Sola kaydır → silme kuyruğuna ekle. Sağa kaydır → tut. Tek dokun → büyük önizleme.',
          padding: const EdgeInsets.all(0),
          radius: 24,
        ),
        CoachStep(
          targetKey: _revertKey,
          title: 'Geri al',
          description:
              'Son hamleni buradan geri al. Sağa atılan sağdan, sola atılan soldan geri gelir.',
          shape: CoachShape.circle,
          padding: const EdgeInsets.all(4),
        ),
        CoachStep(
          targetKey: _queueKey,
          title: 'Silme kuyruğu',
          description:
              'Sola attıkların burada birikir. Hepsini gözden geçirip toplu kalıcı silme yapabilirsin.',
          shape: CoachShape.circle,
          padding: const EdgeInsets.all(6),
        ),
      ],
    );
    await prefs.setBool(widget.tourPrefsKey, true);
  }

  @override
  void didUpdateWidget(covariant SwipeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category) {
      _initialTotal = widget.media.length;
      _dragOffset = Offset.zero;
      _pendingAction = null;
      _isAnimatingOut = false;
      _isUndoEntering = false;
      _pendingUndoEnter = false;
      return;
    }
    if (oldWidget.media != widget.media) {
      // Yeni bir yükleme yapıldıysa total'ı tazeleyelim.
      if (oldWidget.media.isEmpty && widget.media.isNotEmpty) {
        _initialTotal = widget.media.length;
      } else if (widget.media.length > _initialTotal) {
        _initialTotal = widget.media.length;
      }
      if (_pendingUndoEnter && widget.media.isNotEmpty) {
        _pendingUndoEnter = false;
        _prepareUndoEnter();
      }
    }
  }

  void _prepareUndoEnter() {
    final width = MediaQuery.sizeOf(context).width - 40;
    if (width <= 0) return;
    _controller.stop();
    _pendingAction = null;
    _isAnimatingOut = false;
    _isUndoEntering = true;
    final fromRight = _pendingUndoAction == SwipeAction.keep;
    final start = Offset((fromRight ? 1 : -1) * width * 1.2, 0);
    _dragOffset = start;
    _offsetAnimation = Tween<Offset>(begin: start, end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Cubic(0.18, 0.9, 0.25, 1.0),
      ),
    );
    _controller
      ..duration = const Duration(milliseconds: 380)
      ..forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final swipedCount = (_initialTotal - widget.media.length).clamp(
      0,
      _initialTotal,
    );
    final progress = _initialTotal == 0 ? 0.0 : swipedCount / _initialTotal;

    return Stack(
      children: [
        Column(
          children: [
            Container(
              height: 2,
              color: const Color(0xFFE8E8E8),
              child: FractionallySizedBox(
                widthFactor: progress,
                alignment: Alignment.centerLeft,
                child: const ColoredBox(color: Colors.black),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  Expanded(
                    child: Text(
                      widget.category.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    key: _revertKey,
                    onPressed: widget.canRevert ? _onRevertPressed : null,
                    tooltip: 'Geri al',
                    icon: const Icon(Icons.undo_rounded),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 30,
          child: FloatingActionButton(
            key: _queueKey,
            heroTag: 'queue_fab',
            onPressed: widget.onOpenQueue,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            child: Badge.count(
              count: widget.queueCount,
              isLabelVisible: widget.queueCount > 0,
              child: const Icon(Icons.delete_outline_rounded),
            ),
          ),
        ),
      ],
    );
  }

  void _onRevertPressed() {
    if (!widget.canRevert) return;
    HapticFeedback.selectionClick();
    final revertedAction = widget.onRevertLast();
    if (revertedAction == null) return;
    _pendingUndoAction = revertedAction;
    _pendingUndoEnter = true;
  }

  Widget _buildBody() {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.media.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.done_all_rounded, size: 56),
            const SizedBox(height: 12),
            const Text('Tüm medyalar tarandı.', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            if (widget.canRevert)
              FilledButton.icon(
                onPressed: _onRevertPressed,
                icon: const Icon(Icons.undo_rounded),
                label: const Text('Son hamleyi geri al'),
              ),
          ],
        ),
      );
    }

    final current = widget.media.first;
    final next = widget.media.length > 1 ? widget.media[1] : null;
    _precacheUpcoming(context);
    if (!_tourChecked) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStartTour());
    }
    final width = MediaQuery.sizeOf(context).width - 40;
    final dragProgress = _isUndoEntering
        ? 0.0
        : (_dragOffset.dx.abs() / (width * 0.35)).clamp(0.0, 1.0);
    final cardOpacity = 1 - (dragProgress * 0.12);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: _SwipeHints(
              dx: _isUndoEntering ? 0 : _dragOffset.dx,
              width: width,
            ),
          ),
          if (next != null)
            Positioned.fill(
              child: IgnorePointer(child: _MediaCard(item: next)),
            ),
          Positioned.fill(
            key: _cardKey,
            child: GestureDetector(
              onTap: () => _openPreview(current),
              onPanStart: (_) {
                if (_isAnimatingOut) return;
                _controller.stop();
                if (_isUndoEntering) {
                  setState(() => _isUndoEntering = false);
                }
              },
              onPanUpdate: (details) {
                if (_isAnimatingOut) return;
                final resistedDx = _applyHorizontalResistance(
                  _dragOffset.dx,
                  details.delta.dx,
                );
                final resistedDy = details.delta.dy * 0.08;
                setState(() {
                  _dragOffset = Offset(
                    _dragOffset.dx + resistedDx,
                    _dragOffset.dy + resistedDy,
                  );
                });
              },
              onPanEnd: (details) => _onPanEnd(details, current, width),
              child: Transform.translate(
                offset: _dragOffset,
                child: Transform.rotate(
                  angle: (_dragOffset.dx / width) * 0.175,
                  child: Opacity(
                    opacity: cardOpacity,
                    child: _MediaCard(
                      item: current,
                      dragDx: _isUndoEntering ? 0 : _dragOffset.dx,
                      width: width,
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

  void _openPreview(MediaItem item) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => _PreviewScreen(item: item)));
  }

  void _onPanEnd(DragEndDetails details, MediaItem current, double width) {
    if (_isAnimatingOut) return;

    final velocityX = details.velocity.pixelsPerSecond.dx;
    final threshold = width * _swipeThresholdRatio;
    final shouldSwipeRight = _dragOffset.dx > threshold || velocityX > 900;
    final shouldSwipeLeft = _dragOffset.dx < -threshold || velocityX < -900;

    if (shouldSwipeLeft) {
      HapticFeedback.mediumImpact();
      _animateOut(current, _SwipeAction.delete, width, velocityX);
      return;
    }
    if (shouldSwipeRight) {
      HapticFeedback.lightImpact();
      _animateOut(current, _SwipeAction.keep, width, velocityX);
      return;
    }
    _animateBack();
  }

  void _animateBack() {
    _pendingAction = null;
    _isAnimatingOut = false;
    _offsetAnimation = Tween<Offset>(begin: _dragOffset, end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Cubic(0.2, 0.9, 0.2, 1.0),
          ),
        );
    _controller
      ..duration = const Duration(milliseconds: 420)
      ..forward(from: 0);
  }

  void _animateOut(
    MediaItem current,
    _SwipeAction action,
    double width,
    double velocityX,
  ) {
    _pendingAction = action;
    _isAnimatingOut = true;
    final sign = action == _SwipeAction.delete ? -1.0 : 1.0;
    final speedBoost = velocityX.abs().clamp(0, 1400) / 1400;
    final target = Offset(
      sign * (width * (1.35 + (speedBoost * 0.25))),
      _dragOffset.dy + 42,
    );
    _offsetAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: target,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller
      ..duration = const Duration(milliseconds: 320)
      ..forward(from: 0);
  }

  void _completeSwipe(_SwipeAction action) {
    if (widget.media.isEmpty) {
      _resetTransform();
      return;
    }
    final current = widget.media.first;
    if (action == _SwipeAction.delete) {
      widget.onSwipeLeft(current);
    } else {
      widget.onSwipeRight(current);
    }
    _resetTransform();
  }

  void _resetTransform() {
    setState(() {
      _dragOffset = Offset.zero;
      _pendingAction = null;
      _isAnimatingOut = false;
    });
  }

  void _precacheUpcoming(BuildContext context) {
    for (var step = 1; step <= 3; step++) {
      if (step >= widget.media.length) break;
      final asset = widget.media[step].asset;
      precacheImage(
        AssetEntityImageProvider(
          asset,
          isOriginal: false,
          thumbnailSize: const ThumbnailSize.square(800),
        ),
        context,
      );
    }
  }

  double _applyHorizontalResistance(double currentDx, double deltaDx) {
    final absDx = currentDx.abs();
    if (absDx < 100) return deltaDx;
    if (absDx < 220) return deltaDx * 0.78;
    return deltaDx * 0.58;
  }
}

enum _SwipeAction { keep, delete }

class _SwipeHints extends StatelessWidget {
  const _SwipeHints({required this.dx, required this.width});

  final double dx;
  final double width;

  @override
  Widget build(BuildContext context) {
    final keepOpacity = (dx / (width * 0.22)).clamp(0.0, 1.0);
    final deleteOpacity = ((-dx) / (width * 0.22)).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.grey.shade100,
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.black12),
              ),
              child: const Text(
                'Left: Delete  •  Right: Keep',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Opacity(
              opacity: keepOpacity,
              child: const _HintChip(
                label: 'KEEP',
                color: Color(0xFF146C2E),
                icon: Icons.favorite_border_rounded,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Opacity(
              opacity: deleteOpacity,
              child: const _HintChip(
                label: 'DELETE',
                color: Color(0xFFC81E1E),
                icon: Icons.delete_outline_rounded,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HintChip extends StatelessWidget {
  const _HintChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  const _MediaCard({required this.item, this.dragDx = 0, this.width = 1});

  final MediaItem item;
  final double dragDx;
  final double width;

  @override
  Widget build(BuildContext context) {
    final isVideo = item.type == MediaType.video;
    final created = item.createdAt;
    final date =
        '${created.year}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')}';
    final sizeText = item.fileSizeInBytes != null
        ? '  •  ${(item.fileSizeInBytes! / (1024 * 1024)).toStringAsFixed(1)} MB'
        : '';
    final intentProgress = (dragDx.abs() / (width * 0.22)).clamp(0.0, 1.0);
    final keepIntent = dragDx > 0;

    return GestureDetector(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          color: Colors.white,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image(
                image: AssetEntityImageProvider(
                  item.asset,
                  isOriginal: false,
                  thumbnailSize: const ThumbnailSize.square(800),
                ),
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => const Center(
                  child: Icon(Icons.broken_image_outlined, size: 64),
                ),
              ),
              if (isVideo)
                const Center(
                  child: Icon(
                    Icons.play_circle_outline_rounded,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              if (intentProgress > 0)
                Positioned.fill(
                  child: ColoredBox(
                    color:
                        (keepIntent
                                ? const Color(0xFF2BA94E)
                                : const Color(0xFFD13A3A))
                            .withValues(
                              alpha: keepIntent
                                  ? (0.07 + (intentProgress * 0.18))
                                  : (0.12 + (intentProgress * 0.30)),
                            ),
                  ),
                ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 0,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.34),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$date$sizeText',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
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

class _PreviewScreen extends StatelessWidget {
  const _PreviewScreen({required this.item});

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
