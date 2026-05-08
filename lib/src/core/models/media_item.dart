import 'package:photo_manager/photo_manager.dart';

enum MediaType { photo, video }

class MediaItem {
  const MediaItem({required this.asset, this.fileSizeInBytes});

  final AssetEntity asset;
  final int? fileSizeInBytes;

  String get id => asset.id;

  String get name {
    final title = asset.title;
    if (title != null && title.isNotEmpty) return title;
    return asset.id;
  }

  MediaType get type =>
      asset.type == AssetType.video ? MediaType.video : MediaType.photo;

  DateTime get createdAt => asset.createDateTime;

  Duration? get videoDuration =>
      type == MediaType.video ? asset.videoDuration : null;

  MediaItem copyWith({int? fileSizeInBytes}) => MediaItem(
    asset: asset,
    fileSizeInBytes: fileSizeInBytes ?? this.fileSizeInBytes,
  );
}
