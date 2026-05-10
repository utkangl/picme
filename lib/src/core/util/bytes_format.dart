/// Formats a byte count into a short, human-readable string.
///
/// - Below 1 MB → KB (rounded)
/// - Below 1 GB → MB (rounded)
/// - 1 GB and above → GB (one decimal)
///
/// Used by home tiles, history savings, and any other place that needs a
/// compact storage label like "1.2 GB" or "640 MB".
String formatBytes(int bytes) {
  if (bytes <= 0) return '0 KB';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}
