// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Picme';

  @override
  String get navClean => 'Clean';

  @override
  String get navReview => 'Review';

  @override
  String get categories => 'Categories';

  @override
  String get recent => 'Recent';

  @override
  String get homeHeroTitle => 'Lighten your gallery';

  @override
  String get homeHeroSubtitle => 'Swipe left to queue, right to keep.';

  @override
  String get statsTotal => 'Total';

  @override
  String get statsQueued => 'Queued';

  @override
  String get statsKept => 'Kept';

  @override
  String get settingsSectionPermissions => 'Permissions';

  @override
  String get settingsSectionData => 'My data';

  @override
  String get settingsSectionGuide => 'Help';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get sortNewest => 'Newest';

  @override
  String get sortOldest => 'Oldest';

  @override
  String get sortLargest => 'Largest';

  @override
  String get catAllMedia => 'All Media';

  @override
  String get catPhotos => 'Photos';

  @override
  String get catVideos => 'Videos';

  @override
  String get catScreenshots => 'Screenshots';

  @override
  String get catDownloads => 'Downloads';

  @override
  String get permissionTitle => 'Gallery access required';

  @override
  String get permissionBody =>
      'Picme needs access to your photos to scan your gallery.';

  @override
  String get retryButton => 'Retry';

  @override
  String get openSettingsButton => 'Open Settings';

  @override
  String itemsDeleted(int count) {
    return '$count items deleted';
  }

  @override
  String deleteError(String error) {
    return 'Could not delete: $error';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get galleryPermTitle => 'Open gallery permission settings';

  @override
  String get galleryPermSubtitle => 'Opens the system permission screen';

  @override
  String get clearQueueTitle => 'Clear delete queue';

  @override
  String clearQueueSubtitle(int count) {
    return '$count items in queue';
  }

  @override
  String get clearQueueDialogTitle => 'Clear queue?';

  @override
  String get clearQueueDialogBody =>
      'Items in queue will not be deleted, only removed from the list.';

  @override
  String get clearQueueConfirm => 'Clear';

  @override
  String get clearQueueSuccess => 'Queue cleared';

  @override
  String get resetKeptTitle => 'Reset kept items';

  @override
  String get resetKeptSubtitleEmpty => 'No items kept yet';

  @override
  String resetKeptSubtitle(int count) {
    return '$count items will return to the deck';
  }

  @override
  String get resetKeptDialogTitle => 'Reset kept items?';

  @override
  String get resetKeptDialogBody =>
      'Items you swiped right (\"keep\") will return to the top of the deck.';

  @override
  String get resetKeptConfirm => 'Reset';

  @override
  String get resetKeptSuccess => 'Kept items reset';

  @override
  String get restartTourTitle => 'Show guide again';

  @override
  String get restartTourSubtitle => 'Restart the in-app tutorial';

  @override
  String get settingsAbout =>
      'Fast gallery cleanup. Queued and kept items are preserved when the app is closed.';

  @override
  String get cancel => 'Cancel';

  @override
  String reviewQueueTitle(int count) {
    return 'Review Queue ($count)';
  }

  @override
  String get queueEmpty => 'Queue is empty.';

  @override
  String deleteItemsButton(int count) {
    return 'Delete $count Items';
  }

  @override
  String get confirmDeleteTitle => 'Confirm Delete';

  @override
  String confirmDeleteBody(int count) {
    return '$count item(s) will be deleted permanently.';
  }

  @override
  String get delete => 'Delete';

  @override
  String get historyTitle => 'Delete History';

  @override
  String get historyEmpty => 'No delete history yet';

  @override
  String historyItemDeleted(int count) {
    return '$count items permanently deleted';
  }

  @override
  String get swipeHint => 'Left: Delete  •  Right: Keep';

  @override
  String get keep => 'KEEP';

  @override
  String get deleteLabel => 'DELETE';

  @override
  String get undoButton => 'Undo';

  @override
  String get undoLastMove => 'Undo last move';

  @override
  String get allScanned => 'All media scanned.';

  @override
  String get coachSkip => 'Skip';

  @override
  String get coachNext => 'Next';

  @override
  String get coachDone => 'Done';

  @override
  String get coachHomeSettingsTitle => 'Settings';

  @override
  String get coachHomeSettingsDesc =>
      'Manage gallery permissions, queue, and kept items here.';

  @override
  String get coachHomeCategoryTitle => 'Choose a category';

  @override
  String get coachHomeCategoryDesc =>
      'Tap a category like All Media, Photos, or Videos to start cleaning.';

  @override
  String get coachHomeHistoryTitle => 'Delete history';

  @override
  String get coachHomeHistoryDesc =>
      'See a log of all the batches you have permanently deleted.';

  @override
  String get coachHomeQueueTitle => 'Delete queue';

  @override
  String get coachHomeQueueDesc =>
      'Items you swipe left pile up here; do a bulk permanent delete from here.';

  @override
  String get coachSwipeDecideTitle => 'Left to delete, right to keep';

  @override
  String get coachSwipeDecideDesc =>
      'We turned your gallery into a deck. Swipe right on the ones you love and left on the ones you don\'t. Tap to open a full preview.';

  @override
  String get swipeIntroCta => 'Got it, let\'s start';

  @override
  String get coachSwipeUndoTitle => 'Undo';

  @override
  String get coachSwipeUndoDesc =>
      'Undo your last move here. Kept items come back from the right, deleted from the left.';

  @override
  String get coachSwipeQueueTitle => 'Delete queue';

  @override
  String get coachSwipeQueueDesc =>
      'Items you swipe left pile up here. Review them and do a bulk permanent delete.';

  @override
  String get welcomeTitle => 'Welcome to Picme';

  @override
  String get welcomeSubtitle => 'Clean your gallery, fast';

  @override
  String get welcomeFeature1Title => 'Fully Local';

  @override
  String get welcomeFeature1Body =>
      'Your gallery is scanned on-device only. No data is ever sent to a server.';

  @override
  String get welcomeFeature2Title => 'You Decide What\'s Deleted';

  @override
  String get welcomeFeature2Body =>
      'Items go to a queue first; permanent deletion only happens with your explicit confirmation.';

  @override
  String get welcomeFeature3Title => 'Privacy First';

  @override
  String get welcomeFeature3Body =>
      'No photo analysis, ad targeting, or third-party sharing.';

  @override
  String get welcomeContinueButton => 'Allow Gallery Access';

  @override
  String get welcomePrivacyNote =>
      'By continuing you accept the Privacy Policy.';

  @override
  String get permissionWhyTitle => 'Why gallery access?';

  @override
  String get permissionWhyBody =>
      'Picme needs read access to your gallery to list and display your photos and videos for review. No files are deleted without your confirmation, and your data stays on your device.';

  @override
  String get permissionWhyClose => 'Got it';

  @override
  String get limitedAccessBanner => 'Access limited to selected photos.';

  @override
  String get limitedAccessAction => 'Select more';

  @override
  String queueSummary(int count, String mb) {
    return '$count items • ~$mb MB';
  }

  @override
  String deleteItemsButtonWithSize(int count, String mb) {
    return 'Delete $count Items (~$mb MB)';
  }

  @override
  String confirmDeleteBodyWithSize(int count, String mb) {
    return '$count items (~$mb MB) will be permanently deleted. This cannot be undone.';
  }

  @override
  String get privacyPolicyTitle => 'Privacy Policy';

  @override
  String get privacyPolicySubtitle => 'Learn how your data is used';

  @override
  String get viewKeptTitle => 'View kept items';

  @override
  String viewKeptSubtitle(int count) {
    return '$count items kept';
  }

  @override
  String keptListTitle(int count) {
    return 'Kept Items ($count)';
  }

  @override
  String get keptListEmpty => 'No kept items yet.';

  @override
  String get unkeepTooltip => 'Remove from kept';
}
