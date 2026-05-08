import 'package:picme/src/core/models/media_item.dart';

enum SwipeAction { keep, delete }

class SwipeActionRecord {
  const SwipeActionRecord({
    required this.item,
    required this.action,
    this.wasAlreadyKept = false,
  });

  final MediaItem item;
  final SwipeAction action;

  /// Sağa atılan item zaten kept set'te miydi (kalıcı). Revert sırasında
  /// kept'ten çıkarmamak için kullanılır.
  final bool wasAlreadyKept;
}
