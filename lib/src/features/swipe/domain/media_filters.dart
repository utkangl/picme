/// Immutable filter parameters for gallery media queries.
///
/// [dateOlderThanYears] — only include items with datetaken older than N years.
///   Null means no date filter.
/// [minBytes] — only include items larger than this many bytes.
///   Null means no size filter.
class MediaFilters {
  const MediaFilters({
    this.dateOlderThanYears,
    this.minBytes,
  });

  static const MediaFilters none = MediaFilters();

  final int? dateOlderThanYears;
  final int? minBytes;

  bool get isActive => dateOlderThanYears != null || minBytes != null;

  int get activeCount =>
      (dateOlderThanYears != null ? 1 : 0) + (minBytes != null ? 1 : 0);

  MediaFilters copyWith({
    Object? dateOlderThanYears = _sentinel,
    Object? minBytes = _sentinel,
  }) {
    return MediaFilters(
      dateOlderThanYears: dateOlderThanYears == _sentinel
          ? this.dateOlderThanYears
          : dateOlderThanYears as int?,
      minBytes:
          minBytes == _sentinel ? this.minBytes : minBytes as int?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaFilters &&
          other.dateOlderThanYears == dateOlderThanYears &&
          other.minBytes == minBytes);

  @override
  int get hashCode => Object.hash(dateOlderThanYears, minBytes);
}

const _sentinel = Object();
