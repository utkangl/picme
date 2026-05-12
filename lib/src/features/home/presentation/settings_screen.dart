import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:picme/l10n/app_localizations.dart';
import 'package:picme/src/app/app_locale_controller.dart';
import 'package:picme/src/core/config/external_links.dart';
import 'package:picme/src/core/data/review_prompter.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.queueCount,
    required this.keptCount,
    required this.onClearQueue,
    required this.onResetKept,
    required this.onViewKept,
  });

  final int queueCount;
  final int keptCount;
  final VoidCallback onClearQueue;
  final VoidCallback onResetKept;
  final Future<void> Function() onViewKept;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Local mirrors of the parent counts. The settings screen is pushed as a
  // separate route, so when the parent calls `setState` after we invoke
  // `onResetKept` / `onClearQueue`, this route does not rebuild on its own —
  // we have to track the values locally and update them after each action.
  late int _keptCount = widget.keptCount;
  late int _queueCount = widget.queueCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          physics: const ClampingScrollPhysics(),
          children: [
            _SettingsHeader(title: l10n.settingsTitle),
            const SizedBox(height: 22),

            _SectionLabel(text: l10n.settingsSectionPermissions),
            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.lock_open_rounded,
                  iconBg: const Color(0xFFE6DFFF),
                  iconFg: const Color(0xFF6E5BC7),
                  title: l10n.galleryPermTitle,
                  subtitle: l10n.galleryPermSubtitle,
                  trailing: Icons.open_in_new_rounded,
                  onTap: PhotoManager.openSetting,
                ),
              ],
            ),
            const SizedBox(height: 20),

            _SectionLabel(text: l10n.settingsSectionLanguage),
            ValueListenableBuilder<Locale?>(
              valueListenable: AppLocaleController.locale,
              builder: (context, selectedLocale, _) {
                return _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.translate_rounded,
                      iconBg: const Color(0xFFE5E5EA),
                      iconFg: const Color(0xFF1F1F1F),
                      title: l10n.languageTitle,
                      subtitle: _localeLabel(l10n, selectedLocale),
                      trailing: Icons.chevron_right_rounded,
                      onTap: () => _showLanguageSheet(context, l10n),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            _SectionLabel(text: l10n.settingsSectionData),
            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.delete_sweep_rounded,
                  iconBg: const Color(0xFFFFE2E5),
                  iconFg: const Color(0xFFD45D6E),
                  title: l10n.clearQueueTitle,
                  subtitle: l10n.clearQueueSubtitle(_queueCount),
                  enabled: _queueCount > 0,
                  onTap: () => _confirm(
                    context,
                    l10n: l10n,
                    title: l10n.clearQueueDialogTitle,
                    body: l10n.clearQueueDialogBody,
                    confirmLabel: l10n.clearQueueConfirm,
                    onConfirm: () {
                      widget.onClearQueue();
                      setState(() => _queueCount = 0);
                    },
                    successText: l10n.clearQueueSuccess,
                  ),
                ),
                _SettingsDivider(),
                _SettingsTile(
                  icon: Icons.favorite_rounded,
                  iconBg: const Color(0xFFFCE3DA),
                  iconFg: const Color(0xFFE07A5F),
                  title: l10n.viewKeptTitle,
                  subtitle: l10n.viewKeptSubtitle(_keptCount),
                  enabled: _keptCount > 0,
                  trailing: Icons.chevron_right_rounded,
                  onTap: () async {
                    await widget.onViewKept();
                    if (!mounted) return;
                  },
                ),
                _SettingsDivider(),
                _SettingsTile(
                  icon: Icons.restart_alt_rounded,
                  iconBg: const Color(0xFFD9ECFF),
                  iconFg: const Color(0xFF3D7CC9),
                  title: l10n.resetKeptTitle,
                  subtitle: _keptCount == 0
                      ? l10n.resetKeptSubtitleEmpty
                      : l10n.resetKeptSubtitle(_keptCount),
                  enabled: _keptCount > 0,
                  onTap: () => _confirm(
                    context,
                    l10n: l10n,
                    title: l10n.resetKeptDialogTitle,
                    body: l10n.resetKeptDialogBody,
                    confirmLabel: l10n.resetKeptConfirm,
                    onConfirm: () {
                      widget.onResetKept();
                      setState(() => _keptCount = 0);
                    },
                    successText: l10n.resetKeptSuccess,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _SectionLabel(text: l10n.settingsSectionGuide),
            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.help_outline_rounded,
                  iconBg: const Color(0xFFD8F0E0),
                  iconFg: const Color(0xFF3F9E68),
                  title: l10n.restartTourTitle,
                  subtitle: l10n.restartTourSubtitle,
                  trailing: Icons.chevron_right_rounded,
                  onTap: () => Navigator.of(context).pop('restart_tour'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _SectionLabel(text: l10n.settingsSectionAbout),
            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.star_rounded,
                  iconBg: const Color(0xFFFFF3E0),
                  iconFg: const Color(0xFFF59E0B),
                  title: l10n.rateAppTitle,
                  subtitle: l10n.rateAppSubtitle,
                  trailing: Icons.chevron_right_rounded,
                  onTap: ReviewPrompter.requestReviewOrOpenStore,
                ),
                _SettingsTile(
                  icon: Icons.mail_outline_rounded,
                  iconBg: const Color(0xFFE3F2FD),
                  iconFg: const Color(0xFF2196F3),
                  title: l10n.feedbackTitle,
                  subtitle: l10n.feedbackSubtitle,
                  trailing: Icons.open_in_new_rounded,
                  onTap: () => launchUrl(
                    Uri.parse(
                      'mailto:utkangul994@gmail.com?subject=Picme%20feedback',
                    ),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                _SettingsTile(
                  icon: Icons.campaign_rounded,
                  iconBg: const Color(0xFFFFF1E7),
                  iconFg: const Color(0xFFE07A5F),
                  title: l10n.adsDisclosureTitle,
                  subtitle: l10n.adsDisclosureSubtitle,
                  trailing: Icons.open_in_new_rounded,
                  onTap: () => launchUrl(
                    Uri.parse(privacyPolicyUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                _SettingsDivider(),
                _SettingsTile(
                  icon: Icons.privacy_tip_rounded,
                  iconBg: const Color(0xFFE5E5EA),
                  iconFg: const Color(0xFF1F1F1F),
                  title: l10n.privacyPolicyTitle,
                  subtitle: l10n.privacyPolicySubtitle,
                  trailing: Icons.open_in_new_rounded,
                  onTap: () => launchUrl(
                    Uri.parse(privacyPolicyUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Text(
                    l10n.appTitle.toLowerCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      color: Color(0xFF1F1F1F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.settingsAbout,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF1F1F1F).withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm(
    BuildContext context, {
    required AppLocalizations l10n,
    required String title,
    required String body,
    required String confirmLabel,
    required String successText,
    required VoidCallback onConfirm,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1F1F1F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      onConfirm();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successText)));
    }
  }

  Future<void> _showLanguageSheet(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final options = <({Locale? locale, String label})>[
      (locale: null, label: l10n.languageSystem),
      (locale: const Locale('tr'), label: l10n.languageTurkish),
      (locale: const Locale('en'), label: l10n.languageEnglish),
    ];
    final currentCode = AppLocaleController.locale.value?.languageCode;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.languageTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final option in options)
                    Builder(
                      builder: (context) {
                        final isSelected =
                            option.locale == null && currentCode == null ||
                            option.locale?.languageCode == currentCode;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(option.label),
                          trailing: isSelected
                              ? const Icon(Icons.check_rounded)
                              : null,
                          onTap: () async {
                            await AppLocaleController.setLocale(option.locale);
                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop();
                            }
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _localeLabel(AppLocalizations l10n, Locale? locale) {
    switch (locale?.languageCode) {
      case 'tr':
        return l10n.languageTurkish;
      case 'en':
        return l10n.languageEnglish;
      default:
        return l10n.languageSystem;
    }
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: Colors.white.withValues(alpha: 0.7),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.of(context).maybePop(),
            child: const SizedBox(
              width: 42,
              height: 42,
              child: Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: Color(0xFF1F1F1F),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: Color(0xFF1F1F1F),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Color(0xFF8A8A8A),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 64),
      child: Divider(height: 1, thickness: 1, color: Color(0x10000000)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String title;
  final String subtitle;
  final IconData? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final disabled = !enabled || onTap == null;
    return InkWell(
      onTap: disabled ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: disabled ? const Color(0xFFEFEFEF) : iconBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                size: 18,
                color: disabled ? const Color(0xFFB0B0B0) : iconFg,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      color: disabled
                          ? const Color(0xFFA0A0A0)
                          : const Color(0xFF1F1F1F),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      color: disabled
                          ? const Color(0xFFB8B8B8)
                          : const Color(0xFF8A8A8A),
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              Icon(
                trailing,
                size: 18,
                color: disabled
                    ? const Color(0xFFC8C8C8)
                    : const Color(0xFF8A8A8A),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
