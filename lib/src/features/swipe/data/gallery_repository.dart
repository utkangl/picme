import 'dart:io';

import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:picme/src/core/data/size_cache.dart';
import 'package:picme/src/core/models/media_item.dart';
import 'package:picme/src/features/swipe/domain/media_filters.dart';
import 'package:picme/src/features/swipe/domain/swipe_filters.dart';

class GalleryRepository {
  static const int defaultPageSize = 200;

  static const _sizeChannel = MethodChannel('picme/media_size');

  /// Returns the total byte size of all media in [category] (or, when
  /// [folderPathId] is provided, the size of that specific bucket). Uses a
  /// native MediaStore aggregate query on Android — much faster than
  /// resolving each [AssetEntity]'s file individually. On other platforms
  /// this returns `0`.
  Future<int> getCategoryBytes(
    GalleryCategory category, {
    String? folderPathId,
  }) async {
    if (!Platform.isAndroid) return 0;

    String? bucketId = folderPathId;
    int mediaType;

    if (bucketId == null) {
      switch (category) {
        case GalleryCategory.allMedia:
          mediaType = 0;
          break;
        case GalleryCategory.photos:
          mediaType = 1;
          break;
        case GalleryCategory.videos:
          mediaType = 3;
          break;
        case GalleryCategory.screenshots:
        case GalleryCategory.downloads:
          final paths = await PhotoManager.getAssetPathList(
            type: _requestType(category),
            hasAll: false,
          );
          final selected = _selectPath(paths, category);
          if (selected == null) return 0;
          bucketId = selected.id;
          mediaType = category == GalleryCategory.screenshots ? 1 : 0;
          break;
      }
    } else {
      mediaType = 0;
    }

    try {
      final result = await _sizeChannel.invokeMethod<num>(
        'getBucketSize',
        {'bucketId': bucketId, 'mediaType': mediaType},
      );
      return (result ?? 0).toInt();
    } catch (_) {
      return 0;
    }
  }

  Future<PermissionState> requestPermission() {
    return PhotoManager.requestPermissionExtend();
  }

  Future<void> presentLimited() {
    return PhotoManager.presentLimited();
  }

  Future<int> getCount(GalleryCategory category, {String? folderPathId}) async {
    final type = folderPathId != null
        ? RequestType.common
        : _requestType(category);
    final paths = await PhotoManager.getAssetPathList(
      type: type,
      hasAll: folderPathId == null,
    );
    if (paths.isEmpty) return 0;
    final path = _selectPath(paths, category, folderPathId: folderPathId);
    if (path == null) return 0;
    return path.assetCountAsync;
  }

  /// Returns true if the named folder for [category] actually exists on the
  /// device. For allMedia/photos/videos this is always true when permission is
  /// granted; for Screenshots and Downloads it depends on the folder name.
  /// When [folderPathId] is provided, this checks for that specific folder
  /// instead.
  Future<bool> categoryExists(
    GalleryCategory category, {
    String? folderPathId,
  }) async {
    if (folderPathId == null &&
        (category == GalleryCategory.allMedia ||
            category == GalleryCategory.photos ||
            category == GalleryCategory.videos)) {
      return true;
    }
    final type = folderPathId != null
        ? RequestType.common
        : _requestType(category);
    final paths = await PhotoManager.getAssetPathList(
      type: type,
      hasAll: false,
    );
    return _selectPath(paths, category, folderPathId: folderPathId) != null;
  }

  /// Returns all non-empty media folders (buckets) discovered on the device,
  /// sorted by item count descending. Used to surface app-specific folders
  /// (Camera, WhatsApp, Snapchat, Telegram, Instagram, etc.) as dynamic
  /// categories in the home grid.
  Future<List<({AssetPathEntity entity, int count})>> getFolders() async {
    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      hasAll: false,
    );
    final results = <({AssetPathEntity entity, int count})>[];
    for (final p in paths) {
      final count = await p.assetCountAsync;
      if (count > 0) {
        results.add((entity: p, count: count));
      }
    }
    results.sort((a, b) => b.count.compareTo(a.count));
    return results;
  }

  Future<List<MediaItem>> getMedia({
    required GalleryCategory category,
    required SortOption sortOption,
    int page = 0,
    int pageSize = defaultPageSize,
    MediaFilters filters = MediaFilters.none,
    String? folderPathId,
  }) async {
    final type = folderPathId != null
        ? RequestType.common
        : _requestType(category);
    final paths = await PhotoManager.getAssetPathList(
      type: type,
      filterOption: _buildFilter(sortOption, filters),
      hasAll: folderPathId == null,
    );
    if (paths.isEmpty) return const [];

    final path = _selectPath(paths, category, folderPathId: folderPathId);
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

  PMFilter _buildFilter(SortOption sortOption, MediaFilters filters) {
    if (Platform.isAndroid) return _buildAndroidFilter(sortOption, filters);
    return _buildLegacyFilter(sortOption);
  }

  // Android: query MediaStore directly via CustomFilter so we sort by
  // `datetaken` (real EXIF capture date) when present, falling back to
  // `date_added * 1000` so files without EXIF metadata (WhatsApp media,
  // cloud-restored, screenshots) still show up in the right chronological
  // place — without the previous bug that pushed them to the end of the
  // deck. The size-based sort uses `_size` (actual byte length).
  PMFilter _buildAndroidFilter(SortOption sortOption, MediaFilters filters) {
    final col = CustomColumns.android;
    // Effective timestamp expression in milliseconds: real capture time when
    // available, else MediaStore-add time (in seconds → multiply by 1000).
    final effectiveDate =
        'COALESCE(${col.dateTaken}, ${col.createDate} * 1000)';
    final orderBy = <OrderByItem>[];
    switch (sortOption) {
      case SortOption.newestFirst:
        orderBy.add(OrderByItem(effectiveDate, false));
        break;
      case SortOption.oldestFirst:
        orderBy.add(OrderByItem(effectiveDate, true));
        break;
      case SortOption.largestSizeFirst:
        orderBy.add(OrderByItem.desc(col.size));
        orderBy.add(OrderByItem(effectiveDate, false));
        break;
    }

    // Build WHERE clause from active filters.
    final whereParts = <String>[];
    if (filters.dateOlderThanYears != null) {
      final cutoff = DateTime.now()
          .subtract(Duration(days: 365 * filters.dateOlderThanYears!));
      final cutoffMs = cutoff.millisecondsSinceEpoch;
      // datetaken (EXIF capture time) is NULL for many files (cloud-restored,
      // transferred, screenshots, etc.). Fall back to date_added (in seconds
      // → multiply by 1000) so the filter matches files we have no EXIF for.
      whereParts.add(
        'COALESCE(${col.dateTaken}, ${col.createDate} * 1000) < $cutoffMs',
      );
    }
    if (filters.minBytes != null) {
      whereParts.add('${col.size} > ${filters.minBytes}');
    }
    final where = whereParts.join(' AND ');

    return CustomFilter.sql(where: where, orderBy: orderBy)..needTitle = true;
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
    GalleryCategory category, {
    String? folderPathId,
  }) {
    if (folderPathId != null) {
      for (final p in paths) {
        if (p.id == folderPathId) return p;
      }
      return null;
    }
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
