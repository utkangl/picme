import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A persistent cache that maps asset IDs to file sizes in bytes.
/// Backed by SharedPreferences so values survive app restarts.
class SizeCache {
  SizeCache._();

  static const String _prefsKey = 'picme_size_cache';
  static const int _maxEntries = 5000;

  static Map<String, int>? _memory;

  static Future<Map<String, int>> _load() async {
    if (_memory != null) return _memory!;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) {
      _memory = {};
      return _memory!;
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _memory = decoded.map((k, v) => MapEntry(k, v as int));
    } catch (_) {
      _memory = {};
    }
    return _memory!;
  }

  static Future<void> _persist() async {
    final map = _memory;
    if (map == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(map));
  }

  static Future<int?> get(String assetId) async {
    final map = await _load();
    return map[assetId];
  }

  static Future<void> put(String assetId, int bytes) async {
    final map = await _load();
    map[assetId] = bytes;
    // Evict oldest entries if too large (simple FIFO trim).
    if (map.length > _maxEntries) {
      final keysToRemove = map.keys.take(map.length - _maxEntries).toList();
      for (final k in keysToRemove) {
        map.remove(k);
      }
    }
    await _persist();
  }

  static Future<void> putAll(Map<String, int> entries) async {
    final map = await _load();
    map.addAll(entries);
    if (map.length > _maxEntries) {
      final keysToRemove = map.keys.take(map.length - _maxEntries).toList();
      for (final k in keysToRemove) {
        map.remove(k);
      }
    }
    await _persist();
  }

  static Future<void> remove(String assetId) async {
    final map = await _load();
    map.remove(assetId);
    await _persist();
  }
}
