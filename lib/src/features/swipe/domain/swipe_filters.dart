import 'package:picme/l10n/app_localizations.dart';

enum GalleryCategory {
  allMedia,
  photos,
  videos,
  screenshots,
  downloads;
}

enum SortOption {
  newestFirst,
  oldestFirst,
  largestSizeFirst;
}

extension GalleryCategoryL10n on GalleryCategory {
  String labelOf(AppLocalizations l10n) {
    switch (this) {
      case GalleryCategory.allMedia:
        return l10n.catAllMedia;
      case GalleryCategory.photos:
        return l10n.catPhotos;
      case GalleryCategory.videos:
        return l10n.catVideos;
      case GalleryCategory.screenshots:
        return l10n.catScreenshots;
      case GalleryCategory.downloads:
        return l10n.catDownloads;
    }
  }
}

extension SortOptionL10n on SortOption {
  String labelOf(AppLocalizations l10n) {
    switch (this) {
      case SortOption.newestFirst:
        return l10n.sortNewest;
      case SortOption.oldestFirst:
        return l10n.sortOldest;
      case SortOption.largestSizeFirst:
        return l10n.sortLargest;
    }
  }
}
