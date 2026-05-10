import 'dart:convert';

class DeleteHistoryEntry {
  const DeleteHistoryEntry({
    required this.deletedAt,
    required this.count,
    this.bytes = 0,
  });

  final DateTime deletedAt;
  final int count;

  /// Total byte size of the deleted batch. `0` when unknown — older entries
  /// persisted before the field was introduced will deserialize as 0, and
  /// items whose size couldn't be resolved at delete time also fall back to
  /// 0. Cumulative-savings logic in the UI tolerates 0 by ignoring those
  /// entries instead of throwing.
  final int bytes;

  String toJson() => jsonEncode({
    'deletedAt': deletedAt.toIso8601String(),
    'count': count,
    'bytes': bytes,
  });

  static DeleteHistoryEntry? tryParse(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final deletedAt = DateTime.tryParse(
        decoded['deletedAt'] as String? ?? '',
      );
      final count = decoded['count'];
      if (deletedAt == null || count is! int) return null;
      final bytesRaw = decoded['bytes'];
      final bytes = bytesRaw is int
          ? bytesRaw
          : (bytesRaw is num ? bytesRaw.toInt() : 0);
      return DeleteHistoryEntry(
        deletedAt: deletedAt,
        count: count,
        bytes: bytes,
      );
    } catch (_) {
      return null;
    }
  }
}
