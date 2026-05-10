import 'package:flutter/material.dart';
import 'package:picme/l10n/app_localizations.dart';

/// Full-screen onboarding overlay shown the first time a user enters the
/// swipe deck. Demonstrates the left-to-delete / right-to-keep gesture with
/// an animated mini-card and tinted intent badges, instead of trying to
/// spotlight the live deck (which left the prior coach card half-cropped).
class SwipeIntroOverlay extends StatefulWidget {
  const SwipeIntroOverlay({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<SwipeIntroOverlay> createState() => _SwipeIntroOverlayState();
}

class _SwipeIntroOverlayState extends State<SwipeIntroOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mq = MediaQuery.of(context);

    return Material(
      color: Colors.black.withValues(alpha: 0.78),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onDone,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: Text(l10n.coachSkip),
                ),
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return _SwipeDemo(
                      progress: _controller.value,
                      maxWidth: mq.size.width - 40,
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.coachSwipeDecideTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.coachSwipeDecideDesc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.86),
                  fontSize: 14.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: widget.onDone,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(l10n.swipeIntroCta),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animation cycle:
///   0.00 - 0.18  card sits centered, idle
///   0.18 - 0.40  card swings RIGHT (keep), green tint grows
///   0.40 - 0.55  card snaps back to center
///   0.55 - 0.77  card swings LEFT (delete), red tint grows
///   0.77 - 1.00  card returns to center, brief idle
class _SwipeDemo extends StatelessWidget {
  const _SwipeDemo({required this.progress, required this.maxWidth});

  final double progress;
  final double maxWidth;

  double _cardDx() {
    final p = progress;
    const peak = 0.45;
    if (p < 0.18) return 0;
    if (p < 0.40) {
      final t = (p - 0.18) / (0.40 - 0.18);
      return Curves.easeOut.transform(t) * peak;
    }
    if (p < 0.55) {
      final t = (p - 0.40) / (0.55 - 0.40);
      return peak * (1 - Curves.easeIn.transform(t));
    }
    if (p < 0.77) {
      final t = (p - 0.55) / (0.77 - 0.55);
      return -Curves.easeOut.transform(t) * peak;
    }
    final t = (p - 0.77) / (1.0 - 0.77);
    return -peak * (1 - Curves.easeIn.transform(t));
  }

  @override
  Widget build(BuildContext context) {
    final dxRatio = _cardDx();
    final translation = dxRatio * (maxWidth * 0.55);
    final rotation = dxRatio * 0.22;
    final keepActive = dxRatio > 0.05;
    final deleteActive = dxRatio < -0.05;
    final intent = dxRatio.abs().clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth * 0.66).clamp(220.0, 340.0);
        final cardHeight = (constraints.maxHeight * 0.78).clamp(280.0, 480.0);

        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 8,
              child: _IntentBadge(
                label: AppLocalizations.of(context)!.deleteLabel,
                icon: Icons.close_rounded,
                color: const Color(0xFFE74C3C),
                active: deleteActive,
                intensity: deleteActive ? intent : 0,
              ),
            ),
            Positioned(
              right: 8,
              child: _IntentBadge(
                label: AppLocalizations.of(context)!.keep,
                icon: Icons.favorite_rounded,
                color: const Color(0xFF2BA94E),
                active: keepActive,
                intensity: keepActive ? intent : 0,
              ),
            ),
            Transform.translate(
              offset: Offset(translation, 0),
              child: Transform.rotate(
                angle: rotation,
                child: _DemoCard(
                  width: cardWidth,
                  height: cardHeight,
                  intent: intent,
                  keep: keepActive,
                ),
              ),
            ),
            Positioned(
              left: cardWidth / 2 + translation - 14,
              top: cardHeight * 0.5 - 14,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: intent < 0.05 ? 0 : 1,
                child: const _FingerDot(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DemoCard extends StatelessWidget {
  const _DemoCard({
    required this.width,
    required this.height,
    required this.intent,
    required this.keep,
  });

  final double width;
  final double height;
  final double intent;
  final bool keep;

  @override
  Widget build(BuildContext context) {
    final tint = keep
        ? const Color(0xFF2BA94E).withValues(alpha: 0.10 + intent * 0.22)
        : const Color(0xFFE74C3C).withValues(alpha: 0.12 + intent * 0.28);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE9D6DA), Color(0xFFC9B7C9), Color(0xFF7E6F86)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _CardArtworkPainter()),
            if (intent > 0.05)
              ColoredBox(color: tint),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.34),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 12,
                      width: 110,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 8,
                      width: 70,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardArtworkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.18);

    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.28),
      size.shortestSide * 0.18,
      paint,
    );

    final mountainPaint = Paint()..color = Colors.white.withValues(alpha: 0.10);
    final path = Path()
      ..moveTo(0, size.height * 0.78)
      ..lineTo(size.width * 0.32, size.height * 0.42)
      ..lineTo(size.width * 0.55, size.height * 0.62)
      ..lineTo(size.width * 0.78, size.height * 0.36)
      ..lineTo(size.width, size.height * 0.58)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, mountainPaint);
  }

  @override
  bool shouldRepaint(covariant _CardArtworkPainter oldDelegate) => false;
}

class _IntentBadge extends StatelessWidget {
  const _IntentBadge({
    required this.label,
    required this.icon,
    required this.color,
    required this.active,
    required this.intensity,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool active;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final scale = 1.0 + (active ? intensity * 0.18 : 0.0);
    final opacity = active ? (0.6 + intensity * 0.4) : 0.32;

    return AnimatedScale(
      duration: const Duration(milliseconds: 220),
      scale: scale,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: opacity,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color, width: 2),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.45),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ]
                : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FingerDot extends StatelessWidget {
  const _FingerDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(
        Icons.touch_app_rounded,
        color: Colors.black87,
        size: 16,
      ),
    );
  }
}
