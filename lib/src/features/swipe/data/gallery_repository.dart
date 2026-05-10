import 'dart:io';

import 'package:photo_manager/photo_manager.dart';
import 'package:picme/src/core/data/size_cache.dart';
import 'package:picme/src/core/models/media_item.dart';
import 'package:picme/src/features/swipe/domain/swipe_filters.dart';

class GalleryRepository {
  static const int defaultPageSize = 200;

  Future<PermissionState> requestPermission() {
    return PhotoManager.requestPermissionExtend();
  }

  Future<void> presentLimited() {
    return PhotoManager.presentLimited();
  }

  Future<int> getCount(GalleryCategory category) async {
    final paths = await PhotoManager.getAssetPathList(
      type: _requestType(category),
      hasAll: true,
    );
    if (paths.isEmpty) return 0;
    final path = _selectPath(paths, category);
    if (path == null) return 0;
    return path.assetCountAsync;
  }

  Future<List<MediaItem>> getMedia({
    required GalleryCategory category,
    required SortOption sortOption,
    int page = 0,
    int pageSize = defaultPageSize,
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

    final start = page * pageSize;
    if (start >= total) return const [];
    final end = (start + pageSize).clamp(0, total);

    final assets = await path.getAssetListRange(start: start, end: end);
    return assets.map((asset) => MediaItem(asset: asset)).toList();
  }

  /// Resolves and persists `fileSizeInBytes` for the given items by reading
  /// the underlying file once and writing all resolved values to [SizeCache]
  /// in a single batch. Items already carrying a size are left untouched.
  ///
  /// Used for showing the "X MB" label on swipe cards: the home screen warms
  /// the first few items in the deck after a fetch so the user immediately
  /// sees how much space each card takes up.
  Future<List<MediaItem>> warmSizes(List<MediaItem> items) async {
    if (items.isEmpty) return items;

    final cachedFutures = items.map((m) => SizeCache.get(m.asset.id));
    final cachedValues = await Future.wait(cachedFutures);

    final missingIdx = <int>[];
    for (var i = 0; i < items.length; i++) {
      if (items[i].fileSizeInBytes == null && cachedValues[i] == null) {
        missingIdx.add(i);
      }
    }

    if (missingIdx.isNotEmpty) {
      final resolved = await Future.wait(
        missingIdx.map((i) async {
          try {
            final file = await items[i].asset.file;
            return file == null ? 0 : await file.length();
          } catch (_) {
            return 0;
          }
        }),
      );
      final newEntries = <String, int>{};
      for (var k = 0; k < missingIdx.length; k++) {
        final i = missingIdx[k];
        newEntries[items[i].asset.id] = resolved[k];
        cachedValues[i] = resolved[k];
      }
      await SizeCache.putAll(newEntries);
    }

    return [
      for (var i = 0; i < items.length; i++)
        items[i].fileSizeInBytes != null
            ? items[i]
            : items[i].copyWith(fileSizeInBytes: cachedValues[i] ?? 0),
    ];
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

  PMFilter _buildFilter(SortOption sortOption) {
    if (Platform.isAndroid) return _buildAndroidFilter(sortOption);
    return _buildLegacyFilter(sortOption);
  }

  // Android: query MediaStore directly via CustomFilter so we sort by
  // `datetaken` (real EXIF capture date) and `_size` (actual byte length)
  // instead of the misleading `date_added` (= when MediaStore indexed the
  // file, e.g. during a Drive restore). NULL `datetaken` rows are pushed to
  // the end of an "oldest first" sort using the `(col IS NULL) ASC` trick.
  PMFilter _buildAndroidFilter(SortOption sortOption) {
    final col = CustomColumns.android;
    final orderBy = <OrderByItem>[];
    switch (sortOption) {
      case SortOption.newestFirst:
        orderBy.add(OrderByItem('${col.dateTaken} IS NULL', true));
        orderBy.add(OrderByItem.desc(col.dateTaken));
        orderBy.add(OrderByItem.desc(col.createDate));
        break;
      case SortOption.oldestFirst:
        orderBy.add(OrderByItem('${col.dateTaken} IS NULL', true));
        orderBy.add(OrderByItem.asc(col.dateTaken));
        orderBy.add(OrderByItem.asc(col.createDate));
        break;
      case SortOption.largestSizeFirst:
        orderBy.add(OrderByItem.desc(col.size));
        orderBy.add(OrderByItem.desc(col.dateTaken));
        break;
    }
    return CustomFilter.sql(where: '', orderBy: orderBy)..needTitle = true;
  }

  FilterOptionGroup _buildLegacyFilter(SortOption sortOption) {
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
        // No native byte-size sort on iOS PHFetchOptions; fall back to
        // newest-first so the UI is at least deterministic on iOS.
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
}
