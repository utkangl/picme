enum GalleryCategory {
  allMedia('All Media'),
  photos('Photos'),
  videos('Videos'),
  screenshots('Screenshots'),
  downloads('Downloads');

  const GalleryCategory(this.label);
  final String label;
}

enum SortOption {
  newestFirst('Newest First'),
  oldestFirst('Oldest First'),
  largestSizeFirst('Largest Size First');

  const SortOption(this.label);
  final String label;
}
