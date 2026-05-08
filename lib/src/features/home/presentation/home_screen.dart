import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:picme/src/core/models/delete_history_entry.dart';
import 'package:picme/src/core/models/media_item.dart';
import 'package:picme/src/core/models/swipe_action_record.dart';
import 'package:picme/src/core/ui/app_coach.dart';
import 'package:picme/src/features/home/presentation/history_screen.dart';
import 'package:picme/src/features/home/presentation/settings_screen.dart';
import 'package:picme/src/features/queue/presentation/delete_queue_screen.dart';
import 'package:picme/src/features/swipe/data/gallery_repository.dart';
import 'package:picme/src/features/swipe/domain/swipe_filters.dart';
import 'package:picme/src/features/swipe/presentation/swipe_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _queuePrefsKey = 'picme_delete_queue_ids';
  static const String _historyPrefsKey = 'picme_delete_history';
  static const String _keptPrefsKey = 'picme_kept_ids';
  static const String _homeTourPrefsKey = 'picme_home_tour_done';
  static const String _swipeTourPrefsKey = 'picme_swipe_tour_done';

  final GalleryRepository _repo = GalleryRepository();
  final List<MediaItem> _deleteQueue = [];
  final List<DeleteHistoryEntry> _deleteHistory = [];
  final Set<String> _keptIds = <String>{};
  final List<SwipeActionRecord> _actionHistory = [];

  final GlobalKey _settingsKey = GlobalKey(debugLabel: 'home-settings');
  final GlobalKey _historyKey = GlobalKey(debugLabel: 'home-history');
  final GlobalKey _firstCategoryKey = GlobalKey(debugLabel: 'home-first-cat');
  final GlobalKey _reviewNavKey = GlobalKey(debugLabel: 'home-review-nav');

  GalleryCategory _selectedCategory = GalleryCategory.allMedia;
  SortOption _selectedSort = SortOption.newestFirst;
  _AppView _view = _AppView.home;

  List<MediaItem> _media = [];
  List<MediaItem> _recent = [];
  Map<GalleryCategory, int> _counts = {
    for (final c in GalleryCategory.values) c: 0,
  };
  bool _isLoading = true;
  PermissionState? _permissionState;
  String? _errorMessage;

  Set<String> get _queueIds => _deleteQueue.map((item) => item.id).toSet();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    AppCoach.dismiss();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _loadHistory();
    await _loadKeptIds();
    final state = await _repo.requestPermission();
    if (!mounted) return;
    setState(() => _permissionState = state);

    if (state.isAuth || state.hasAccess) {
      await _hydrateQueueFromStorage();
      await _loadHomeData();
      _maybeStartHomeTour();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _maybeStartHomeTour({bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!force && (prefs.getBool(_homeTourPrefsKey) ?? false)) return;
    if (!mounted || _view != _AppView.home) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await AppCoach.show(
      context,
      steps: [
        CoachStep(
          targetKey: _settingsKey,
          title: 'Ayarlar',
          description:
              'Buradan galeri izinlerini, kuyruğu ve tutulanları yönetebilirsin.',
          shape: CoachShape.circle,
          padding: const EdgeInsets.all(4),
        ),
        CoachStep(
          targetKey: _firstCategoryKey,
          title: 'Bir kategori seç',
          description:
              'Tüm Medya, Fotoğraflar, Videolar gibi kategorilerden birine dokunarak temizliğe başla.',
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          radius: 16,
        ),
        CoachStep(
          targetKey: _historyKey,
          title: 'Silme geçmişi',
          description:
              'Kalıcı olarak sildiğin paketlerin kaydını buradan görebilirsin.',
          shape: CoachShape.circle,
          padding: const EdgeInsets.all(4),
        ),
        CoachStep(
          targetKey: _reviewNavKey,
          title: 'Silme kuyruğu',
          description:
              'Sola kaydırdığın öğeler kuyrukta birikir; toplu kalıcı silmeyi buradan yaparsın.',
          padding: const EdgeInsets.all(8),
          radius: 14,
        ),
      ],
    );
    await prefs.setBool(_homeTourPrefsKey, true);
  }

  Future<void> _restartTours() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_homeTourPrefsKey, false);
    await prefs.setBool(_swipeTourPrefsKey, false);
    if (!mounted) return;
    setState(() => _view = _AppView.home);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    await _maybeStartHomeTour(force: true);
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historyPrefsKey) ?? const [];
    final parsed = raw
        .map(DeleteHistoryEntry.tryParse)
        .whereType<DeleteHistoryEntry>()
        .toList();
    if (!mounted) return;
    setState(() {
      _deleteHistory
        ..clear()
        ..addAll(parsed);
    });
  }

  Future<void> _loadKeptIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_keptPrefsKey) ?? const [];
    if (!mounted) return;
    setState(() {
      _keptIds
        ..clear()
        ..addAll(ids);
    });
  }

  Future<void> _hydrateQueueFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_queuePrefsKey) ?? const [];
    if (ids.isEmpty) return;
    final resolved = await _repo.getMediaByIds(ids);
    if (!mounted) return;
    setState(() {
      _deleteQueue
        ..clear()
        ..addAll(resolved);
    });
  }

  Future<void> _persistQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _queuePrefsKey,
      _deleteQueue.map((item) => item.id).toList(),
    );
  }

  Future<void> _persistHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _historyPrefsKey,
      _deleteHistory.map((entry) => entry.toJson()).toList(),
    );
  }

  Future<void> _persistKept() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keptPrefsKey, _keptIds.toList());
  }

  Future<void> _loadHomeData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final recent = await _repo.getMedia(
        category: GalleryCategory.allMedia,
        sortOption: SortOption.newestFirst,
      );
      final counts = <GalleryCategory, int>{};
      for (final category in GalleryCategory.values) {
        final items = await _repo.getMedia(
          category: category,
          sortOption: SortOption.newestFirst,
        );
        counts[category] = _filterQueued(items).length;
      }
      if (!mounted) return;
      setState(() {
        _recent = _filterQueued(recent).take(15).toList();
        _counts = counts;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Galeri yüklenemedi: $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMedia() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final items = await _repo.getMedia(
        category: _selectedCategory,
        sortOption: _selectedSort,
      );
      if (!mounted) return;
      setState(() {
        _media = _orderForSwipe(_filterQueued(items));
        _actionHistory.clear();
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Galeri yüklenemedi: $error';
        _isLoading = false;
      });
    }
  }

  List<MediaItem> _orderForSwipe(List<MediaItem> items) {
    if (_keptIds.isEmpty) return items;
    final undecided = <MediaItem>[];
    final kept = <MediaItem>[];
    for (final item in items) {
      if (_keptIds.contains(item.id)) {
        kept.add(item);
      } else {
        undecided.add(item);
      }
    }
    return [...undecided, ...kept];
  }

  void _openSwipeForCategory(GalleryCategory category) {
    setState(() {
      _selectedCategory = category;
      _view = _AppView.swipe;
    });
    _loadMedia();
  }

  void _addToQueue(MediaItem item) {
    if (_deleteQueue.any((queued) => queued.id == item.id)) return;
    setState(() {
      _deleteQueue.add(item);
      _media.removeWhere((m) => m.id == item.id);
      _recent.removeWhere((m) => m.id == item.id);
      _actionHistory.add(
        SwipeActionRecord(item: item, action: SwipeAction.delete),
      );
    });
    _persistQueue();
  }

  void _keepItem(MediaItem item) {
    setState(() {
      final wasKept = _keptIds.contains(item.id);
      _keptIds.add(item.id);
      _media.removeWhere((m) => m.id == item.id);
      _actionHistory.add(
        SwipeActionRecord(
          item: item,
          action: SwipeAction.keep,
          wasAlreadyKept: wasKept,
        ),
      );
    });
    _persistKept();
  }

  SwipeAction? _revertLastSwipe() {
    if (_actionHistory.isEmpty) return null;
    final record = _actionHistory.removeLast();
    setState(() {
      switch (record.action) {
        case SwipeAction.delete:
          _deleteQueue.removeWhere((q) => q.id == record.item.id);
          _media = [record.item, ..._media];
          if (!_recent.any((m) => m.id == record.item.id)) {
            _recent = [record.item, ..._recent].take(15).toList();
          }
          break;
        case SwipeAction.keep:
          if (!record.wasAlreadyKept) {
            _keptIds.remove(record.item.id);
          }
          _media = [record.item, ..._media];
          break;
      }
    });
    _persistQueue();
    _persistKept();
    return record.action;
  }

  void _removeFromQueue(MediaItem item) {
    setState(() {
      _deleteQueue.removeWhere((queued) => queued.id == item.id);
      _actionHistory.removeWhere(
        (r) => r.item.id == item.id && r.action == SwipeAction.delete,
      );
    });
    _persistQueue();
    _loadMedia();
  }

  Future<void> _confirmDeleteQueue() async {
    final messenger = ScaffoldMessenger.of(context);
    final toDelete = List<MediaItem>.from(_deleteQueue);

    try {
      final deletedIds = await _repo.deleteItems(toDelete);
      if (!mounted) return;
      setState(() {
        _deleteQueue.removeWhere((item) => deletedIds.contains(item.id));
        _media.removeWhere((item) => deletedIds.contains(item.id));
        _actionHistory.removeWhere(
          (r) =>
              r.action == SwipeAction.delete && deletedIds.contains(r.item.id),
        );
        _deleteHistory.insert(
          0,
          DeleteHistoryEntry(
            deletedAt: DateTime.now(),
            count: deletedIds.length,
          ),
        );
      });
      _persistQueue();
      _persistHistory();
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('${deletedIds.length} öğe silindi')),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text('Silinemedi: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildActiveView();

    return PopScope(
      canPop: _view == _AppView.home,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _view != _AppView.home) {
          setState(() => _view = _AppView.home);
        }
      },
      child: Scaffold(
        body: SafeArea(child: body),
        bottomNavigationBar: _view == _AppView.swipe
            ? null
            : _BottomNavBar(
                current: _view,
                queueCount: _deleteQueue.length,
                reviewKey: _reviewNavKey,
                onHome: () => setState(() => _view = _AppView.home),
                onQueue: () => setState(() => _view = _AppView.queue),
              ),
      ),
    );
  }

  Widget _buildActiveView() {
    final permission = _permissionState;
    if (permission != null && !permission.isAuth && !permission.hasAccess) {
      return _PermissionDenied(onRetry: _bootstrap);
    }

    if (_view == _AppView.home) {
      return _HomeView(
        recent: _recent,
        counts: _counts,
        selectedSort: _selectedSort,
        isLoading: _isLoading,
        errorMessage: _errorMessage,
        settingsKey: _settingsKey,
        historyKey: _historyKey,
        firstCategoryKey: _firstCategoryKey,
        onSortChanged: (sort) {
          setState(() => _selectedSort = sort);
        },
        onOpenSettings: _openSettings,
        onOpenHistory: _openHistory,
        onOpenCategory: _openSwipeForCategory,
      );
    }

    if (_view == _AppView.swipe) {
      return SwipeScreen(
        media: _media,
        category: _selectedCategory,
        isLoading: _isLoading,
        errorMessage: _errorMessage,
        onSwipeLeft: _addToQueue,
        onSwipeRight: _keepItem,
        onRevertLast: _revertLastSwipe,
        canRevert: _actionHistory.isNotEmpty,
        onRetry: _loadMedia,
        onBack: () => setState(() => _view = _AppView.home),
        onOpenQueue: () => setState(() => _view = _AppView.queue),
        queueCount: _deleteQueue.length,
        tourPrefsKey: _swipeTourPrefsKey,
      );
    }

    return DeleteQueueScreen(
      queue: _deleteQueue,
      onRemove: _removeFromQueue,
      onConfirmDelete: _confirmDeleteQueue,
      onClose: () => setState(() => _view = _AppView.home),
    );
  }

  List<MediaItem> _filterQueued(List<MediaItem> items) {
    final queued = _queueIds;
    if (queued.isEmpty) return items;
    return items.where((item) => !queued.contains(item.id)).toList();
  }

  Future<void> _openSettings() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => SettingsScreen(
          queueCount: _deleteQueue.length,
          keptCount: _keptIds.length,
          onClearQueue: _clearQueueFromSettings,
          onResetKept: _resetKept,
        ),
      ),
    );
    if (result == 'restart_tour') {
      _restartTours();
    }
  }

  Future<void> _openHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HistoryScreen(entries: _deleteHistory),
      ),
    );
  }

  void _clearQueueFromSettings() {
    setState(() {
      _deleteQueue.clear();
      _actionHistory.removeWhere((r) => r.action == SwipeAction.delete);
    });
    _persistQueue();
    _loadHomeData();
    if (_view == _AppView.swipe) {
      _loadMedia();
    }
  }

  void _resetKept() {
    setState(() {
      _keptIds.clear();
      _actionHistory.removeWhere((r) => r.action == SwipeAction.keep);
    });
    _persistKept();
    if (_view == _AppView.swipe) {
      _loadMedia();
    }
  }
}

enum _AppView { home, swipe, queue }

class _HomeView extends StatelessWidget {
  const _HomeView({
    required this.recent,
    required this.counts,
    required this.selectedSort,
    required this.isLoading,
    required this.errorMessage,
    required this.settingsKey,
    required this.historyKey,
    required this.firstCategoryKey,
    required this.onSortChanged,
    required this.onOpenSettings,
    required this.onOpenHistory,
    required this.onOpenCategory,
  });

  final List<MediaItem> recent;
  final Map<GalleryCategory, int> counts;
  final SortOption selectedSort;
  final bool isLoading;
  final String? errorMessage;
  final GlobalKey settingsKey;
  final GlobalKey historyKey;
  final GlobalKey firstCategoryKey;
  final ValueChanged<SortOption> onSortChanged;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenHistory;
  final ValueChanged<GalleryCategory> onOpenCategory;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
          child: Row(
            children: [
              IconButton(
                key: settingsKey,
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings),
              ),
              const Spacer(),
              const Text(
                'Picme',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
              ),
              const Spacer(),
              IconButton(
                key: historyKey,
                onPressed: onOpenHistory,
                icon: const Icon(Icons.history),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
            children: [
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, i) {
                    final option = SortOption.values[i];
                    final active = option == selectedSort;
                    return ChoiceChip(
                      label: Text(_sortLabel(option)),
                      selected: active,
                      onSelected: (_) => onSortChanged(option),
                      selectedColor: Colors.black,
                      labelStyle: TextStyle(
                        color: active ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide.none,
                      backgroundColor: Colors.grey.shade100,
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemCount: SortOption.values.length,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Categories',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              for (final (i, category) in GalleryCategory.values.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _CategoryTile(
                    key: i == 0 ? firstCategoryKey : null,
                    category: category,
                    count: counts[category] ?? 0,
                    onTap: () => onOpenCategory(category),
                  ),
                ),
              const SizedBox(height: 16),
              const Text(
                'Recent',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              else
                SizedBox(
                  height: 260,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final item = recent[index];
                      return GestureDetector(
                        onTap: () => onOpenCategory(GalleryCategory.allMedia),
                        child: Container(
                          width: 190,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: Colors.grey.shade200,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _SimpleThumb(item: item),
                              Positioned(
                                left: 12,
                                right: 12,
                                bottom: 12,
                                child: Text(
                                  item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 10),
                    itemCount: recent.length,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static String _sortLabel(SortOption option) {
    switch (option) {
      case SortOption.newestFirst:
        return 'Newest';
      case SortOption.oldestFirst:
        return 'Oldest';
      case SortOption.largestSizeFirst:
        return 'Largest';
    }
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    super.key,
    required this.category,
    required this.count,
    required this.onTap,
  });

  final GalleryCategory category;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey.shade300,
                child: Icon(_categoryIcon(category), color: Colors.black87),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                count.toString(),
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _categoryIcon(GalleryCategory category) {
    switch (category) {
      case GalleryCategory.allMedia:
        return Icons.photo_library_outlined;
      case GalleryCategory.photos:
        return Icons.photo_outlined;
      case GalleryCategory.videos:
        return Icons.movie_outlined;
      case GalleryCategory.screenshots:
        return Icons.screenshot_monitor_outlined;
      case GalleryCategory.downloads:
        return Icons.download_outlined;
    }
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.current,
    required this.queueCount,
    required this.reviewKey,
    required this.onHome,
    required this.onQueue,
  });

  final _AppView current;
  final int queueCount;
  final GlobalKey reviewKey;
  final VoidCallback onHome;
  final VoidCallback onQueue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEBEBEB))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            label: 'Clean',
            icon: Icons.cleaning_services_outlined,
            active: current == _AppView.home,
            onTap: onHome,
          ),
          _NavItem(
            key: reviewKey,
            label: 'Review',
            icon: Icons.auto_delete_outlined,
            active: current == _AppView.queue,
            onTap: onQueue,
            badge: queueCount,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    super.key,
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.badge,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.black : Colors.grey.shade600;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color),
                if ((badge ?? 0) > 0)
                  Positioned(
                    right: -8,
                    top: -7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleThumb extends StatelessWidget {
  const _SimpleThumb({required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image(
          image: AssetEntityImageProvider(
            item.asset,
            isOriginal: false,
            thumbnailSize: const ThumbnailSize.square(400),
          ),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const ColoredBox(color: Colors.black26),
        ),
        if (item.type == MediaType.video)
          const Center(
            child: Icon(
              Icons.play_circle_outline_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
      ],
    );
  }
}

class _PermissionDenied extends StatelessWidget {
  const _PermissionDenied({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline_rounded, size: 56),
            const SizedBox(height: 12),
            const Text(
              'Galeri erişimi gerekli',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Picme galerini görebilmen için fotoğraflara erişim izni vermen gerekiyor.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tekrar dene'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: PhotoManager.openSetting,
              child: const Text('Ayarları aç'),
            ),
          ],
        ),
      ),
    );
  }
}
