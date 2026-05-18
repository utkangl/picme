import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:picme/src/core/ads/admob_config.dart';
import 'package:picme/src/core/ads/picme_banner_ad_slot.dart';
import 'package:picme/src/core/analytics/app_analytics.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:picme/l10n/app_localizations.dart';
import 'package:picme/src/core/models/media_item.dart';
import 'package:picme/src/core/models/swipe_action_record.dart';
import 'package:picme/src/core/ui/app_coach.dart';
import 'package:picme/src/features/swipe/domain/swipe_filters.dart';
import 'package:picme/src/features/swipe/presentation/swipe_intro_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({
    super.key,
    required this.media,
    required this.category,
    required this.isLoading,
    required this.errorMessage,
    required this.showSponsoredCard,
    required this.sponsoredCardSerial,
    required this.totalDeckCount,
    required this.remainingDeckCount,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.onDismissSponsoredCard,
    required this.onRevertLast,
    required this.canRevert,
    required this.onRetry,
    required this.onBack,
    required this.onOpenQueue,
    required this.queueCount,
    required this.swipesUntilSponsoredCard,
    required this.tourPrefsKey,
    this.onLoadMore,
    this.categoryNotFound = false,
    this.displayTitle,
  });

  final List<MediaItem> media;
  final GalleryCategory category;
  final bool isLoading;
  final String? errorMessage;
  final bool showSponsoredCard;
  final int sponsoredCardSerial;
  final int totalDeckCount;
  final int remainingDeckCount;

  /// True when the named folder for this category doesn't exist on the device
  /// (e.g. no "Screenshots" folder). Shows a specific empty state instead of
  /// the generic "all scanned" message.
  final bool categoryNotFound;

  /// Optional override for the title shown in the swipe header. When the user
  /// is browsing a dynamically-discovered folder (e.g. "WhatsApp Images") we
  /// pass the folder name here instead of falling back to the category label.
  final String? displayTitle;
  final ValueChanged<MediaItem> onSwipeLeft;
  final ValueChanged<MediaItem> onSwipeRight;
  final VoidCallback onDismissSponsoredCard;
  final SwipeAction? Function() onRevertLast;
  final bool canRevert;
  final VoidCallback onRetry;
  final VoidCallback onBack;
  final VoidCallback onOpenQueue;
  final int queueCount;
  final int swipesUntilSponsoredCard;
  final String tourPrefsKey;

  /// Called when the swipe deck is near empty and more pages may be available.
  final VoidCallback? onLoadMore;

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen>
    with TickerProviderStateMixin {
  static const double _swipeThresholdRatio = 0.18;
  static const double _velocityThreshold = 700;
  static const double _sponsoredLockedDragLimit = 28;
  static const Duration _sponsoredLockDuration = Duration(seconds: 10);
  static const Duration _sponsoredAdLoadTimeout = Duration(seconds: 8);
  static const int _sponsoredPreloadLead = 3;

  Offset _dragOffset = Offset.zero;
  late final AnimationController _controller;
  late final AnimationController _sponsoredLockController;
  late final AnimationController _lockedShakeController;
  late final Animation<double> _lockedShakeOffset;
  Animation<Offset>? _offsetAnimation;
  _SwipeAction? _pendingAction;
  bool _isAnimatingOut = false;
  bool _pendingUndoEnter = false;
  bool _isUndoEntering = false;
  SwipeAction? _pendingUndoAction;

  /// Progress bar için: kategori ilk yüklendiğindeki toplam item sayısı.
  int _initialTotal = 0;

  bool _tourChecked = false;
  bool _sponsoredExposureStarted = false;
  Timer? _sponsoredLoadTimeoutTimer;
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
    _sponsoredLockController =
        AnimationController(vsync: this, duration: _sponsoredLockDuration)
          ..addListener(() {
            if (mounted) setState(() {});
          });
    _lockedShakeController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 420),
        )..addListener(() {
          if (mounted) setState(() {});
        });
    _lockedShakeOffset =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0, end: -12), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -12, end: 12), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 12, end: -9), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -9, end: 9), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 9, end: -5), weight: 1.5),
          TweenSequenceItem(tween: Tween(begin: -5, end: 0), weight: 1.5),
        ]).animate(
          CurvedAnimation(
            parent: _lockedShakeController,
            curve: Curves.easeOutCubic,
          ),
        );
    _syncSponsoredLockState(forceRestart: widget.showSponsoredCard);
    _maybePreloadSponsoredAd();
  }

  @override
  void dispose() {
    AppCoach.dismiss();
    _sponsoredLoadTimeoutTimer?.cancel();
    _controller.dispose();
    _sponsoredLockController.dispose();
    _lockedShakeController.dispose();
    super.dispose();
  }

  bool get _isSponsoredLocked =>
      widget.showSponsoredCard &&
      (!_sponsoredExposureStarted || _sponsoredLockController.value < 1.0);

  double get _sponsoredLockProgress =>
      _sponsoredLockController.value.clamp(0.0, 1.0);

  double get _lockAttemptProgress =>
      _lockedShakeController.value.clamp(0.0, 1.0);

  int get _sponsoredLockRemainingSeconds {
    if (!_isSponsoredLocked) return 0;
    final remainingFraction = (1 - _sponsoredLockController.value).clamp(
      0.0,
      1.0,
    );
    final seconds = (remainingFraction * _sponsoredLockDuration.inSeconds)
        .ceil();
    return seconds.clamp(1, _sponsoredLockDuration.inSeconds);
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

    // Step 1 — animated full-screen intro that demonstrates the swipe gesture
    // (the previous spotlight on the live deck couldn't fit a tooltip without
    // clipping).
    await Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (ctx, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: SwipeIntroOverlay(onDone: () => Navigator.of(ctx).pop()),
          );
        },
      ),
    );
    if (!mounted) return;

    // Step 2 — small, focused coach marks for the secondary controls.
    final l10n = AppLocalizations.of(context)!;
    await AppCoach.show(
      context,
      steps: [
        CoachStep(
          targetKey: _revertKey,
          title: l10n.coachSwipeUndoTitle,
          description: l10n.coachSwipeUndoDesc,
          shape: CoachShape.circle,
          padding: const EdgeInsets.all(4),
        ),
        CoachStep(
          targetKey: _queueKey,
          title: l10n.coachSwipeQueueTitle,
          description: l10n.coachSwipeQueueDesc,
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
      _syncSponsoredLockState(forceRestart: widget.showSponsoredCard);
      _maybePreloadSponsoredAd();
      return;
    }
    if (oldWidget.showSponsoredCard != widget.showSponsoredCard ||
        oldWidget.sponsoredCardSerial != widget.sponsoredCardSerial) {
      _syncSponsoredLockState(forceRestart: widget.showSponsoredCard);
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
    _maybePreloadSponsoredAd();
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

  void _syncSponsoredLockState({required bool forceRestart}) {
    _lockedShakeController.stop();
    _lockedShakeController.reset();
    if (!widget.showSponsoredCard) {
      _sponsoredLoadTimeoutTimer?.cancel();
      _sponsoredLockController.stop();
      _sponsoredLockController.reset();
      _sponsoredExposureStarted = false;
      return;
    }
    if (!forceRestart && _sponsoredExposureStarted) return;
    _sponsoredLoadTimeoutTimer?.cancel();
    _sponsoredLockController
      ..stop()
      ..reset();
    _sponsoredExposureStarted = false;
    _sponsoredLoadTimeoutTimer = Timer(_sponsoredAdLoadTimeout, () {
      if (!mounted || !widget.showSponsoredCard || _sponsoredExposureStarted) {
        return;
      }
      widget.onDismissSponsoredCard();
    });
  }

  void _maybePreloadSponsoredAd() {
    if (widget.showSponsoredCard || widget.swipesUntilSponsoredCard <= 0) {
      return;
    }
    if (widget.swipesUntilSponsoredCard > _sponsoredPreloadLead) return;
    unawaited(PicmeBannerAdSlot.preload(PicmeAdPlacement.swipeSponsoredCard));
  }

  void _handleSponsoredAdLoaded() {
    if (!widget.showSponsoredCard || _sponsoredExposureStarted) return;
    _sponsoredLoadTimeoutTimer?.cancel();
    _sponsoredExposureStarted = true;
    unawaited(
      AppAnalytics.instance.logSponsoredAdLoaded(
        serial: widget.sponsoredCardSerial,
      ),
    );
    _sponsoredLockController
      ..stop()
      ..forward(from: 0);
  }

  void _handleSponsoredAdFailed() {
    _sponsoredLoadTimeoutTimer?.cancel();
    if (!widget.showSponsoredCard) return;
    unawaited(
      AppAnalytics.instance.logSponsoredAdFailed(
        serial: widget.sponsoredCardSerial,
      ),
    );
    widget.onDismissSponsoredCard();
  }

  Future<void> _triggerSponsoredLockFeedback() async {
    HapticFeedback.mediumImpact();
    _controller.stop();
    setState(() {
      _pendingAction = null;
      _isAnimatingOut = false;
      _dragOffset = Offset.zero;
    });
    await _lockedShakeController.forward(from: 0);
    if (!mounted) return;
    _lockedShakeController.reset();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final totalProgressCount = widget.totalDeckCount > 0
        ? widget.totalDeckCount
        : widget.media.length;
    final swipedCount = (totalProgressCount - widget.remainingDeckCount).clamp(
      0,
      totalProgressCount,
    );
    final progress = totalProgressCount == 0
        ? 0.0
        : swipedCount / totalProgressCount;
    final controlsLocked = widget.showSponsoredCard;

    return PopScope(
      canPop: !controlsLocked,
      child: Stack(
        children: [
          Column(
            children: [
              // Slim animated progress bar at the very top.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 3,
                    color: Colors.white.withValues(alpha: 0.5),
                    child: FractionallySizedBox(
                      widthFactor: progress.clamp(0.0, 1.0),
                      alignment: Alignment.centerLeft,
                      child: const ColoredBox(color: Color(0xFF1F1F1F)),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                child: Row(
                  children: [
                    _SwipeCircleButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: controlsLocked ? null : widget.onBack,
                    ),
                    Expanded(
                      child: Text(
                        widget.displayTitle ??
                            widget.category.labelOf(
                              AppLocalizations.of(context)!,
                            ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: Color(0xFF1F1F1F),
                        ),
                      ),
                    ),
                    _SwipeCircleButton(
                      key: _revertKey,
                      icon: Icons.undo_rounded,
                      onTap: !controlsLocked && widget.canRevert
                          ? _onRevertPressed
                          : null,
                      tooltip: AppLocalizations.of(context)!.undoButton,
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
            child: _QueueFab(
              key: _queueKey,
              count: widget.queueCount,
              onTap: controlsLocked ? null : widget.onOpenQueue,
            ),
          ),
        ],
      ),
    );
  }

  void _onRevertPressed() {
    if (!widget.canRevert || widget.showSponsoredCard) return;
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
      final l10n = AppLocalizations.of(context)!;
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
                label: Text(l10n.retryButton),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.media.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      if (widget.categoryNotFound) {
        return _CategoryNotFoundState(
          category: widget.displayTitle ?? widget.category.labelOf(l10n),
          onBack: widget.onBack,
          l10n: l10n,
        );
      }
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.done_all_rounded,
                size: 36,
                color: Color(0xFF1F1F1F),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.allScanned,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F1F1F),
              ),
            ),
            const SizedBox(height: 12),
            if (widget.canRevert && !widget.showSponsoredCard)
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1F1F1F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _onRevertPressed,
                icon: const Icon(Icons.undo_rounded, size: 18),
                label: Text(l10n.undoLastMove),
              ),
          ],
        ),
      );
    }

    final isSponsoredCard = widget.showSponsoredCard && widget.media.isNotEmpty;
    final current = widget.media.first;
    final next = isSponsoredCard
        ? current
        : (widget.media.length > 1 ? widget.media[1] : null);
    _precacheUpcoming(context);
    if (!_tourChecked) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStartTour());
    }
    final width = MediaQuery.sizeOf(context).width - 40;
    final dragProgress = _isUndoEntering
        ? 0.0
        : (_dragOffset.dx.abs() / (width * 0.35)).clamp(0.0, 1.0);
    final cardOpacity = 1 - (dragProgress * 0.12);
    final shakeDx = isSponsoredCard ? _lockedShakeOffset.value : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: isSponsoredCard
                ? _SponsoredHints(
                    dx: _isUndoEntering ? 0 : _dragOffset.dx,
                    width: width,
                    isLocked: _isSponsoredLocked,
                    lockProgress: _sponsoredLockProgress,
                    lockAttemptProgress: _lockAttemptProgress,
                  )
                : _SwipeHints(
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
              onTap: isSponsoredCard ? null : () => _openPreview(current),
              onPanStart: (_) => _onPanStart(),
              onPanUpdate: (details) {
                if (_isAnimatingOut) return;
                final resistedDx = _applyHorizontalResistance(
                  _dragOffset.dx,
                  details.delta.dx,
                );
                final resistedDy = details.delta.dy * 0.08;
                final nextDx = _dragOffset.dx + resistedDx;
                final nextDy = _dragOffset.dy + resistedDy;
                setState(() {
                  _dragOffset = Offset(
                    isSponsoredCard && _isSponsoredLocked
                        ? nextDx
                              .clamp(
                                -_sponsoredLockedDragLimit,
                                _sponsoredLockedDragLimit,
                              )
                              .toDouble()
                        : nextDx,
                    isSponsoredCard && _isSponsoredLocked
                        ? nextDy.clamp(-10, 10).toDouble()
                        : nextDy,
                  );
                });
              },
              onPanEnd: (details) =>
                  _onPanEnd(details, width, isSponsoredCard: isSponsoredCard),
              child: Transform.translate(
                offset: Offset(_dragOffset.dx + shakeDx, _dragOffset.dy),
                child: Transform.rotate(
                  angle: (_dragOffset.dx / width) * 0.175,
                  child: Opacity(
                    opacity: cardOpacity,
                    child: isSponsoredCard
                        ? _SponsoredCard(
                            serial: widget.sponsoredCardSerial,
                            dragDx: _isUndoEntering ? 0 : _dragOffset.dx,
                            width: width,
                            isLocked: _isSponsoredLocked,
                            lockProgress: _sponsoredLockProgress,
                            remainingSeconds: _sponsoredLockRemainingSeconds,
                            onAdLoaded: _handleSponsoredAdLoaded,
                            onAdFailed: _handleSponsoredAdFailed,
                          )
                        : _MediaCard(
                            item: current,
                            dragDx: _isUndoEntering ? 0 : _dragOffset.dx,
                            width: width,
                            autoplayVideo: true,
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

  /// If a swipe-out animation is still running when the user lifts and
  /// re-touches the card to fire the next swipe, we don't want them to wait
  /// for the previous animation to finish. Instead we commit the pending
  /// swipe immediately, snap the deck to the next card, and let the new pan
  /// drag from origin — this is what makes "tap tap tap" feel possible.
  void _onPanStart() {
    if (_isAnimatingOut && _pendingAction != null) {
      _commitPendingSwipe();
      return;
    }
    _controller.stop();
    if (_isUndoEntering) {
      setState(() => _isUndoEntering = false);
    }
  }

  void _commitPendingSwipe() {
    final action = _pendingAction;
    if (action == null) return;
    _controller.stop();
    _pendingAction = null;
    _isAnimatingOut = false;
    _resolveSwipeAction(action);
    setState(() => _dragOffset = Offset.zero);
    if (!widget.showSponsoredCard && widget.media.length <= 30) {
      widget.onLoadMore?.call();
    }
  }

  void _onPanEnd(
    DragEndDetails details,
    double width, {
    required bool isSponsoredCard,
  }) {
    if (_isAnimatingOut) return;

    final velocityX = details.velocity.pixelsPerSecond.dx;
    final threshold = width * _swipeThresholdRatio;
    final shouldSwipeRight =
        _dragOffset.dx > threshold || velocityX > _velocityThreshold;
    final shouldSwipeLeft =
        _dragOffset.dx < -threshold || velocityX < -_velocityThreshold;

    if (isSponsoredCard && _isSponsoredLocked) {
      final attemptedSwipe =
          shouldSwipeLeft ||
          shouldSwipeRight ||
          _dragOffset.dx.abs() > 22 ||
          velocityX.abs() > 180;
      if (attemptedSwipe) {
        unawaited(_triggerSponsoredLockFeedback());
      } else {
        _animateBack();
      }
      return;
    }

    if (shouldSwipeLeft) {
      HapticFeedback.lightImpact();
      _animateOut(
        isSponsoredCard ? _SwipeAction.dismissSponsored : _SwipeAction.delete,
        width,
        velocityX,
      );
      return;
    }
    if (shouldSwipeRight) {
      HapticFeedback.selectionClick();
      _animateOut(
        isSponsoredCard ? _SwipeAction.dismissSponsored : _SwipeAction.keep,
        width,
        velocityX,
      );
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
      ..duration = const Duration(milliseconds: 240)
      ..forward(from: 0);
  }

  void _animateOut(_SwipeAction action, double width, double velocityX) {
    _pendingAction = action;
    _isAnimatingOut = true;
    final sign = switch (action) {
      _SwipeAction.delete => -1.0,
      _SwipeAction.keep => 1.0,
      _SwipeAction.dismissSponsored => _dragOffset.dx < 0 ? -1.0 : 1.0,
    };
    final speedBoost = velocityX.abs().clamp(0, 1400) / 1400;
    final target = Offset(
      sign * (width * (1.25 + (speedBoost * 0.25))),
      _dragOffset.dy + 32,
    );
    _offsetAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: target,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    // Faster fling-out so the user can chain swipes more aggressively.
    // _commitPendingSwipe() in onPanStart still bypasses this duration if the
    // next pan begins before the animation finishes.
    _controller
      ..duration = const Duration(milliseconds: 180)
      ..forward(from: 0);
  }

  void _completeSwipe(_SwipeAction action) {
    if (widget.media.isEmpty && action != _SwipeAction.dismissSponsored) {
      _resetTransform();
      return;
    }
    _resolveSwipeAction(action);
    _resetTransform();
    // Trigger next-page load when 30 items remain.
    if (action != _SwipeAction.dismissSponsored && widget.media.length <= 30) {
      widget.onLoadMore?.call();
    }
  }

  void _resolveSwipeAction(_SwipeAction action) {
    if (action == _SwipeAction.dismissSponsored) {
      unawaited(
        AppAnalytics.instance.logSponsoredAdDismissed(
          serial: widget.sponsoredCardSerial,
          wasUnlocked: !_isSponsoredLocked,
        ),
      );
      widget.onDismissSponsoredCard();
      return;
    }
    if (widget.media.isEmpty) return;
    final current = widget.media.first;
    if (action == _SwipeAction.delete) {
      widget.onSwipeLeft(current);
    } else {
      widget.onSwipeRight(current);
    }
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

enum _SwipeAction { keep, delete, dismissSponsored }

class _SwipeCircleButton extends StatelessWidget {
  const _SwipeCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final btn = Material(
      color: disabled
          ? Colors.white.withValues(alpha: 0.4)
          : Colors.white.withValues(alpha: 0.8),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            size: 20,
            color: disabled ? const Color(0xFFB0B0B0) : const Color(0xFF1F1F1F),
          ),
        ),
      ),
    );
    if (tooltip == null) return btn;
    return Tooltip(message: tooltip!, child: btn);
  }
}

class _QueueFab extends StatelessWidget {
  const _QueueFab({super.key, required this.count, required this.onTap});

  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Material(
      color: disabled
          ? const Color(0xFF1F1F1F).withValues(alpha: 0.35)
          : const Color(0xFF1F1F1F),
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.delete_sweep_rounded,
                color: Colors.white,
                size: 22,
              ),
              if (count > 0)
                Positioned(
                  right: -8,
                  top: -8,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE07A5F),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                      ),
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

class _SwipeHints extends StatelessWidget {
  const _SwipeHints({required this.dx, required this.width});

  final double dx;
  final double width;

  @override
  Widget build(BuildContext context) {
    final keepOpacity = (dx / (width * 0.22)).clamp(0.0, 1.0);
    final deleteOpacity = ((-dx) / (width * 0.22)).clamp(0.0, 1.0);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.45),
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
              child: Text(
                l10n.swipeHint,
                style: const TextStyle(
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
              child: _HintChip(
                label: l10n.keep,
                color: const Color(0xFF146C2E),
                icon: Icons.favorite_border_rounded,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Opacity(
              opacity: deleteOpacity,
              child: _HintChip(
                label: l10n.deleteLabel,
                color: const Color(0xFFC81E1E),
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

class _SponsoredReadyBanner extends StatefulWidget {
  const _SponsoredReadyBanner({this.compact = false});

  final bool compact;

  @override
  State<_SponsoredReadyBanner> createState() => _SponsoredReadyBannerState();
}

class _SponsoredReadyBannerState extends State<_SponsoredReadyBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    final child = AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        final iconScale = 0.96 + (t * 0.12);
        final glowAlpha = 0.08 + (t * 0.10);
        final leftOffset = -6 + (t * 6);
        final rightOffset = 6 - (t * 6);
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.translate(
              offset: Offset(leftOffset, 0),
              child: Icon(
                Icons.chevron_left_rounded,
                size: compact ? 22 : 24,
                color: const Color(
                  0xFF146C2E,
                ).withValues(alpha: 0.52 + (t * 0.38)),
              ),
            ),
            const SizedBox(width: 4),
            Transform.scale(
              scale: iconScale,
              child: Container(
                width: compact ? 30 : 34,
                height: compact ? 30 : 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF146C2E).withValues(alpha: glowAlpha),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.verified_rounded,
                  size: 18,
                  color: Color(0xFF146C2E),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Transform.translate(
              offset: Offset(rightOffset, 0),
              child: Icon(
                Icons.chevron_right_rounded,
                size: compact ? 22 : 24,
                color: const Color(
                  0xFF146C2E,
                ).withValues(alpha: 0.52 + (t * 0.38)),
              ),
            ),
          ],
        );
      },
    );

    if (compact) {
      return child;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFF1F1F1F).withValues(alpha: 0.1),
        ),
      ),
      child: child,
    );
  }
}

class _SponsoredHints extends StatelessWidget {
  const _SponsoredHints({
    required this.dx,
    required this.width,
    required this.isLocked,
    required this.lockProgress,
    required this.lockAttemptProgress,
  });

  final double dx;
  final double width;
  final bool isLocked;
  final double lockProgress;
  final double lockAttemptProgress;

  @override
  Widget build(BuildContext context) {
    final dismissOpacity = (dx.abs() / (width * 0.22)).clamp(0.0, 1.0);
    final lockOpacity = (0.34 + (lockAttemptProgress * 0.66)).clamp(0.0, 1.0);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.45),
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
              child: Text(
                isLocked
                    ? l10n.sponsoredCardLockedHint
                    : l10n.sponsoredCardSwipeHint,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          if (isLocked) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Opacity(
                opacity: lockOpacity,
                child: _HintChip(
                  label: l10n.sponsoredCardLocked,
                  color: const Color(0xFF1F1F1F),
                  icon: Icons.lock_rounded,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Opacity(
                opacity: lockOpacity,
                child: _HintChip(
                  label: l10n.sponsoredCardLocked,
                  color: const Color(0xFF1F1F1F),
                  icon: Icons.lock_rounded,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: lockProgress,
                    backgroundColor: Colors.white.withValues(alpha: 0.5),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF1F1F1F)),
                  ),
                ),
              ),
            ),
          ] else
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
                child: Opacity(
                  opacity: (0.88 + (dismissOpacity * 0.12)).clamp(0.0, 1.0),
                  child: const _SponsoredReadyBanner(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SponsoredCard extends StatelessWidget {
  const _SponsoredCard({
    required this.serial,
    required this.isLocked,
    required this.lockProgress,
    required this.remainingSeconds,
    required this.onAdLoaded,
    required this.onAdFailed,
    this.dragDx = 0,
    this.width = 1,
  });

  final int serial;
  final bool isLocked;
  final double lockProgress;
  final int remainingSeconds;
  final VoidCallback onAdLoaded;
  final VoidCallback onAdFailed;
  final double dragDx;
  final double width;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final intentProgress = (dragDx.abs() / (width * 0.22)).clamp(0.0, 1.0);
    final statusText = l10n.sponsoredCardUnlockingCountdown(remainingSeconds);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F2F0),
          border: Border.all(color: const Color(0x14000000)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (intentProgress > 0)
              Positioned.fill(
                child: ColoredBox(
                  color: const Color(
                    0xFF1F1F1F,
                  ).withValues(alpha: 0.04 + (intentProgress * 0.08)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          l10n.sponsoredCardBadge,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                            color: Color(0xFF1F1F1F),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l10n.sponsoredCardTitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(
                            0xFF1F1F1F,
                          ).withValues(alpha: 0.68),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (isLocked)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        value: lockProgress,
                        backgroundColor: const Color(0x14000000),
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF1F1F1F),
                        ),
                      ),
                    )
                  else
                    const _SponsoredReadyBanner(),
                  const Spacer(),
                  PicmeBannerAdSlot(
                    key: ValueKey('sponsored-card-ad-$serial'),
                    placement: PicmeAdPlacement.swipeSponsoredCard,
                    onAdLoaded: onAdLoaded,
                    onAdFailedToLoad: onAdFailed,
                    builder: (context, adWidget) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.08),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: adWidget,
                      );
                    },
                  ),
                  const Spacer(),
                  if (isLocked)
                    Center(
                      child: Text(
                        statusText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                          color: const Color(
                            0xFF1F1F1F,
                          ).withValues(alpha: 0.62),
                        ),
                      ),
                    )
                  else
                    const Center(child: _SponsoredReadyBanner(compact: true)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  const _MediaCard({
    required this.item,
    this.dragDx = 0,
    this.width = 1,
    this.autoplayVideo = false,
  });

  final MediaItem item;
  final double dragDx;
  final double width;

  /// When `true` and [item] is a video, the card embeds an inline
  /// [VideoPlayer] that plays muted in a loop. We only enable this for the
  /// top card so the under-card (preload) doesn't burn battery decoding two
  /// videos at once.
  final bool autoplayVideo;

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
              if (isVideo && autoplayVideo)
                _InlineVideoPlayer(
                  asset: item.asset,
                  key: ValueKey('video-${item.id}'),
                )
              else
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
              if (isVideo && !autoplayVideo)
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

/// Inline, muted-and-looping video preview that fits the swipe card.
///
/// Resolves the underlying [File] from `photo_manager` lazily and disposes
/// the [VideoPlayerController] when the card is rebuilt out (e.g. when the
/// next video becomes the top card). A blurred image of the same asset is
/// shown while the player is initializing so the card never goes blank.
class _InlineVideoPlayer extends StatefulWidget {
  const _InlineVideoPlayer({super.key, required this.asset});

  final AssetEntity asset;

  @override
  State<_InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<_InlineVideoPlayer> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final File? file = await widget.asset.file;
      if (!mounted || file == null) {
        if (mounted) setState(() => _failed = true);
        return;
      }
      final controller = VideoPlayerController.file(file);
      _controller = controller;
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.setVolume(0);
      await controller.setLooping(true);
      await controller.play();
      setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final placeholder = Image(
      image: AssetEntityImageProvider(
        widget.asset,
        isOriginal: false,
        thumbnailSize: const ThumbnailSize.square(800),
      ),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) =>
          const Center(child: Icon(Icons.videocam_off_rounded, size: 64)),
    );

    if (_failed || controller == null || !_ready) {
      return Stack(
        fit: StackFit.expand,
        children: [
          placeholder,
          if (!_failed)
            const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      );
    }

    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  }
}

class _PreviewScreen extends StatelessWidget {
  const _PreviewScreen({required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    final isVideo = item.type == MediaType.video;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: isVideo
                ? _FullScreenVideo(asset: item.asset)
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
    );
  }
}

class _FullScreenVideo extends StatefulWidget {
  const _FullScreenVideo({required this.asset});

  final AssetEntity asset;

  @override
  State<_FullScreenVideo> createState() => _FullScreenVideoState();
}

class _FullScreenVideoState extends State<_FullScreenVideo> {
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
      final c = VideoPlayerController.file(file);
      _controller = c;
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      await c.setLooping(true);
      await c.play();
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
    final c = _controller;
    if (!_ready || c == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        AspectRatio(
          aspectRatio: c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio,
          child: VideoPlayer(c),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Material(
            color: Colors.black.withValues(alpha: 0.5),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                if (c.value.isPlaying) {
                  c.pause();
                } else {
                  c.play();
                }
                setState(() {});
              },
              child: SizedBox(
                width: 56,
                height: 56,
                child: Icon(
                  c.value.isPlaying
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

class _CategoryNotFoundState extends StatelessWidget {
  const _CategoryNotFoundState({
    required this.category,
    required this.onBack,
    required this.l10n,
  });

  final String category;
  final VoidCallback onBack;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.folder_off_rounded,
                size: 36,
                color: Color(0xFF8A8A8A),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.categoryNotFoundTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: Color(0xFF1F1F1F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.categoryNotFoundSubtitle(category),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: const Color(0xFF1F1F1F).withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1F1F1F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: Text(l10n.goBack),
            ),
          ],
        ),
      ),
    );
  }
}
