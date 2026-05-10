import 'package:flutter/material.dart';
import 'package:picme/l10n/app_localizations.dart';
import 'package:picme/src/features/swipe/domain/media_filters.dart';

/// Presets for the date filter.
enum _DatePreset {
  all,
  oneYear,
  threeYears,
  fiveYears;

  int? toYears() {
    switch (this) {
      case _DatePreset.all:
        return null;
      case _DatePreset.oneYear:
        return 1;
      case _DatePreset.threeYears:
        return 3;
      case _DatePreset.fiveYears:
        return 5;
    }
  }

  static _DatePreset fromYears(int? years) {
    if (years == null) return _DatePreset.all;
    if (years <= 1) return _DatePreset.oneYear;
    if (years <= 3) return _DatePreset.threeYears;
    return _DatePreset.fiveYears;
  }

  String label(AppLocalizations l10n) {
    switch (this) {
      case _DatePreset.all:
        return l10n.filterDateAll;
      case _DatePreset.oneYear:
        return l10n.filterDate1Year;
      case _DatePreset.threeYears:
        return l10n.filterDate3Years;
      case _DatePreset.fiveYears:
        return l10n.filterDate5Years;
    }
  }
}

/// Presets for the file-size filter.
enum _SizePreset {
  all,
  over10mb,
  over50mb,
  over100mb;

  int? toBytes() {
    switch (this) {
      case _SizePreset.all:
        return null;
      case _SizePreset.over10mb:
        return 10 * 1024 * 1024;
      case _SizePreset.over50mb:
        return 50 * 1024 * 1024;
      case _SizePreset.over100mb:
        return 100 * 1024 * 1024;
    }
  }

  static _SizePreset fromBytes(int? bytes) {
    if (bytes == null) return _SizePreset.all;
    if (bytes <= 10 * 1024 * 1024) return _SizePreset.over10mb;
    if (bytes <= 50 * 1024 * 1024) return _SizePreset.over50mb;
    return _SizePreset.over100mb;
  }

  String label(AppLocalizations l10n) {
    switch (this) {
      case _SizePreset.all:
        return l10n.filterSizeAll;
      case _SizePreset.over10mb:
        return l10n.filterSize10MB;
      case _SizePreset.over50mb:
        return l10n.filterSize50MB;
      case _SizePreset.over100mb:
        return l10n.filterSize100MB;
    }
  }
}

/// Shows a modal bottom sheet for configuring [MediaFilters].
///
/// Returns the updated [MediaFilters] when the user taps "Apply", or
/// [null] if the sheet is dismissed without saving.
Future<MediaFilters?> showFiltersSheet(
  BuildContext context,
  MediaFilters current,
) {
  return showModalBottomSheet<MediaFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FiltersSheet(current: current),
  );
}

class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet({required this.current});
  final MediaFilters current;

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late _DatePreset _date;
  late _SizePreset _size;

  @override
  void initState() {
    super.initState();
    _date = _DatePreset.fromYears(widget.current.dateOlderThanYears);
    _size = _SizePreset.fromBytes(widget.current.minBytes);
  }

  void _reset() {
    setState(() {
      _date = _DatePreset.all;
      _size = _SizePreset.all;
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      MediaFilters(
        dateOlderThanYears: _date.toYears(),
        minBytes: _size.toBytes(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: bottom + 12,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
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
                l10n.filterTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 20),
              _SectionLabel(l10n.filterDateLabel),
              const SizedBox(height: 10),
              _ChipRow<_DatePreset>(
                values: _DatePreset.values,
                selected: _date,
                label: (v) => v.label(l10n),
                onSelected: (v) => setState(() => _date = v),
              ),
              const SizedBox(height: 18),
              _SectionLabel(l10n.filterSizeLabel),
              const SizedBox(height: 10),
              _ChipRow<_SizePreset>(
                values: _SizePreset.values,
                selected: _size,
                label: (v) => v.label(l10n),
                onSelected: (v) => setState(() => _size = v),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(
                          color: Colors.black.withValues(alpha: 0.15),
                        ),
                      ),
                      onPressed: _reset,
                      child: Text(l10n.filterReset),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1F1F1F),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _apply,
                      child: Text(l10n.filterApply),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: Color(0xFF8A8A8A),
      ),
    );
  }
}

class _ChipRow<T> extends StatelessWidget {
  const _ChipRow({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in values)
          ChoiceChip(
            label: Text(label(v)),
            selected: v == selected,
            onSelected: (_) => onSelected(v),
            selectedColor: const Color(0xFF1F1F1F),
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: v == selected ? Colors.white : const Color(0xFF1F1F1F),
            ),
            backgroundColor: Colors.black.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: v == selected
                    ? Colors.transparent
                    : Colors.black.withValues(alpha: 0.1),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
      ],
    );
  }
}
