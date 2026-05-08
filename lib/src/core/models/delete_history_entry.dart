import 'dart:convert';

class DeleteHistoryEntry {
  const DeleteHistoryEntry({required this.deletedAt, required this.count});

  final DateTime deletedAt;
  final int count;

  String toJson() =>
      jsonEncode({'deletedAt': deletedAt.toIso8601String(), 'count': count});

  static DeleteHistoryEntry? tryParse(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final deletedAt = DateTime.tryParse(
        decoded['deletedAt'] as String? ?? '',
      );
      final count = decoded['count'];
      if (deletedAt == null || count is! int) return null;
      return DeleteHistoryEntry(deletedAt: deletedAt, count: count);
    } catch (_) {
      return null;
    }
  }
}
