import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:picme/l10n/app_localizations.dart';
import 'package:picme/src/core/ads/admob_config.dart';
import 'package:picme/src/core/ads/picme_banner_ad_slot.dart';
import 'package:picme/src/core/models/delete_history_entry.dart';
import 'package:picme/src/core/models/media_item.dart';
import 'package:picme/src/core/models/swipe_action_record.dart';
import 'package:picme/src/core/ui/app_coach.dart';
import 'package:picme/src/core/ui/app_startup_loading_screen.dart';
import 'package:picme/src/core/util/bytes_format.dart';
import 'package:picme/src/features/home/presentation/history_screen.dart';
import 'package:picme/src/features/home/presentation/settings_screen.dart';
import 'package:picme/src/features/kept/presentation/kept_list_screen.dart';
import 'package:picme/src/features/queue/presentation/delete_queue_screen.dart';
import 'package:picme/src/core/data/review_prompter.dart';
import 'package:picme/src/features/home/presentation/widgets/filters_sheet.dart';
import 'package:picme/src/features/swipe/data/gallery_repository.dart';
import 'package:picme/src/features/swipe/domain/media_filters.dart';
import 'package:picme/src/features/swipe/domain/swipe_filters.dart';
import 'package:picme/src/features/swipe/presentation/swipe_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialPermissionState});

  final PermissionState? initialPermissionState;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _queuePrefsKey = 'picme_delete_queue_ids';
  static const String _historyPrefsKey = 'picme_delete_history';
  static const String _keptPrefsKey = 'picme_kept_ids';
  static const String _homeTourPrefsKey = 'picme_home_tour_done';
  static const String _swipeTourPrefsKey = 'picme_swipe_tour_done';
  static const int _firstSponsoredCardAfter = 20;
  static const int _sponsoredCardCooldown = 40;

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
  MediaFilters _activeFilters = MediaFilters.none;

  /// When non-null, the swipe screen is browsing a specific app folder
  /// (e.g. WhatsApp Images) instead of one of the predefined categories.
  String? _selectedFolderId;
  String? _selectedFolderName;

  /// Discovered media folders/buckets on the device. Used to expose
  /// app-specific media (Snapchat, WhatsApp, Telegram, Instagram, …) as
  /// dynamic categories in the home grid.
  List<({AssetPathEntity entity, int count})> _folders = const [];
  _AppView _view = _AppView.home;

  List<MediaItem> _media = [];
  Map<GalleryCategory, int> _counts = {
    for (final c in GalleryCategory.values) c: 0,
  };

  /// Total bytes per predefined category, lazily filled in by
  /// [_loadCategorySizes] after the home grid is rendered. `null` means
  /// "not resolved yet" — the tile shows a count-only label until then.
  final Map<GalleryCategory, int> _categoryBytes = {};

  /// Total bytes per discovered folder, keyed by [AssetPathEntity.id].
  final Map<String, int> _folderBytes = {};
  bool _isLoading = true;
  int _currentMediaPage = 0;
  bool _hasMoreMedia = false;
  bool _isLoadingNextPage = false;
  bool _categoryNotFound = false;
  PermissionState? _permissionState;
  String? _errorMessage;
  int _committedSwipeCount = 0;
  int _nextSponsoredCardAt = _firstSponsoredCardAfter;
  int _sponsoredCardSerial = 0;
  bool _showSponsoredCard = false;
  String? _ignoreAdCountForNextSwipeItemId;
  bool _showStartupLoading = true;
  int _deckTotalCount = 0;
  int _remainingDeckCount = 0;

  Set<String> get _queueIds => _deleteQueue.map((item) => item.id).toSet();

  /// Cumulative byte total of every successful delete batch in the user's
  /// history. Drives the dynamic hero subtitle and the history savings card.
  int get _totalSavedBytes =>
      _deleteHistory.fold<int>(0, (sum, e) => sum + e.bytes);

  @override
  void initState() {
    super.initState();
    if (widget.initialPermissionState != null) {
      _permissionState = widget.initialPermissionState;
    }
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

    // Always fetch a fresh permission snapshot. `_permissionState` may already
    // hold the value RootGate / WelcomeScreen seeded, but the user can flip
    // permission via system settings between bootstraps (this is exactly the
    // path triggered when they tap "Retry" on the permission-denied screen).
    final state = await _repo.requestPermission();
    if (!mounted) return;
    setState(() => _permissionState = state);

    if (state.isAuth || state.hasAccess) {
      await _hydrateQueueFromStorage();
      await _loadHomeData();
      if (!mounted) return;
      setState(() => _showStartupLoading = false);
      _maybeStartHomeTour();
    } else {
      setState(() {
        _isLoading = false;
        _showStartupLoading = false;
      });
    }
  }

  Future<void> _maybeStartHomeTour({bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!force && (prefs.getBool(_homeTourPrefsKey) ?? false)) return;
    if (!mounted || _view != _AppView.home) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final completed = await AppCoach.show(
      context,
      steps: [
        CoachStep(
          targetKey: _settingsKey,
          title: l10n.coachHomeSettingsTitle,
          description: l10n.coachHomeSettingsDesc,
          shape: CoachShape.circle,
          padding: const EdgeInsets.all(4),
        ),
        CoachStep(
          targetKey: _firstCategoryKey,
          title: l10n.coachHomeCategoryTitle,
          description: l10n.coachHomeCategoryDesc,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          radius: 16,
        ),
        CoachStep(
          targetKey: _historyKey,
          title: l10n.coachHomeHistoryTitle,
          description: l10n.coachHomeHistoryDesc,
          shape: CoachShape.circle,
          padding: const EdgeInsets.all(4),
        ),
        CoachStep(
          targetKey: _reviewNavKey,
          title: l10n.coachHomeQueueTitle,
          description: l10n.coachHomeQueueDesc,
          padding: const EdgeInsets.all(8),
          radius: 14,
        ),
        CoachStep(
          targetKey: _firstCategoryKey,
          title: l10n.coachHomeStartTitle,
          description: l10n.coachHomeStartDesc,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          radius: 16,
          actionLabel: l10n.coachStart,
        ),
      ],
    );
    await prefs.setBool(_homeTourPrefsKey, true);
    if (completed && mounted && _view == _AppView.home) {
      _openSwipeForCategory(GalleryCategory.allMedia);
    }
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
    final storedEntries = _decodeQueueEntries(
      prefs.getStringList(_queuePrefsKey) ?? const [],
    );
    if (storedEntries.isEmpty) return;
    final resolved = await _repo.getMediaByIds(
      storedEntries.map((entry) => entry.id).toList(),
    );
    final storedSizes = {
      for (final entry in storedEntries)
        if (entry.fileSizeInBytes != null) entry.id: entry.fileSizeInBytes!,
    };
    final restored = [
      for (final item in resolved)
        storedSizes.containsKey(item.id)
            ? item.copyWith(fileSizeInBytes: storedSizes[item.id])
            : item,
    ];
    final warmed = await _repo.warmSizes(restored);
    if (!mounted) return;
    setState(() {
      _deleteQueue
        ..clear()
        ..addAll(warmed);
    });
    unawaited(_persistQueue());
  }

  Future<void> _persistQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _queuePrefsKey,
      _deleteQueue.map(_encodeQueueEntry).toList(),
    );
  }

  String _encodeQueueEntry(MediaItem item) {
    return jsonEncode({
      'id': item.id,
      if (item.fileSizeInBytes != null) 'fileSizeInBytes': item.fileSizeInBytes,
    });
  }

  List<({String id, int? fileSizeInBytes})> _decodeQueueEntries(
    List<String> rawEntries,
  ) {
    final decoded = <({String id, int? fileSizeInBytes})>[];
    for (final raw in rawEntries) {
      try {
        final json = jsonDecode(raw);
        if (json is Map<String, dynamic>) {
          final id = json['id'];
          final size = json['fileSizeInBytes'];
          if (id is String && id.isNotEmpty) {
            decoded.add((id: id, fileSizeInBytes: size is int ? size : null));
            continue;
          }
        }
      } catch (_) {
        // Older builds stored raw ids only; keep supporting them.
      }
      if (raw.isNotEmpty) {
        decoded.add((id: raw, fileSizeInBytes: null));
      }
    }
    return decoded;
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
      // Use getCount() for category totals — much faster than loading all items.
      final countFutures = GalleryCategory.values.map(
        (cat) => _repo.getCount(cat),
      );
      final countResults = await Future.wait(countFutures);
      final counts = <GalleryCategory, int>{};
      for (var i = 0; i < GalleryCategory.values.length; i++) {
        counts[GalleryCategory.values[i]] = countResults[i];
      }
      // Discover app-specific folders (Snapchat, WhatsApp, Telegram, …) and
      // surface them as dynamic categories alongside the predefined ones.
      // We exclude buckets that already map to a predefined category — there
      // is no point showing "Camera", "Screenshots", or "Download" twice.
      final allFolders = await _repo.getFolders();
      final folders = _filterPredefinedFolders(allFolders);
      if (!mounted) return;
      setState(() {
        _counts = counts;
        _folders = folders;
        _isLoading = false;
      });
      // Kick off size aggregation in the background. Results will appear in
      // tiles as they resolve (each tile rebuilds via setState).
      unawaited(_loadCategorySizes());
    } catch (error) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _errorMessage = l10n.deleteError(error.toString());
        _isLoading = false;
      });
    }
  }

  /// Resolves total byte size for each predefined category and discovered
  /// folder via the native MediaStore aggregate query, then folds the result
  /// into [_categoryBytes] / [_folderBytes] one by one so the UI updates
  /// progressively.
  Future<void> _loadCategorySizes() async {
    for (final cat in GalleryCategory.values) {
      if ((_counts[cat] ?? 0) <= 0) continue;
      try {
        final bytes = await _repo.getCategoryBytes(cat);
        if (!mounted) return;
        setState(() => _categoryBytes[cat] = bytes);
      } catch (_) {}
    }
    for (final folder in _folders) {
      try {
        final bytes = await _repo.getCategoryBytes(
          GalleryCategory.allMedia,
          folderPathId: folder.entity.id,
        );
        if (!mounted) return;
        setState(() => _folderBytes[folder.entity.id] = bytes);
      } catch (_) {}
    }
  }

  /// How many items at the head of the deck we eagerly resolve sizes for so
  /// the "X MB" label on the swipe card is filled in by the time it shows up.
  /// Resolution beyond this count happens naturally via `_addToQueue` once
  /// the user swipes left.
  static const int _sizeWarmCount = 30;

  Future<void> _loadMedia() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentMediaPage = 0;
      _hasMoreMedia = false;
      _categoryNotFound = false;
    });
    try {
      // Check folder existence first for named categories.
      final exists = await _repo.categoryExists(
        _selectedCategory,
        folderPathId: _selectedFolderId,
      );
      if (!exists) {
        if (!mounted) return;
        setState(() {
          _media = [];
          _categoryNotFound = true;
          _isLoading = false;
        });
        return;
      }
      final totalCount = await _repo.getCount(
        _selectedCategory,
        folderPathId: _selectedFolderId,
      );
      final chunk = await _loadVisibleMediaChunk(startPage: 0);
      if (!mounted) return;
      setState(() {
        _media = chunk.items;
        _actionHistory.clear();
        _currentMediaPage = chunk.lastPage;
        _hasMoreMedia = chunk.hasMore;
        _deckTotalCount = totalCount;
        _remainingDeckCount = totalCount;
        _isLoading = false;
      });
      unawaited(_warmDeckSizes());
    } catch (error) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _errorMessage = l10n.deleteError(error.toString());
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNextMediaPage() async {
    if (_isLoadingNextPage || !_hasMoreMedia) return;
    setState(() => _isLoadingNextPage = true);
    try {
      final nextPage = _currentMediaPage + 1;
      final chunk = await _loadVisibleMediaChunk(startPage: nextPage);
      if (!mounted) return;
      setState(() {
        _media = [..._media, ...chunk.items];
        _currentMediaPage = chunk.lastPage;
        _hasMoreMedia = chunk.hasMore;
        _isLoadingNextPage = false;
      });
      unawaited(_warmDeckSizes());
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingNextPage = false);
    }
  }

  /// Fills in `fileSizeInBytes` for the next chunk of items at the head of
  /// the deck so cards display their MB right away. Runs in the background
  /// after a load finishes; failures are swallowed (size is decorative).
  Future<void> _warmDeckSizes() async {
    if (_media.isEmpty) return;
    final candidates = <MediaItem>[];
    for (final item in _media) {
      if (item.fileSizeInBytes == null) candidates.add(item);
      if (candidates.length >= _sizeWarmCount) break;
    }
    if (candidates.isEmpty) return;
    try {
      final resolved = await _repo.warmSizes(candidates);
      if (!mounted) return;
      final byId = {for (final m in resolved) m.id: m};
      setState(() {
        _media = [for (final item in _media) byId[item.id] ?? item];
      });
    } catch (_) {
      // ignore; size is non-critical UI affordance.
    }
  }

  List<MediaItem> _orderForSwipe(List<MediaItem> items) {
    if (_keptIds.isEmpty) return items;
    return items.where((item) => !_keptIds.contains(item.id)).toList();
  }

  Future<({List<MediaItem> items, int lastPage, bool hasMore})>
  _loadVisibleMediaChunk({
    required int startPage,
    int minVisibleItems = 24,
  }) async {
    final collected = <MediaItem>[];
    var page = startPage;
    var hasMore = false;
    while (true) {
      final batch = await _repo.getMedia(
        category: _selectedCategory,
        sortOption: _selectedSort,
        page: page,
        pageSize: GalleryRepository.defaultPageSize,
        filters: _activeFilters,
        folderPathId: _selectedFolderId,
      );
      if (batch.isEmpty) {
        hasMore = false;
        break;
      }
      collected.addAll(_orderForSwipe(_filterQueued(batch)));
      hasMore = batch.length == GalleryRepository.defaultPageSize;
      if (collected.length >= minVisibleItems || !hasMore) break;
      page += 1;
    }
    return (items: collected, lastPage: page, hasMore: hasMore);
  }

  void _resetSwipeMonetizationSession() {
    _committedSwipeCount = 0;
    _nextSponsoredCardAt = _firstSponsoredCardAfter;
    _showSponsoredCard = false;
    _ignoreAdCountForNextSwipeItemId = null;
  }

  void _registerCommittedSwipeForAd(MediaItem item) {
    if (_ignoreAdCountForNextSwipeItemId == item.id) {
      _ignoreAdCountForNextSwipeItemId = null;
      return;
    }

    _ignoreAdCountForNextSwipeItemId = null;
    _committedSwipeCount += 1;
    final canInsertSponsoredCard = _media.isNotEmpty;
    if (!_showSponsoredCard &&
        canInsertSponsoredCard &&
        _committedSwipeCount >= _nextSponsoredCardAt) {
      _showSponsoredCard = true;
      _sponsoredCardSerial += 1;
      _nextSponsoredCardAt += _sponsoredCardCooldown;
    }
  }

  void _dismissSponsoredCard() {
    if (!_showSponsoredCard) return;
    setState(() => _showSponsoredCard = false);
    if (_media.length <= 30) {
      unawaited(_loadNextMediaPage());
    }
  }

  void _openSwipeForCategory(GalleryCategory category) {
    setState(() {
      _selectedCategory = category;
      _selectedFolderId = null;
      _selectedFolderName = null;
      _view = _AppView.swipe;
      _resetSwipeMonetizationSession();
    });
    _loadMedia();
  }

  void _openSwipeForFolder(AssetPathEntity folder) {
    setState(() {
      _selectedCategory = GalleryCategory.allMedia;
      _selectedFolderId = folder.id;
      _selectedFolderName = folder.name;
      _view = _AppView.swipe;
      _resetSwipeMonetizationSession();
    });
    _loadMedia();
  }

  /// Filters out buckets whose names match the predefined categories
  /// (Screenshots, Downloads) so we don't display the same folder twice.
  List<({AssetPathEntity entity, int count})> _filterPredefinedFolders(
    List<({AssetPathEntity entity, int count})> all,
  ) {
    const predefinedNames = <String>[
      'screenshots',
      'screenshot',
      'download',
      'downloads',
    ];
    return all.where((f) {
      final lower = f.entity.name.toLowerCase();
      return !predefinedNames.any(
        (name) => lower == name || lower.contains(name),
      );
    }).toList();
  }

  void _addToQueue(MediaItem item) {
    if (_deleteQueue.any((queued) => queued.id == item.id)) return;
    setState(() {
      _deleteQueue.add(item);
      _media.removeWhere((m) => m.id == item.id);
      if (_remainingDeckCount > 0) {
        _remainingDeckCount -= 1;
      }
      _registerCommittedSwipeForAd(item);
      _actionHistory.add(
        SwipeActionRecord(item: item, action: SwipeAction.delete),
      );
    });
    _persistQueue();
    // Lazily resolve file size so the queue summary can show total MB.
    if (item.fileSizeInBytes == null) {
      _resolveSizeForQueueItem(item);
    }
  }

  Future<void> _resolveSizeForQueueItem(MediaItem item) async {
    try {
      final resolved = await _repo.warmSizes([item]);
      if (resolved.isEmpty) return;
      final sizedItem = resolved.first;
      if (!mounted) return;
      final idx = _deleteQueue.indexWhere((q) => q.id == item.id);
      if (idx == -1) return;
      setState(() {
        _deleteQueue[idx] = sizedItem;
      });
      unawaited(_persistQueue());
    } catch (_) {
      // Ignore; size will remain null
    }
  }

  void _keepItem(MediaItem item) {
    setState(() {
      final wasKept = _keptIds.contains(item.id);
      _keptIds.add(item.id);
      _media.removeWhere((m) => m.id == item.id);
      if (_remainingDeckCount > 0) {
        _remainingDeckCount -= 1;
      }
      _registerCommittedSwipeForAd(item);
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
      _ignoreAdCountForNextSwipeItemId = record.item.id;
      if (_remainingDeckCount < _deckTotalCount) {
        _remainingDeckCount += 1;
      }
      switch (record.action) {
        case SwipeAction.delete:
          _deleteQueue.removeWhere((q) => q.id == record.item.id);
          _media = [record.item, ..._media];
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
    final l10n = AppLocalizations.of(context)!;
    final toDelete = List<MediaItem>.from(_deleteQueue);

    try {
      final deletedIds = await _repo.deleteItems(toDelete);
      if (!mounted) return;
      // Sum bytes for items that actually got deleted. Items whose size
      // wasn't resolved (fileSizeInBytes == null) contribute 0 — better than
      // throwing or showing an inflated number. _warmDeckSizes typically
      // resolves head-of-deck items long before they reach the queue, so
      // most batches will carry accurate byte totals.
      final deletedSet = deletedIds.toSet();
      final totalBytes = toDelete
          .where((it) => deletedSet.contains(it.id))
          .fold<int>(0, (sum, it) => sum + (it.fileSizeInBytes ?? 0));
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
            bytes: totalBytes,
          ),
        );
      });
      _persistQueue();
      _persistHistory();
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.itemsDeleted(deletedIds.length))),
      );
      unawaited(ReviewPrompter.recordBatchAndMaybePrompt());
    } catch (error) {
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.deleteError(error.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final body = _buildActiveView(l10n);
    final backLockedBySponsoredCard =
        _view == _AppView.swipe && _showSponsoredCard;
    return PopScope(
      canPop: _view == _AppView.home,
      onPopInvokedWithResult: (didPop, result) {
        if (backLockedBySponsoredCard) {
          return;
        }
        if (!didPop && _view != _AppView.home) {
          setState(() => _view = _AppView.home);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
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

  Widget _buildActiveView(AppLocalizations l10n) {
    if (_showStartupLoading) {
      return AppStartupLoadingScreen(subtitle: l10n.startupLoadingHomeSubtitle);
    }

    final permission = _permissionState;
    if (permission != null && !permission.isAuth && !permission.hasAccess) {
      return _PermissionDenied(onRetry: _bootstrap);
    }

    final isLimited =
        permission != null && !permission.isAuth && permission.hasAccess;

    if (_view == _AppView.swipe) {
      return SwipeScreen(
        media: _media,
        category: _selectedCategory,
        isLoading: _isLoading,
        errorMessage: _errorMessage,
        showSponsoredCard:
            _showSponsoredCard &&
            PicmeAdMobConfig.isPlacementEnabled(
              PicmeAdPlacement.swipeSponsoredCard,
            ),
        sponsoredCardSerial: _sponsoredCardSerial,
        totalDeckCount: _deckTotalCount,
        remainingDeckCount: _remainingDeckCount,
        onSwipeLeft: _addToQueue,
        onSwipeRight: _keepItem,
        onDismissSponsoredCard: _dismissSponsoredCard,
        onRevertLast: _revertLastSwipe,
        canRevert: _actionHistory.isNotEmpty,
        onRetry: _loadMedia,
        onBack: () => setState(() => _view = _AppView.home),
        onOpenQueue: () => setState(() => _view = _AppView.queue),
        queueCount: _deleteQueue.length,
        tourPrefsKey: _swipeTourPrefsKey,
        onLoadMore: _hasMoreMedia ? _loadNextMediaPage : null,
        categoryNotFound: _categoryNotFound,
        displayTitle: _selectedFolderName,
      );
    }

    final homePane = Column(
      children: [
        if (isLimited) _LimitedAccessBanner(onSelectMore: _onSelectMorePhotos),
        Expanded(
          child: _HomeView(
            counts: _counts,
            folders: _folders,
            categoryBytes: _categoryBytes,
            folderBytes: _folderBytes,
            totalSavedBytes: _totalSavedBytes,
            selectedSort: _selectedSort,
            activeFilters: _activeFilters,
            queueCount: _deleteQueue.length,
            keptCount: _keptIds.length,
            settingsKey: _settingsKey,
            historyKey: _historyKey,
            firstCategoryKey: _firstCategoryKey,
            onSortChanged: (sort) {
              setState(() => _selectedSort = sort);
              _loadMedia();
            },
            onFiltersChanged: (filters) {
              setState(() => _activeFilters = filters);
              _loadMedia();
            },
            onOpenSettings: _openSettings,
            onOpenHistory: _openHistory,
            onOpenCategory: _openSwipeForCategory,
            onOpenFolder: _openSwipeForFolder,
            onOpenQueue: () => setState(() => _view = _AppView.queue),
            onOpenKept: _openKeptList,
          ),
        ),
      ],
    );

    final queuePane = DeleteQueueScreen(
      queue: _deleteQueue,
      onRemove: _removeFromQueue,
      onConfirmDelete: _confirmDeleteQueue,
      onClose: () => setState(() => _view = _AppView.home),
    );

    return IndexedStack(
      index: _view == _AppView.home ? 0 : 1,
      children: [homePane, queuePane],
    );
  }

  Future<void> _onSelectMorePhotos() async {
    await _repo.presentLimited();
    if (!mounted) return;
    final newState = await _repo.requestPermission();
    if (!mounted) return;
    setState(() => _permissionState = newState);
    await _loadHomeData();
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
          onViewKept: _openKeptList,
        ),
      ),
    );
    if (result == 'restart_tour') {
      _restartTours();
    }
  }

  Future<void> _openKeptList() async {
    final keptItems = await _repo.getMediaByIds(_keptIds.toList());
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KeptListScreen(
          initialItems: keptItems,
          onUnkeep: (item) async {
            setState(() {
              _keptIds.remove(item.id);
              _actionHistory.removeWhere(
                (r) => r.action == SwipeAction.keep && r.item.id == item.id,
              );
            });
            await _persistKept();
            // Refresh home counts and recent so the un-kept item reappears.
            if (_view == _AppView.home) {
              _loadHomeData();
            } else if (_view == _AppView.swipe) {
              _loadMedia();
            }
          },
        ),
      ),
    );
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
    required this.counts,
    required this.folders,
    required this.categoryBytes,
    required this.folderBytes,
    required this.totalSavedBytes,
    required this.selectedSort,
    required this.activeFilters,
    required this.queueCount,
    required this.keptCount,
    required this.settingsKey,
    required this.historyKey,
    required this.firstCategoryKey,
    required this.onSortChanged,
    required this.onFiltersChanged,
    required this.onOpenSettings,
    required this.onOpenHistory,
    required this.onOpenCategory,
    required this.onOpenFolder,
    required this.onOpenQueue,
    required this.onOpenKept,
  });

  final Map<GalleryCategory, int> counts;
  final List<({AssetPathEntity entity, int count})> folders;
  final Map<GalleryCategory, int> categoryBytes;
  final Map<String, int> folderBytes;

  /// Cumulative byte total of every successful delete batch so far.
  /// Drives the hero subtitle ("You've freed up 1.4 GB so far").
  final int totalSavedBytes;
  final SortOption selectedSort;
  final MediaFilters activeFilters;
  final int queueCount;
  final int keptCount;
  final GlobalKey settingsKey;
  final GlobalKey historyKey;
  final GlobalKey firstCategoryKey;
  final ValueChanged<SortOption> onSortChanged;
  final ValueChanged<MediaFilters> onFiltersChanged;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenHistory;
  final ValueChanged<GalleryCategory> onOpenCategory;
  final ValueChanged<AssetPathEntity> onOpenFolder;
  final VoidCallback onOpenQueue;
  final VoidCallback onOpenKept;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        _HomeTopBar(
          settingsKey: settingsKey,
          historyKey: historyKey,
          onOpenSettings: onOpenSettings,
          onOpenHistory: onOpenHistory,
        ),
        const SizedBox(height: 18),
        _HeroCard(
          title: l10n.homeSwipeLaunchTitle,
          subtitle: l10n.homeSwipeLaunchSubtitle,
          primaryLabel: l10n.homeSwipeLaunchCta,
          quickPicksLabel: l10n.homeSwipeQuickPicks,
          totalValue: formatBytes(totalSavedBytes),
          queuedCount: queueCount,
          keptCount: keptCount,
          totalLabel: l10n.historySavingsTitle,
          queuedLabel: l10n.statsQueued,
          keptLabel: l10n.statsKept,
          photosLabel: l10n.catPhotos,
          videosLabel: l10n.catVideos,
          onStartAllMedia: () => onOpenCategory(GalleryCategory.allMedia),
          onOpenPhotos: () => onOpenCategory(GalleryCategory.photos),
          onOpenVideos: () => onOpenCategory(GalleryCategory.videos),
          onTapTotal: onOpenHistory,
          onTapQueued: onOpenQueue,
          onTapKept: onOpenKept,
        ),
        if (PicmeAdMobConfig.isPlacementEnabled(
          PicmeAdPlacement.homeBanner,
        )) ...[
          const SizedBox(height: 14),
          const _HomeBannerCard(),
        ],
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: _SortSegments(
                selected: selectedSort,
                onChanged: onSortChanged,
              ),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              activeFilters: activeFilters,
              onTap: () async {
                final updated = await showFiltersSheet(context, activeFilters);
                if (updated != null) onFiltersChanged(updated);
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SectionHeader(label: l10n.homeCategoriesSecondary),
        const SizedBox(height: 12),
        _CategoryGrid(
          counts: counts,
          folders: folders,
          categoryBytes: categoryBytes,
          folderBytes: folderBytes,
          firstKey: firstCategoryKey,
          onTap: onOpenCategory,
          onTapFolder: onOpenFolder,
        ),
      ],
    );
  }
}

class _HomeBannerCard extends StatelessWidget {
  const _HomeBannerCard();

  @override
  Widget build(BuildContext context) {
    return PicmeBannerAdSlot(
      placement: PicmeAdPlacement.homeBanner,
      builder: (context, adWidget) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.76),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: adWidget,
        );
      },
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({
    required this.settingsKey,
    required this.historyKey,
    required this.onOpenSettings,
    required this.onOpenHistory,
  });

  final GlobalKey settingsKey;
  final GlobalKey historyKey;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(
          key: settingsKey,
          icon: Icons.tune_rounded,
          onTap: onOpenSettings,
        ),
        const Spacer(),
        const Text(
          'picme',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: Color(0xFF1F1F1F),
          ),
        ),
        const Spacer(),
        _CircleIconButton(
          key: historyKey,
          icon: Icons.history_rounded,
          onTap: onOpenHistory,
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.7),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 20, color: const Color(0xFF1F1F1F)),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.quickPicksLabel,
    required this.totalValue,
    required this.queuedCount,
    required this.keptCount,
    required this.totalLabel,
    required this.queuedLabel,
    required this.keptLabel,
    required this.photosLabel,
    required this.videosLabel,
    required this.onStartAllMedia,
    required this.onOpenPhotos,
    required this.onOpenVideos,
    this.onTapTotal,
    this.onTapQueued,
    this.onTapKept,
  });

  final String title;
  final String subtitle;
  final String primaryLabel;
  final String quickPicksLabel;
  final String totalValue;
  final int queuedCount;
  final int keptCount;
  final String totalLabel;
  final String queuedLabel;
  final String keptLabel;
  final String photosLabel;
  final String videosLabel;
  final VoidCallback onStartAllMedia;
  final VoidCallback onOpenPhotos;
  final VoidCallback onOpenVideos;
  final VoidCallback? onTapTotal;
  final VoidCallback? onTapQueued;
  final VoidCallback? onTapKept;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F1F1F).withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.74),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const _DeckGlyph(),
            ],
          ),
          const SizedBox(height: 18),
          _HeroPrimaryButton(label: primaryLabel, onTap: onStartAllMedia),
          const SizedBox(height: 12),
          Text(
            quickPicksLabel,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _HeroQuickPick(
                  icon: Icons.photo_library_rounded,
                  label: photosLabel,
                  onTap: onOpenPhotos,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeroQuickPick(
                  icon: Icons.videocam_rounded,
                  label: videosLabel,
                  onTap: onOpenVideos,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.10)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  value: totalValue,
                  label: totalLabel,
                  accent: Colors.white,
                  onTap: onTapTotal,
                ),
              ),
              _HeroDivider(),
              Expanded(
                child: _HeroStat(
                  value: _formatCompactCount(queuedCount),
                  label: queuedLabel,
                  accent: const Color(0xFFE07A5F),
                  onTap: onTapQueued,
                ),
              ),
              _HeroDivider(),
              Expanded(
                child: _HeroStat(
                  value: _formatCompactCount(keptCount),
                  label: keptLabel,
                  accent: const Color(0xFFA3D9B1),
                  onTap: onTapKept,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeckGlyph extends StatelessWidget {
  const _DeckGlyph();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: -0.22,
            child: _DeckGlyphCard(
              color: const Color(0x33FFFFFF),
              borderColor: const Color(0x2EFFFFFF),
            ),
          ),
          Transform.rotate(
            angle: 0.12,
            child: _DeckGlyphCard(
              color: const Color(0x26FFFFFF),
              borderColor: const Color(0x24FFFFFF),
            ),
          ),
          const _DeckGlyphCard(
            color: Color(0xFFF4F5F7),
            borderColor: Color(0x33FFFFFF),
            child: Icon(
              Icons.swipe_rounded,
              color: Color(0xFF1F1F1F),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeckGlyphCard extends StatelessWidget {
  const _DeckGlyphCard({
    required this.color,
    required this.borderColor,
    this.child,
  });

  final Color color;
  final Color borderColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      height: 82,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _HeroPrimaryButton extends StatelessWidget {
  const _HeroPrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.play_arrow_rounded,
                size: 20,
                color: Color(0xFF1F1F1F),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF1F1F1F),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroQuickPick extends StatelessWidget {
  const _HeroQuickPick({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: Colors.white.withValues(alpha: 0.12),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.value,
    required this.label,
    required this.accent,
    this.onTap,
  });

  final String value;
  final String label;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final column = Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: accent,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
    if (onTap == null) return column;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: column,
      ),
    );
  }
}

String _formatCompactCount(int n) {
  if (n >= 1000) {
    final k = n / 1000;
    return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}K';
  }
  return n.toString();
}

class _SortSegments extends StatelessWidget {
  const _SortSegments({required this.selected, required this.onChanged});

  final SortOption selected;
  final ValueChanged<SortOption> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (final option in SortOption.values)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected == option
                        ? const Color(0xFF1F1F1F)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    option.labelOf(l10n),
                    style: TextStyle(
                      color: selected == option
                          ? Colors.white
                          : const Color(0xFF1F1F1F),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Compact filter icon button with an active-count badge.
class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.activeFilters, required this.onTap});

  final MediaFilters activeFilters;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isActive = activeFilters.isActive;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF1F1F1F)
              : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 16,
              color: isActive ? Colors.white : const Color(0xFF1F1F1F),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              Text(
                l10n.filterActiveLabel(activeFilters.activeCount),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: Color(0xFF1F1F1F),
      ),
    );
  }
}

class _CategoryGrid extends StatefulWidget {
  const _CategoryGrid({
    required this.counts,
    required this.folders,
    required this.categoryBytes,
    required this.folderBytes,
    required this.firstKey,
    required this.onTap,
    required this.onTapFolder,
  });

  final Map<GalleryCategory, int> counts;
  final List<({AssetPathEntity entity, int count})> folders;
  final Map<GalleryCategory, int> categoryBytes;
  final Map<String, int> folderBytes;
  final GlobalKey firstKey;
  final ValueChanged<GalleryCategory> onTap;
  final ValueChanged<AssetPathEntity> onTapFolder;

  @override
  State<_CategoryGrid> createState() => _CategoryGridState();
}

class _CategoryGridState extends State<_CategoryGrid> {
  static const int _collapsedItemCount = 6;

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categoryCount = GalleryCategory.values.length;
    final total = categoryCount + widget.folders.length;
    final visibleCount = _expanded
        ? total
        : total.clamp(0, _collapsedItemCount);
    final canExpand = total > _collapsedItemCount;

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 116,
          ),
          itemCount: visibleCount,
          itemBuilder: (context, i) {
            if (i < categoryCount) {
              final category = GalleryCategory.values[i];
              return _BrowseTile(
                key: i == 0 ? widget.firstKey : null,
                label: category.labelOf(l10n),
                count: widget.counts[category] ?? 0,
                bytes: widget.categoryBytes[category],
                icon: _CategoryTile._iconFor(category),
                palette: _CategoryTile._paletteFor(category),
                onTap: () => widget.onTap(category),
              );
            }
            final folder = widget.folders[i - categoryCount];
            return _BrowseTile(
              label: folder.entity.name,
              count: folder.count,
              bytes: widget.folderBytes[folder.entity.id],
              icon: _CategoryTile._iconForFolder(folder.entity.name),
              palette: _CategoryTile._paletteForFolder(folder.entity.name),
              onTap: () => widget.onTapFolder(folder.entity),
            );
          },
        ),
        if (canExpand) ...[
          const SizedBox(height: 12),
          _CategoryGridToggle(
            expanded: _expanded,
            label: _expanded
                ? l10n.categoriesCollapse
                : l10n.categoriesShowAll(total),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
        ],
      ],
    );
  }
}

class _CategoryGridToggle extends StatelessWidget {
  const _CategoryGridToggle({
    required this.expanded,
    required this.label,
    required this.onTap,
  });

  final bool expanded;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.68),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F1F1F),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: const Color(0xFF1F1F1F),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Internal helpers shared between the predefined-category and folder tiles.
abstract class _CategoryTile {
  static IconData _iconFor(GalleryCategory category) {
    switch (category) {
      case GalleryCategory.allMedia:
        return Icons.photo_library_rounded;
      case GalleryCategory.photos:
        return Icons.image_rounded;
      case GalleryCategory.videos:
        return Icons.play_circle_filled_rounded;
      case GalleryCategory.screenshots:
        return Icons.crop_square_rounded;
      case GalleryCategory.downloads:
        return Icons.download_rounded;
    }
  }

  static _Palette _paletteFor(GalleryCategory category) {
    switch (category) {
      case GalleryCategory.allMedia:
        return const _Palette(Color(0xFFFCE3DA), Color(0xFFE07A5F));
      case GalleryCategory.photos:
        return const _Palette(Color(0xFFE6DFFF), Color(0xFF6E5BC7));
      case GalleryCategory.videos:
        return const _Palette(Color(0xFFFFE2E5), Color(0xFFD45D6E));
      case GalleryCategory.screenshots:
        return const _Palette(Color(0xFFD8F0E0), Color(0xFF3F9E68));
      case GalleryCategory.downloads:
        return const _Palette(Color(0xFFD9ECFF), Color(0xFF3D7CC9));
    }
  }

  static IconData _iconForFolder(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('whatsapp')) return Icons.chat_rounded;
    if (lower.contains('telegram')) return Icons.send_rounded;
    if (lower.contains('snap')) return Icons.bolt_rounded;
    if (lower.contains('instagram')) return Icons.camera_alt_rounded;
    if (lower.contains('camera') || lower.contains('dcim')) {
      return Icons.photo_camera_rounded;
    }
    if (lower.contains('movie') || lower.contains('video')) {
      return Icons.movie_rounded;
    }
    if (lower.contains('picture')) return Icons.image_rounded;
    if (lower.contains('discord')) return Icons.forum_rounded;
    if (lower.contains('signal')) return Icons.lock_rounded;
    return Icons.folder_rounded;
  }

  /// Stable color for an arbitrary folder name. Hashes the name into a fixed
  /// palette so the same folder gets the same color across launches without
  /// requiring us to enumerate every possible app.
  static _Palette _paletteForFolder(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('whatsapp')) {
      return const _Palette(Color(0xFFD8F0E0), Color(0xFF22A06B));
    }
    if (lower.contains('telegram')) {
      return const _Palette(Color(0xFFD9ECFF), Color(0xFF2AABEE));
    }
    if (lower.contains('snap')) {
      return const _Palette(Color(0xFFFFF6CC), Color(0xFFEEC400));
    }
    if (lower.contains('instagram')) {
      return const _Palette(Color(0xFFFCE0E8), Color(0xFFC13584));
    }
    if (lower.contains('camera') || lower.contains('dcim')) {
      return const _Palette(Color(0xFFFCE3DA), Color(0xFFE07A5F));
    }
    if (lower.contains('discord')) {
      return const _Palette(Color(0xFFE0E3FA), Color(0xFF5865F2));
    }
    const palettes = <_Palette>[
      _Palette(Color(0xFFE6DFFF), Color(0xFF6E5BC7)),
      _Palette(Color(0xFFD8F0E0), Color(0xFF3F9E68)),
      _Palette(Color(0xFFD9ECFF), Color(0xFF3D7CC9)),
      _Palette(Color(0xFFFFE2E5), Color(0xFFD45D6E)),
      _Palette(Color(0xFFFFF1D6), Color(0xFFB97A1E)),
      _Palette(Color(0xFFE7F0E1), Color(0xFF6B8E5A)),
    ];
    return palettes[name.hashCode.abs() % palettes.length];
  }
}

class _BrowseTile extends StatelessWidget {
  const _BrowseTile({
    super.key,
    required this.label,
    required this.count,
    required this.bytes,
    required this.icon,
    required this.palette,
    required this.onTap,
  });

  final String label;
  final int count;
  final int? bytes;
  final IconData icon;
  final _Palette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final countLabel = _formatCount(count);
    final sizeLabel = bytes != null && bytes! > 0 ? formatBytes(bytes!) : null;
    return Material(
      color: Colors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: palette.bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: palette.fg),
              ),
              const Spacer(),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F1F1F),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sizeLabel == null ? countLabel : '$countLabel · $sizeLabel',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8A8A8A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatCount(int n) {
    if (n >= 1000) {
      final k = n / 1000;
      return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}K';
    }
    return n.toString();
  }
}

class _Palette {
  const _Palette(this.bg, this.fg);
  final Color bg;
  final Color fg;
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
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _NavItem(
                label: l10n.navClean,
                icon: Icons.auto_awesome_rounded,
                active: current == _AppView.home,
                onTap: onHome,
              ),
            ),
            Expanded(
              child: _NavItem(
                key: reviewKey,
                label: l10n.navReview,
                icon: Icons.delete_sweep_rounded,
                active: current == _AppView.queue,
                onTap: onQueue,
                badge: queueCount,
              ),
            ),
          ],
        ),
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
    final fg = active ? Colors.white : const Color(0xFF1F1F1F);
    final bg = active ? const Color(0xFF1F1F1F) : Colors.transparent;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: fg, size: 18),
                if ((badge ?? 0) > 0)
                  Positioned(
                    right: -7,
                    top: -6,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE07A5F),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LimitedAccessBanner extends StatelessWidget {
  const _LimitedAccessBanner({required this.onSelectMore});

  final VoidCallback onSelectMore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Material(
        color: const Color(0xFFFFF1D6),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onSelectMore,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5A85B).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    size: 16,
                    color: Color(0xFFB07724),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.limitedAccessBanner,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF7A5418),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.limitedAccessAction,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB07724),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: Color(0xFFB07724),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PermissionDenied extends StatelessWidget {
  const _PermissionDenied({required this.onRetry});

  final VoidCallback onRetry;

  void _showRationale(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.permissionWhyTitle),
        content: Text(l10n.permissionWhyBody),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.permissionWhyClose),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 36,
                color: Color(0xFF1F1F1F),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.permissionTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
                color: Color(0xFF1F1F1F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.permissionBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: const Color(0xFF1F1F1F).withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(l10n.retryButton),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1F1F1F),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: PhotoManager.openSetting,
              child: Text(l10n.openSettingsButton),
            ),
            TextButton(
              onPressed: () => _showRationale(context),
              child: Text(l10n.permissionWhyTitle),
            ),
          ],
        ),
      ),
    );
  }
}
