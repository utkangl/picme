import 'dart:async';

import 'package:flutter/material.dart';

class PicmeToast {
  PicmeToast._();

  static OverlayEntry? _entry;
  static Timer? _timer;
  static _PicmeToastState? _activeState;

  static void show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 1800),
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _dismissImmediate();

    final entry = OverlayEntry(
      builder: (ctx) => _PicmeToast(
        message: message,
        actionLabel: actionLabel,
        onAction: () {
          onAction?.call();
          _dismissAnimated();
        },
        onMounted: (state) => _activeState = state,
      ),
    );
    _entry = entry;
    overlay.insert(entry);

    _timer = Timer(duration, _dismissAnimated);
  }

  static void _dismissAnimated() {
    _timer?.cancel();
    _timer = null;
    final state = _activeState;
    final entry = _entry;
    _activeState = null;
    if (state == null || entry == null) {
      _dismissImmediate();
      return;
    }
    state.hide().whenComplete(() {
      if (entry.mounted) entry.remove();
      if (_entry == entry) _entry = null;
    });
  }

  static void _dismissImmediate() {
    _timer?.cancel();
    _timer = null;
    _activeState = null;
    final entry = _entry;
    _entry = null;
    if (entry != null && entry.mounted) entry.remove();
  }
}

class _PicmeToast extends StatefulWidget {
  const _PicmeToast({
    required this.message,
    required this.onMounted,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final ValueChanged<_PicmeToastState> onMounted;

  @override
  State<_PicmeToast> createState() => _PicmeToastState();
}

class _PicmeToastState extends State<_PicmeToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    widget.onMounted(this);
    _controller.forward();
  }

  Future<void> hide() => _controller.reverse();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Positioned(
      left: 16,
      right: 16,
      bottom: mq.padding.bottom + 24,
      child: IgnorePointer(
        ignoring: false,
        child: FadeTransition(
          opacity: _opacity,
          child: SlideTransition(
            position: _offset,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.actionLabel != null) ...[
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: widget.onAction,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: Text(
                            widget.actionLabel!.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF7CC8FF),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
