import 'package:photo_manager/photo_manager.dart';
import 'package:picme/src/core/models/media_item.dart';
import 'package:picme/src/features/swipe/domain/swipe_filters.dart';

class GalleryRepository {
  static const int _maxItemsPerLoad = 500;

  Future<PermissionState> requestPermission() {
    return PhotoManager.requestPermissionExtend();
  }

  Future<List<MediaItem>> getMedia({
    required GalleryCategory category,
    required SortOption sortOption,
  }) async {
    final paths = await PhotoManager.getAssetPathList(
      type: _requestType(category),
      filterOption: _buildFilter(sortOption),
      hasAll: true,
    );
    if (paths.isEmpty) return const [];

    final path = _selectPath(paths, category);
    if (path == null) return const [];

    final total = await path.assetCountAsync;
    if (total == 0) return const [];

    final end = total < _maxItemsPerLoad ? total : _maxItemsPerLoad;
    final assets = await path.getAssetListRange(start: 0, end: end);

    if (sortOption == SortOption.largestSizeFirst) {
      return _resolveAndSortBySize(assets);
    }

    return assets.map((asset) => MediaItem(asset: asset)).toList();
  }

  Future<List<String>> deleteItems(List<MediaItem> items) {
    final ids = items.map((item) => item.id).toList();
    return PhotoManager.editor.deleteWithIds(ids);
  }

  Future<List<MediaItem>> getMediaByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final assets = await Future.wait(ids.map(AssetEntity.fromId));
    return assets
        .whereType<AssetEntity>()
        .map((asset) => MediaItem(asset: asset))
        .toList();
  }

  RequestType _requestType(GalleryCategory category) {
    switch (category) {
      case GalleryCategory.photos:
      case GalleryCategory.screenshots:
        return RequestType.image;
      case GalleryCategory.videos:
        return RequestType.video;
      case GalleryCategory.allMedia:
      case GalleryCategory.downloads:
        return RequestType.common;
    }
  }

  FilterOptionGroup _buildFilter(SortOption sortOption) {
    final orders = <OrderOption>[];
    switch (sortOption) {
      case SortOption.newestFirst:
        orders.add(
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        );
        break;
      case SortOption.oldestFirst:
        orders.add(
          const OrderOption(type: OrderOptionType.createDate, asc: true),
        );
        break;
      case SortOption.largestSizeFirst:
        orders.add(
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        );
        break;
    }

    return FilterOptionGroup(
      orders: orders,
      imageOption: const FilterOption(needTitle: true),
      videoOption: const FilterOption(needTitle: true),
    );
  }

  AssetPathEntity? _selectPath(
    List<AssetPathEntity> paths,
    GalleryCategory category,
  ) {
    switch (category) {
      case GalleryCategory.allMedia:
      case GalleryCategory.photos:
      case GalleryCategory.videos:
        return paths.firstWhere((p) => p.isAll, orElse: () => paths.first);
      case GalleryCategory.screenshots:
        return _findPathByName(paths, const ['screenshots', 'screenshot']);
      case GalleryCategory.downloads:
        return _findPathByName(paths, const ['download', 'downloads']);
    }
  }

  AssetPathEntity? _findPathByName(
    List<AssetPathEntity> paths,
    List<String> names,
  ) {
    for (final path in paths) {
      final lower = path.name.toLowerCase();
      if (names.any((target) => lower == target)) {
        return path;
      }
    }
    for (final path in paths) {
      final lower = path.name.toLowerCase();
      if (names.any(lower.contains)) {
        return path;
      }
    }
    return null;
  }

  Future<List<MediaItem>> _resolveAndSortBySize(
    List<AssetEntity> assets,
  ) async {
    final results = await Future.wait(
      assets.map((asset) async {
        try {
          final file = await asset.file;
          final length = file == null ? 0 : await file.length();
          return MediaItem(asset: asset, fileSizeInBytes: length);
        } catch (_) {
          return MediaItem(asset: asset, fileSizeInBytes: 0);
        }
      }),
    );
    results.sort(
      (a, b) => (b.fileSizeInBytes ?? 0).compareTo(a.fileSizeInBytes ?? 0),
    );
    return results;
  }
}
