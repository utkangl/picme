import 'dart:async';

import 'package:flutter/material.dart';
import 'package:picme/l10n/app_localizations.dart';

enum CoachShape { roundedRect, circle }

class CoachStep {
  const CoachStep({
    required this.targetKey,
    required this.title,
    required this.description,
    this.shape = CoachShape.roundedRect,
    this.padding = const EdgeInsets.all(8),
    this.radius = 16,
  });

  final GlobalKey targetKey;
  final String title;
  final String description;
  final CoachShape shape;
  final EdgeInsets padding;
  final double radius;
}

class AppCoach {
  AppCoach._();

  static OverlayEntry? _entry;
  static _CoachOverlayState? _state;

  static Future<void> show(
    BuildContext context, {
    required List<CoachStep> steps,
  }) async {
    if (steps.isEmpty) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    await dismiss();

    final completer = Completer<void>();
    final entry = OverlayEntry(
      builder: (ctx) => _CoachOverlay(
        steps: steps,
        onMounted: (state) => _state = state,
        onClosed: () {
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
    return completer.future;
  }

  static Future<void> dismiss() async {
    final entry = _entry;
    final state = _state;
    if (entry == null) return;
    _entry = null;
    _state = null;
    if (state != null) {
      await state.close();
    }
    if (entry.mounted) entry.remove();
  }
}

class _CoachOverlay extends StatefulWidget {
  const _CoachOverlay({
    required this.steps,
    required this.onMounted,
    required this.onClosed,
  });

  final List<CoachStep> steps;
  final ValueChanged<_CoachOverlayState> onMounted;
  final VoidCallback onClosed;

  @override
  State<_CoachOverlay> createState() => _CoachOverlayState();
}

class _CoachOverlayState extends State<_CoachOverlay>
    with TickerProviderStateMixin {
  int _index = 0;
  late final AnimationController _fade;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    widget.onMounted(this);
    _fade.forward();
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  Future<void> close() async {
    if (!mounted) return;
    await _fade.reverse();
    widget.onClosed();
  }

  void _next() {
    if (_index >= widget.steps.length - 1) {
      AppCoach.dismiss();
      return;
    }
    setState(() => _index += 1);
  }

  void _skip() {
    AppCoach.dismiss();
  }

  Rect? _resolveTargetRect(CoachStep step) {
    final ctx = step.targetKey.currentContext;
    if (ctx == null) return null;
    final renderObject = ctx.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    final topLeft = renderObject.localToGlobal(Offset.zero);
    return topLeft & renderObject.size;
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final step = widget.steps[_index];
    final rawRect = _resolveTargetRect(step);

    final screenSize = mq.size;
    final paddedRect = rawRect == null
        ? null
        : Rect.fromLTRB(
            rawRect.left - step.padding.left,
            rawRect.top - step.padding.top,
            rawRect.right + step.padding.right,
            rawRect.bottom + step.padding.bottom,
          );

    return FadeTransition(
      opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _next,
            child: CustomPaint(
              size: Size.infinite,
              painter: _SpotlightPainter(
                targetRect: paddedRect,
                shape: step.shape,
                radius: step.radius,
                color: Colors.black.withValues(alpha: 0.62),
              ),
            ),
          ),
          if (paddedRect != null)
            Positioned.fromRect(
              rect: paddedRect,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: step.shape == CoachShape.circle
                        ? null
                        : BorderRadius.circular(step.radius),
                    shape: step.shape == CoachShape.circle
                        ? BoxShape.circle
                        : BoxShape.rectangle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.95),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.18),
                        blurRadius: 24,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          _buildTooltip(step, paddedRect, screenSize, mq),
          Positioned(
            top: mq.padding.top + 8,
            right: 12,
            child: TextButton(
              onPressed: _skip,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: Text(AppLocalizations.of(context)!.coachSkip),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTooltip(
    CoachStep step,
    Rect? targetRect,
    Size screenSize,
    MediaQueryData mq,
  ) {
    final tooltip = _CoachTooltip(
      title: step.title,
      description: step.description,
      stepIndex: _index,
      stepCount: widget.steps.length,
      onNext: _next,
    );

    if (targetRect == null) {
      return Center(
        child: Padding(padding: const EdgeInsets.all(24), child: tooltip),
      );
    }

    final spaceBelow =
        screenSize.height - targetRect.bottom - mq.padding.bottom;
    final spaceAbove = targetRect.top - mq.padding.top;
    final placeBelow = spaceBelow >= 180 || spaceBelow >= spaceAbove;

    return Positioned(
      left: 16,
      right: 16,
      top: placeBelow ? targetRect.bottom + 16 : null,
      bottom: placeBelow ? null : screenSize.height - targetRect.top + 16,
      child: tooltip,
    );
  }
}

class _CoachTooltip extends StatelessWidget {
  const _CoachTooltip({
    required this.title,
    required this.description,
    required this.stepIndex,
    required this.stepCount,
    required this.onNext,
  });

  final String title;
  final String description;
  final int stepIndex;
  final int stepCount;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isLast = stepIndex >= stepCount - 1;
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),
                Text(
                  '${stepIndex + 1}/$stepCount',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 14,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: onNext,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(isLast ? l10n.coachDone : l10n.coachNext),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({
    required this.targetRect,
    required this.shape,
    required this.radius,
    required this.color,
  });

  final Rect? targetRect;
  final CoachShape shape;
  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Offset.zero & size;
    final paint = Paint()..color = color;

    if (targetRect == null) {
      canvas.drawRect(fullRect, paint);
      return;
    }

    canvas.saveLayer(fullRect, Paint());
    canvas.drawRect(fullRect, paint);
    final clearPaint = Paint()..blendMode = BlendMode.clear;
    if (shape == CoachShape.circle) {
      final center = targetRect!.center;
      final r = (targetRect!.shortestSide / 2) + 4;
      canvas.drawCircle(center, r, clearPaint);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(targetRect!, Radius.circular(radius)),
        clearPaint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.shape != shape ||
        oldDelegate.radius != radius ||
        oldDelegate.color != color;
  }
}
