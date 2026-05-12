import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:picme/src/core/ads/admob_config.dart';

/// Small stateful wrapper that owns a single [BannerAd] instance.
///
/// Keeping ad loading here prevents feature UIs from dealing with listeners,
/// disposal, or failed-load branches directly.
class PicmeBannerAdSlot extends StatefulWidget {
  const PicmeBannerAdSlot({
    super.key,
    required this.placement,
    this.alignment = Alignment.center,
    this.builder,
    this.onAdLoaded,
    this.onAdFailedToLoad,
  });

  final PicmeAdPlacement placement;
  final AlignmentGeometry alignment;
  final Widget Function(BuildContext context, Widget adWidget)? builder;
  final VoidCallback? onAdLoaded;
  final VoidCallback? onAdFailedToLoad;

  @override
  State<PicmeBannerAdSlot> createState() => _PicmeBannerAdSlotState();
}

class _PicmeBannerAdSlotState extends State<PicmeBannerAdSlot>
    with AutomaticKeepAliveClientMixin {
  static final Map<PicmeAdPlacement, BannerAd> _adCache = {};
  static final Map<PicmeAdPlacement, Future<BannerAd?>> _pendingLoads = {};

  BannerAd? _ad;
  bool _loadStarted = false;
  bool _didNotifyLoaded = false;
  bool _didNotifyFailed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final cached = _adCache[widget.placement];
    if (cached != null) {
      _ad = cached;
      WidgetsBinding.instance.addPostFrameCallback((_) => _notifyLoaded());
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_loadAdWithDelay());
    });
  }

  Future<void> _loadAdWithDelay({bool skipDelay = false}) async {
    if (!skipDelay) {
      await Future<void>.delayed(PicmeAdMobConfig.loadDelay(widget.placement));
    }
    if (!mounted) return;
    await _loadAd();
  }

  Future<void> _loadAd() async {
    if (!PicmeAdMobConfig.isSupportedPlatform ||
        !PicmeAdMobConfig.isPlacementEnabled(widget.placement) ||
        _loadStarted) {
      return;
    }
    _loadStarted = true;
    await PicmeAdMobConfig.ensureInitialized();
    if (!mounted) return;

    final cached = _adCache[widget.placement];
    if (cached != null) {
      setState(() => _ad = cached);
      _notifyLoaded();
      return;
    }

    final future = _pendingLoads[widget.placement] ??= _createAndLoadAd(
      widget.placement,
    );
    final loadedAd = await future;
    if (_pendingLoads[widget.placement] == future) {
      _pendingLoads.remove(widget.placement);
    }
    if (!mounted) return;
    if (loadedAd == null) {
      _notifyFailed();
      return;
    }
    _adCache[widget.placement] = loadedAd;
    setState(() => _ad = loadedAd);
    _notifyLoaded();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<BannerAd?> _createAndLoadAd(PicmeAdPlacement placement) {
    final completer = Completer<BannerAd?>();
    final ad = BannerAd(
      adUnitId: PicmeAdMobConfig.bannerUnitId(placement),
      size: PicmeAdMobConfig.bannerSize(placement),
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!completer.isCompleted) {
            completer.complete(ad as BannerAd);
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        },
      ),
    );
    unawaited(ad.load());
    return completer.future;
  }

  void _notifyLoaded() {
    if (_didNotifyLoaded) return;
    _didNotifyLoaded = true;
    widget.onAdLoaded?.call();
  }

  void _notifyFailed() {
    if (_didNotifyFailed) return;
    _didNotifyFailed = true;
    widget.onAdFailedToLoad?.call();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ad = _ad;
    final size = PicmeAdMobConfig.bannerSize(widget.placement);
    final slotChild = AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      child: ad == null
          ? _AdSlotPlaceholder(
              key: ValueKey('placeholder-${widget.placement.name}'),
              width: size.width.toDouble(),
              height: size.height.toDouble(),
            )
          : SizedBox(
              key: ValueKey('loaded-${widget.placement.name}'),
              width: ad.size.width.toDouble(),
              height: ad.size.height.toDouble(),
              child: AdWidget(ad: ad),
            ),
    );

    final adWidget = Align(alignment: widget.alignment, child: slotChild);
    return widget.builder?.call(context, adWidget) ?? adWidget;
  }
}

class _AdSlotPlaceholder extends StatefulWidget {
  const _AdSlotPlaceholder({
    super.key,
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  State<_AdSlotPlaceholder> createState() => _AdSlotPlaceholderState();
}

class _AdSlotPlaceholderState extends State<_AdSlotPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = widget.height <= 60;

    return ClipRRect(
      borderRadius: BorderRadius.circular(isCompact ? 14 : 20),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1.2 + (t * 2.4), -0.2),
                end: Alignment(-0.2 + (t * 2.4), 0.2),
                colors: const [
                  Color(0xFFECE7E5),
                  Color(0xFFF8F4F3),
                  Color(0xFFECE7E5),
                ],
                stops: const [0.15, 0.5, 0.85],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(isCompact ? 10 : 14),
              child: isCompact
                  ? const _CompactPlaceholderLayout()
                  : const _LargePlaceholderLayout(),
            ),
          );
        },
      ),
    );
  }
}

class _CompactPlaceholderLayout extends StatelessWidget {
  const _CompactPlaceholderLayout();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PlaceholderBox(
          width: 32,
          height: 32,
          radius: 10,
          color: const Color(0x22FFFFFF),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PlaceholderLine(widthFactor: 0.7),
              SizedBox(height: 6),
              _PlaceholderLine(widthFactor: 0.45, opacity: 0.72),
            ],
          ),
        ),
      ],
    );
  }
}

class _LargePlaceholderLayout extends StatelessWidget {
  const _LargePlaceholderLayout();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _PlaceholderLine(widthFactor: 0.34),
        SizedBox(height: 12),
        _PlaceholderBox(width: double.infinity, height: 118, radius: 16),
        SizedBox(height: 12),
        _PlaceholderLine(widthFactor: 0.72),
        SizedBox(height: 8),
        _PlaceholderLine(widthFactor: 0.48, opacity: 0.72),
      ],
    );
  }
}

class _PlaceholderLine extends StatelessWidget {
  const _PlaceholderLine({required this.widthFactor, this.opacity = 1});

  final double widthFactor;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 10,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.46 * opacity),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _PlaceholderBox extends StatelessWidget {
  const _PlaceholderBox({
    required this.width,
    required this.height,
    required this.radius,
    this.color,
  });

  final double width;
  final double height;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? Colors.white.withValues(alpha: 0.44),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
