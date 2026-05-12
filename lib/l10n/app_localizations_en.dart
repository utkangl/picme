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
  String categoriesShowAll(int count) {
    return 'Show all ($count)';
  }

  @override
  String get categoriesCollapse => 'Show less';

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
  String get settingsSectionLanguage => 'Language';

  @override
  String get settingsSectionData => 'My data';

  @override
  String get settingsSectionGuide => 'Help';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get languageTitle => 'App language';

  @override
  String get languageSystem => 'Use system language';

  @override
  String get languageTurkish => 'Turkish';

  @override
  String get languageEnglish => 'English';

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
      'Fast, local-first gallery cleanup. Queue, kept items, crash reporting, and ad-supported free access are all explained in Privacy Policy.';

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
  String get coachStart => 'Start';

  @override
  String get coachHomeStartTitle => 'Let\'s get started';

  @override
  String get coachHomeStartDesc =>
      'Tap All Media and swipe left/right to start managing your photos.';

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
  String get startupLoadingTitle => 'Preparing Picme';

  @override
  String get startupLoadingSubtitle =>
      'Warming up your cleanup flow before the first screen appears.';

  @override
  String get startupLoadingHomeSubtitle =>
      'Restoring your gallery state and loading the first overview.';

  @override
  String get startupLoadingStepState =>
      'Restoring queue, kept items, and preferences';

  @override
  String get startupLoadingStepGallery =>
      'Checking gallery access and loading your media overview';

  @override
  String get startupLoadingStepExperience =>
      'Warming up the swipe experience for a smoother start';

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
      'Your media stays on-device. Picme may show ads and collect crash reports, but it does not upload your photos or videos.';

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

  @override
  String get categoryNotFoundTitle => 'Folder not found';

  @override
  String categoryNotFoundSubtitle(String category) {
    return 'No \"$category\" folder on this device.';
  }

  @override
  String get goBack => 'Go back';

  @override
  String get filterTitle => 'Filter';

  @override
  String get filterDateLabel => 'Date';

  @override
  String get filterSizeLabel => 'Size';

  @override
  String get filterDateAll => 'Any';

  @override
  String get filterDate1Year => 'Older than 1 year';

  @override
  String get filterDate3Years => 'Older than 3 years';

  @override
  String get filterDate5Years => 'Older than 5 years';

  @override
  String get filterSizeAll => 'Any';

  @override
  String get filterSize10MB => 'Over 10 MB';

  @override
  String get filterSize50MB => 'Over 50 MB';

  @override
  String get filterSize100MB => 'Over 100 MB';

  @override
  String get filterReset => 'Reset';

  @override
  String get filterApply => 'Apply';

  @override
  String filterActiveLabel(int count) {
    return '$count filter active';
  }

  @override
  String get rateAppTitle => 'Rate the app';

  @override
  String get rateAppSubtitle => 'Leave a star on the Play Store';

  @override
  String get feedbackTitle => 'Send feedback';

  @override
  String get feedbackSubtitle => 'Share your suggestions and issues';

  @override
  String get adsDisclosureTitle => 'Ads & sponsorships';

  @override
  String get adsDisclosureSubtitle =>
      'Banner and sponsored cards help keep Picme free.';

  @override
  String get adsTestingTitle => 'Show ads (testing)';

  @override
  String get adsTestingSubtitle =>
      'Turn this off temporarily for screenshots or manual QA.';

  @override
  String get admobTestDeviceTitle => 'AdMob test devices';

  @override
  String get admobTestDeviceSubtitleEmpty => 'No device IDs configured yet.';

  @override
  String admobTestDeviceSubtitleConfigured(int count) {
    return '$count test device ID configured';
  }

  @override
  String get admobTestDeviceDialogTitle => 'AdMob test device IDs';

  @override
  String get admobTestDeviceDialogBody =>
      'Paste the test device hash from logcat here. Use one ID per line or separate with commas.';

  @override
  String get admobTestDeviceDialogHint => '33BE2250B43518CCDA7DE426D04EE231';

  @override
  String get admobTestDeviceRestartHint =>
      'New banner requests should switch to test mode right after saving. If the current slot is already open, reopen the screen once.';

  @override
  String get admobTestDeviceSave => 'Save';

  @override
  String get admobTestDeviceSaved => 'Test device IDs saved';

  @override
  String get admobDebugBannerSourceTitle => 'Home banner source (debug)';

  @override
  String get admobDebugBannerSourceReal =>
      'Using your real AdMob home banner unit.';

  @override
  String get admobDebugBannerSourceSample =>
      'Using Google\'s sample banner unit for SDK/UI verification.';

  @override
  String get admobDebugSwipeSourceTitle => 'Swipe sponsored source (debug)';

  @override
  String get admobDebugSwipeSourceReal =>
      'Using your real swipe sponsored ad unit when configured.';

  @override
  String get admobDebugSwipeSourceSample =>
      'Using Google\'s sample banner unit inside the sponsored swipe card.';

  @override
  String get sponsoredCardBadge => 'AD';

  @override
  String get sponsoredCardTitle => 'Advertisement';

  @override
  String get sponsoredCardBody => 'Advertisement';

  @override
  String get sponsoredCardSwipeHint =>
      'Sponsored card • swipe either way to continue';

  @override
  String get sponsoredCardLockedHint =>
      'Sponsored card locked • wait for the timer';

  @override
  String get sponsoredCardLocked => 'LOCKED';

  @override
  String get sponsoredCardUnlocking => 'Unlocking in 4 seconds...';

  @override
  String get sponsoredCardUnlockReady => 'Unlocked • swipe to continue.';

  @override
  String get sponsoredCardContinue => 'CONTINUE';

  @override
  String homeHeroSavings(String amount) {
    return 'You\'ve freed up $amount so far';
  }

  @override
  String get historySavingsTitle => 'Total savings';

  @override
  String historySavingsSubtitle(int count) {
    return '$count delete sessions';
  }

  @override
  String historyItemDeletedWithSize(int count, String amount) {
    return '$count items · $amount';
  }
}
