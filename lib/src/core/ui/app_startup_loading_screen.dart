import 'package:flutter/material.dart';
import 'package:picme/l10n/app_localizations.dart';

class AppStartupLoadingScreen extends StatelessWidget {
  const AppStartupLoadingScreen({super.key, this.subtitle});

  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bodyText = subtitle ?? l10n.startupLoadingSubtitle;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.58),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 28,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _LoadingLogo(),
                    const SizedBox(height: 22),
                    Text(
                      l10n.startupLoadingTitle,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: Color(0xFF1F1F1F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bodyText,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: const Color(0xFF1F1F1F).withValues(alpha: 0.68),
                      ),
                    ),
                    const SizedBox(height: 22),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: const LinearProgressIndicator(
                        minHeight: 5,
                        backgroundColor: Color(0x14000000),
                        valueColor: AlwaysStoppedAnimation(Color(0xFF1F1F1F)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _LoadingStep(label: l10n.startupLoadingStepState),
                    const SizedBox(height: 10),
                    _LoadingStep(label: l10n.startupLoadingStepGallery),
                    const SizedBox(height: 10),
                    _LoadingStep(label: l10n.startupLoadingStepExperience),
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

class _LoadingLogo extends StatelessWidget {
  const _LoadingLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Text(
          'P',
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _LoadingStep extends StatelessWidget {
  const _LoadingStep({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFFEFE7E5),
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.circle, size: 10, color: Color(0xFF1F1F1F)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F1F1F).withValues(alpha: 0.72),
            ),
          ),
        ),
      ],
    );
  }
}
