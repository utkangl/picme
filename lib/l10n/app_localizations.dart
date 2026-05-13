import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// App name
  ///
  /// In tr, this message translates to:
  /// **'Picme'**
  String get appTitle;

  /// Bottom nav - clean tab
  ///
  /// In tr, this message translates to:
  /// **'Temizle'**
  String get navClean;

  /// Bottom nav - review/queue tab
  ///
  /// In tr, this message translates to:
  /// **'İncele'**
  String get navReview;

  /// Home screen section header
  ///
  /// In tr, this message translates to:
  /// **'Kategoriler'**
  String get categories;

  /// Expand categories grid to show every tile
  ///
  /// In tr, this message translates to:
  /// **'Tümünü göster ({count})'**
  String categoriesShowAll(int count);

  /// Collapse expanded categories grid
  ///
  /// In tr, this message translates to:
  /// **'Daha az göster'**
  String get categoriesCollapse;

  /// Home screen section header
  ///
  /// In tr, this message translates to:
  /// **'Son Eklenenler'**
  String get recent;

  /// Hero card title on home
  ///
  /// In tr, this message translates to:
  /// **'Galerini hafiflet'**
  String get homeHeroTitle;

  /// Hero card subtitle on home
  ///
  /// In tr, this message translates to:
  /// **'Sola kaydır ve sırala, sağa kaydır ve sakla.'**
  String get homeHeroSubtitle;

  /// Stats label - total media count
  ///
  /// In tr, this message translates to:
  /// **'Toplam'**
  String get statsTotal;

  /// Stats label - queued for deletion count
  ///
  /// In tr, this message translates to:
  /// **'Kuyrukta'**
  String get statsQueued;

  /// Stats label - kept count
  ///
  /// In tr, this message translates to:
  /// **'Saklanan'**
  String get statsKept;

  /// Settings section header
  ///
  /// In tr, this message translates to:
  /// **'İzinler'**
  String get settingsSectionPermissions;

  /// Settings section header
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get settingsSectionLanguage;

  /// Settings section header
  ///
  /// In tr, this message translates to:
  /// **'Verilerim'**
  String get settingsSectionData;

  /// Settings section header
  ///
  /// In tr, this message translates to:
  /// **'Yardım'**
  String get settingsSectionGuide;

  /// Settings section header
  ///
  /// In tr, this message translates to:
  /// **'Hakkında'**
  String get settingsSectionAbout;

  /// Settings tile title for language picker
  ///
  /// In tr, this message translates to:
  /// **'Uygulama dili'**
  String get languageTitle;

  /// Language option - follow system
  ///
  /// In tr, this message translates to:
  /// **'Sistem dilini kullan'**
  String get languageSystem;

  /// Language option
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get languageTurkish;

  /// Language option
  ///
  /// In tr, this message translates to:
  /// **'İngilizce'**
  String get languageEnglish;

  /// Sort chip label
  ///
  /// In tr, this message translates to:
  /// **'En Yeni'**
  String get sortNewest;

  /// Sort chip label
  ///
  /// In tr, this message translates to:
  /// **'En Eski'**
  String get sortOldest;

  /// Sort chip label - largest file size first
  ///
  /// In tr, this message translates to:
  /// **'En Büyük'**
  String get sortLargest;

  /// Gallery category
  ///
  /// In tr, this message translates to:
  /// **'Tüm Medya'**
  String get catAllMedia;

  /// Gallery category
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraflar'**
  String get catPhotos;

  /// Gallery category
  ///
  /// In tr, this message translates to:
  /// **'Videolar'**
  String get catVideos;

  /// Gallery category
  ///
  /// In tr, this message translates to:
  /// **'Ekran Görüntüleri'**
  String get catScreenshots;

  /// Gallery category
  ///
  /// In tr, this message translates to:
  /// **'İndirilenler'**
  String get catDownloads;

  /// Permission denied screen title
  ///
  /// In tr, this message translates to:
  /// **'Galeri erişimi gerekli'**
  String get permissionTitle;

  /// Permission denied screen body
  ///
  /// In tr, this message translates to:
  /// **'Picme galerini görebilmen için fotoğraflara erişim izni vermen gerekiyor.'**
  String get permissionBody;

  /// Retry button label
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get retryButton;

  /// Open system settings button
  ///
  /// In tr, this message translates to:
  /// **'Ayarları aç'**
  String get openSettingsButton;

  /// Snackbar after deletion
  ///
  /// In tr, this message translates to:
  /// **'{count} öğe silindi'**
  String itemsDeleted(int count);

  /// Snackbar on delete error
  ///
  /// In tr, this message translates to:
  /// **'Silinemedi: {error}'**
  String deleteError(String error);

  /// Settings screen title
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settingsTitle;

  /// Settings tile title
  ///
  /// In tr, this message translates to:
  /// **'Galeri izin ayarlarını aç'**
  String get galleryPermTitle;

  /// Settings tile subtitle
  ///
  /// In tr, this message translates to:
  /// **'Sistem izin ekranını açar'**
  String get galleryPermSubtitle;

  /// Settings tile title
  ///
  /// In tr, this message translates to:
  /// **'Silme kuyruğunu temizle'**
  String get clearQueueTitle;

  /// Settings tile subtitle
  ///
  /// In tr, this message translates to:
  /// **'{count} öğe sırada'**
  String clearQueueSubtitle(int count);

  /// Confirmation dialog title
  ///
  /// In tr, this message translates to:
  /// **'Kuyruk temizlensin mi?'**
  String get clearQueueDialogTitle;

  /// Confirmation dialog body
  ///
  /// In tr, this message translates to:
  /// **'Kuyruktaki öğeler silinmez, sadece listeden çıkar.'**
  String get clearQueueDialogBody;

  /// Confirm button label
  ///
  /// In tr, this message translates to:
  /// **'Temizle'**
  String get clearQueueConfirm;

  /// Success snackbar
  ///
  /// In tr, this message translates to:
  /// **'Kuyruk temizlendi'**
  String get clearQueueSuccess;

  /// Settings tile title
  ///
  /// In tr, this message translates to:
  /// **'Tutulanları sıfırla'**
  String get resetKeptTitle;

  /// Settings tile subtitle when empty
  ///
  /// In tr, this message translates to:
  /// **'Henüz tutulan öğe yok'**
  String get resetKeptSubtitleEmpty;

  /// Settings tile subtitle
  ///
  /// In tr, this message translates to:
  /// **'{count} öğe tekrar deste başına gelir'**
  String resetKeptSubtitle(int count);

  /// Confirmation dialog title
  ///
  /// In tr, this message translates to:
  /// **'Tutulanlar sıfırlansın mı?'**
  String get resetKeptDialogTitle;

  /// Confirmation dialog body
  ///
  /// In tr, this message translates to:
  /// **'Sağa atarak \"tut\" dediğin öğeler tekrar deste başına gelir.'**
  String get resetKeptDialogBody;

  /// Confirm button label
  ///
  /// In tr, this message translates to:
  /// **'Sıfırla'**
  String get resetKeptConfirm;

  /// Success snackbar
  ///
  /// In tr, this message translates to:
  /// **'Tutulanlar sıfırlandı'**
  String get resetKeptSuccess;

  /// Settings tile title
  ///
  /// In tr, this message translates to:
  /// **'Rehberi tekrar göster'**
  String get restartTourTitle;

  /// Settings tile subtitle
  ///
  /// In tr, this message translates to:
  /// **'Uygulama içi tanıtım turunu yeniden başlat'**
  String get restartTourSubtitle;

  /// Settings screen about text
  ///
  /// In tr, this message translates to:
  /// **'Hızlı ve yerel öncelikli galeri temizliği. Kuyruk, tutulanlar, çökme raporları ve reklam destekli ücretsiz kullanım detayları Gizlilik Politikası\'nda açıklanır.'**
  String get settingsAbout;

  /// Cancel button label
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get cancel;

  /// Queue screen title
  ///
  /// In tr, this message translates to:
  /// **'İnceleme Kuyruğu ({count})'**
  String reviewQueueTitle(int count);

  /// Empty queue message
  ///
  /// In tr, this message translates to:
  /// **'Kuyruk boş.'**
  String get queueEmpty;

  /// Delete button label
  ///
  /// In tr, this message translates to:
  /// **'{count} öğeyi sil'**
  String deleteItemsButton(int count);

  /// Confirmation dialog title
  ///
  /// In tr, this message translates to:
  /// **'Silmeyi Onayla'**
  String get confirmDeleteTitle;

  /// Confirmation dialog body
  ///
  /// In tr, this message translates to:
  /// **'{count} öğe kalıcı olarak silinecek.'**
  String confirmDeleteBody(int count);

  /// Delete button label
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get delete;

  /// History screen title
  ///
  /// In tr, this message translates to:
  /// **'Silme Geçmişi'**
  String get historyTitle;

  /// Empty history message
  ///
  /// In tr, this message translates to:
  /// **'Henüz silme geçmişi yok'**
  String get historyEmpty;

  /// History entry description
  ///
  /// In tr, this message translates to:
  /// **'{count} öğe kalıcı silindi'**
  String historyItemDeleted(int count);

  /// Swipe hint label on card deck
  ///
  /// In tr, this message translates to:
  /// **'Sol: Sil  •  Sağ: Tut'**
  String get swipeHint;

  /// Keep swipe hint chip
  ///
  /// In tr, this message translates to:
  /// **'TUT'**
  String get keep;

  /// Delete swipe hint chip
  ///
  /// In tr, this message translates to:
  /// **'SİL'**
  String get deleteLabel;

  /// Undo button tooltip
  ///
  /// In tr, this message translates to:
  /// **'Geri al'**
  String get undoButton;

  /// Undo button on empty state
  ///
  /// In tr, this message translates to:
  /// **'Son hamleyi geri al'**
  String get undoLastMove;

  /// Empty swipe deck message
  ///
  /// In tr, this message translates to:
  /// **'Tüm medyalar tarandı.'**
  String get allScanned;

  /// Coach overlay skip button
  ///
  /// In tr, this message translates to:
  /// **'Atla'**
  String get coachSkip;

  /// Coach tooltip next button
  ///
  /// In tr, this message translates to:
  /// **'Sonraki'**
  String get coachNext;

  /// Coach tooltip last step button
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get coachDone;

  /// Coach tooltip last step button label that opens swipe
  ///
  /// In tr, this message translates to:
  /// **'Başla'**
  String get coachStart;

  /// Coach step title - launches swipe
  ///
  /// In tr, this message translates to:
  /// **'Hadi başlayalım'**
  String get coachHomeStartTitle;

  /// Coach step description - call to action
  ///
  /// In tr, this message translates to:
  /// **'Tüm Medya\'ya dokun ve sola/sağa kaydırarak fotoğraflarını yönetmeye başla.'**
  String get coachHomeStartDesc;

  /// Coach step title
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get coachHomeSettingsTitle;

  /// Coach step description
  ///
  /// In tr, this message translates to:
  /// **'Buradan galeri izinlerini, kuyruğu ve tutulanları yönetebilirsin.'**
  String get coachHomeSettingsDesc;

  /// Coach step title
  ///
  /// In tr, this message translates to:
  /// **'Bir kategori seç'**
  String get coachHomeCategoryTitle;

  /// Coach step description
  ///
  /// In tr, this message translates to:
  /// **'Tüm Medya, Fotoğraflar, Videolar gibi kategorilerden birine dokunarak temizliğe başla.'**
  String get coachHomeCategoryDesc;

  /// Coach step title
  ///
  /// In tr, this message translates to:
  /// **'Silme geçmişi'**
  String get coachHomeHistoryTitle;

  /// Coach step description
  ///
  /// In tr, this message translates to:
  /// **'Kalıcı olarak sildiğin paketlerin kaydını buradan görebilirsin.'**
  String get coachHomeHistoryDesc;

  /// Coach step title
  ///
  /// In tr, this message translates to:
  /// **'Silme kuyruğu'**
  String get coachHomeQueueTitle;

  /// Coach step description
  ///
  /// In tr, this message translates to:
  /// **'Sola kaydırdığın öğeler kuyrukta birikir; toplu kalıcı silmeyi buradan yaparsın.'**
  String get coachHomeQueueDesc;

  /// Swipe intro headline
  ///
  /// In tr, this message translates to:
  /// **'Sola sil, sağa sakla'**
  String get coachSwipeDecideTitle;

  /// Swipe intro body
  ///
  /// In tr, this message translates to:
  /// **'Galerini bir desteye çevirdik. Beğendiğin fotoğrafı sağa, gözden çıkardığını sola kaydır. Tek dokun büyük önizleme açar.'**
  String get coachSwipeDecideDesc;

  /// Swipe intro primary action
  ///
  /// In tr, this message translates to:
  /// **'Anladım, başlayalım'**
  String get swipeIntroCta;

  /// Coach step title
  ///
  /// In tr, this message translates to:
  /// **'Geri al'**
  String get coachSwipeUndoTitle;

  /// Coach step description
  ///
  /// In tr, this message translates to:
  /// **'Son hamleni buradan geri al. Sağa atılan sağdan, sola atılan soldan geri gelir.'**
  String get coachSwipeUndoDesc;

  /// Coach step title
  ///
  /// In tr, this message translates to:
  /// **'Silme kuyruğu'**
  String get coachSwipeQueueTitle;

  /// Coach step description
  ///
  /// In tr, this message translates to:
  /// **'Sola attıkların burada birikir. Hepsini gözden geçirip toplu kalıcı silme yapabilirsin.'**
  String get coachSwipeQueueDesc;

  /// Welcome screen title
  ///
  /// In tr, this message translates to:
  /// **'Picme\'ye Hoş Geldin'**
  String get welcomeTitle;

  /// Welcome screen subtitle
  ///
  /// In tr, this message translates to:
  /// **'Galerinizi hızlıca temizleyin'**
  String get welcomeSubtitle;

  /// Startup loading screen title
  ///
  /// In tr, this message translates to:
  /// **'Picme hazırlanıyor'**
  String get startupLoadingTitle;

  /// Startup loading screen subtitle while root gate initializes
  ///
  /// In tr, this message translates to:
  /// **'İlk ekran açılmadan önce temizleme deneyimi hazırlanıyor.'**
  String get startupLoadingSubtitle;

  /// Startup loading subtitle while home bootstrap finishes
  ///
  /// In tr, this message translates to:
  /// **'Galeri durumun geri yükleniyor ve ilk genel görünüm hazırlanıyor.'**
  String get startupLoadingHomeSubtitle;

  /// Startup loading step label
  ///
  /// In tr, this message translates to:
  /// **'Kuyruk, tutulanlar ve tercihler geri yükleniyor'**
  String get startupLoadingStepState;

  /// Startup loading step label
  ///
  /// In tr, this message translates to:
  /// **'Galeri erişimi kontrol ediliyor ve medya özeti hazırlanıyor'**
  String get startupLoadingStepGallery;

  /// Startup loading step label
  ///
  /// In tr, this message translates to:
  /// **'Daha akıcı bir başlangıç için deneyim ısınıyor'**
  String get startupLoadingStepExperience;

  /// Welcome feature 1 title
  ///
  /// In tr, this message translates to:
  /// **'Tamamen Yerel'**
  String get welcomeFeature1Title;

  /// Welcome feature 1 body
  ///
  /// In tr, this message translates to:
  /// **'Galerin yalnızca cihazında taranır. Hiçbir veri sunucuya gönderilmez.'**
  String get welcomeFeature1Body;

  /// Welcome feature 2 title
  ///
  /// In tr, this message translates to:
  /// **'Sen Onaylamadan Silinmez'**
  String get welcomeFeature2Title;

  /// Welcome feature 2 body
  ///
  /// In tr, this message translates to:
  /// **'Öğeler önce kuyruğa alınır; kalıcı silme ancak senin onayınla gerçekleşir.'**
  String get welcomeFeature2Body;

  /// Welcome feature 3 title
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Önce Gelir'**
  String get welcomeFeature3Title;

  /// Welcome feature 3 body
  ///
  /// In tr, this message translates to:
  /// **'Medyan cihazında kalır. Picme reklam gösterebilir ve çökme raporları toplayabilir, ancak fotoğraf ve videolarını sunucuya yüklemez.'**
  String get welcomeFeature3Body;

  /// Welcome continue button
  ///
  /// In tr, this message translates to:
  /// **'Galerime İzin Ver'**
  String get welcomeContinueButton;

  /// Welcome privacy note
  ///
  /// In tr, this message translates to:
  /// **'Devam ederek Gizlilik Politikası\'nı kabul etmiş olursun.'**
  String get welcomePrivacyNote;

  /// Permission rationale dialog title
  ///
  /// In tr, this message translates to:
  /// **'Neden galeri erişimi?'**
  String get permissionWhyTitle;

  /// Permission rationale dialog body
  ///
  /// In tr, this message translates to:
  /// **'Picme, fotoğraf ve videolarınızı listeleyip kaydırayarak gözden geçirmenizi sağlamak için galeri okuma iznine ihtiyaç duyar. Hiçbir dosya izinsiz silinmez ve verileriniz cihazınızda kalır.'**
  String get permissionWhyBody;

  /// Permission rationale dialog close button
  ///
  /// In tr, this message translates to:
  /// **'Anladım'**
  String get permissionWhyClose;

  /// Limited access banner text
  ///
  /// In tr, this message translates to:
  /// **'Yalnızca seçili medyalara erişim var.'**
  String get limitedAccessBanner;

  /// Limited access banner action button
  ///
  /// In tr, this message translates to:
  /// **'Daha fazla seç'**
  String get limitedAccessAction;

  /// Queue header summary with size
  ///
  /// In tr, this message translates to:
  /// **'{count} öğe • ~{size}'**
  String queueSummary(int count, String size);

  /// Queue stat chip label for total size
  ///
  /// In tr, this message translates to:
  /// **'Boyut'**
  String get queueStatSize;

  /// Queue stat chip label for photo count
  ///
  /// In tr, this message translates to:
  /// **'Foto'**
  String get queueStatPhotos;

  /// Queue stat chip label for video count
  ///
  /// In tr, this message translates to:
  /// **'Video'**
  String get queueStatVideos;

  /// Queue controls label for media filter
  ///
  /// In tr, this message translates to:
  /// **'Göster'**
  String get queueFilterLabel;

  /// Queue filter label for all items
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get queueFilterAll;

  /// Queue filter label for photos
  ///
  /// In tr, this message translates to:
  /// **'Foto'**
  String get queueFilterPhotos;

  /// Queue filter label for videos
  ///
  /// In tr, this message translates to:
  /// **'Video'**
  String get queueFilterVideos;

  /// Queue controls label for sort selector
  ///
  /// In tr, this message translates to:
  /// **'Sırala'**
  String get queueSortLabel;

  /// Queue sort chip label for added order
  ///
  /// In tr, this message translates to:
  /// **'Eklenme sırası'**
  String get queueSortAdded;

  /// Queue sort chip label for largest files first
  ///
  /// In tr, this message translates to:
  /// **'Büyükten küçüğe'**
  String get queueSortSize;

  /// Delete button label with size
  ///
  /// In tr, this message translates to:
  /// **'{count} öğeyi sil (~{size})'**
  String deleteItemsButtonWithSize(int count, String size);

  /// Confirmation dialog body with size
  ///
  /// In tr, this message translates to:
  /// **'{count} öğe (~{size}) kalıcı olarak silinecek. Bu işlem geri alınamaz.'**
  String confirmDeleteBodyWithSize(int count, String size);

  /// Privacy policy settings tile title
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Politikası'**
  String get privacyPolicyTitle;

  /// Privacy policy settings tile subtitle
  ///
  /// In tr, this message translates to:
  /// **'Verilerinizin nasıl kullanıldığını öğrenin'**
  String get privacyPolicySubtitle;

  /// Settings tile to open kept items list
  ///
  /// In tr, this message translates to:
  /// **'Tutulanları görüntüle'**
  String get viewKeptTitle;

  /// Settings tile subtitle showing kept count
  ///
  /// In tr, this message translates to:
  /// **'{count} öğe tutuluyor'**
  String viewKeptSubtitle(int count);

  /// Kept list screen title
  ///
  /// In tr, this message translates to:
  /// **'Tutulanlar ({count})'**
  String keptListTitle(int count);

  /// Empty state for kept list screen
  ///
  /// In tr, this message translates to:
  /// **'Henüz tutulan öğe yok.'**
  String get keptListEmpty;

  /// Tooltip on remove button in kept list
  ///
  /// In tr, this message translates to:
  /// **'Tutulanlardan çıkar'**
  String get unkeepTooltip;

  /// Empty state title when category folder doesn't exist on device
  ///
  /// In tr, this message translates to:
  /// **'Klasör bulunamadı'**
  String get categoryNotFoundTitle;

  /// Empty state subtitle when category folder doesn't exist
  ///
  /// In tr, this message translates to:
  /// **'Bu cihazda \"{category}\" klasörü yok.'**
  String categoryNotFoundSubtitle(String category);

  /// Go back button label
  ///
  /// In tr, this message translates to:
  /// **'Geri dön'**
  String get goBack;

  /// Filter bottom sheet title
  ///
  /// In tr, this message translates to:
  /// **'Filtrele'**
  String get filterTitle;

  /// Filter section: date
  ///
  /// In tr, this message translates to:
  /// **'Tarih'**
  String get filterDateLabel;

  /// Filter section: file size
  ///
  /// In tr, this message translates to:
  /// **'Boyut'**
  String get filterSizeLabel;

  /// Filter date preset: no filter
  ///
  /// In tr, this message translates to:
  /// **'Hepsi'**
  String get filterDateAll;

  /// Filter date preset: older than 1 year
  ///
  /// In tr, this message translates to:
  /// **'1 yıldan eski'**
  String get filterDate1Year;

  /// Filter date preset: older than 3 years
  ///
  /// In tr, this message translates to:
  /// **'3 yıldan eski'**
  String get filterDate3Years;

  /// Filter date preset: older than 5 years
  ///
  /// In tr, this message translates to:
  /// **'5 yıldan eski'**
  String get filterDate5Years;

  /// Filter size preset: no filter
  ///
  /// In tr, this message translates to:
  /// **'Hepsi'**
  String get filterSizeAll;

  /// Filter size preset: >10 MB
  ///
  /// In tr, this message translates to:
  /// **'10 MB üzeri'**
  String get filterSize10MB;

  /// Filter size preset: >50 MB
  ///
  /// In tr, this message translates to:
  /// **'50 MB üzeri'**
  String get filterSize50MB;

  /// Filter size preset: >100 MB
  ///
  /// In tr, this message translates to:
  /// **'100 MB üzeri'**
  String get filterSize100MB;

  /// Reset filters button
  ///
  /// In tr, this message translates to:
  /// **'Sıfırla'**
  String get filterReset;

  /// Apply filters button
  ///
  /// In tr, this message translates to:
  /// **'Uygula'**
  String get filterApply;

  /// Badge text when filters are active
  ///
  /// In tr, this message translates to:
  /// **'{count} filtre aktif'**
  String filterActiveLabel(int count);

  /// Settings tile: rate the app
  ///
  /// In tr, this message translates to:
  /// **'Uygulamayı değerlendir'**
  String get rateAppTitle;

  /// Settings tile: rate app subtitle
  ///
  /// In tr, this message translates to:
  /// **'Play Store\'da yıldız ver'**
  String get rateAppSubtitle;

  /// Settings tile: send feedback
  ///
  /// In tr, this message translates to:
  /// **'Geri bildirim gönder'**
  String get feedbackTitle;

  /// Settings tile: feedback subtitle
  ///
  /// In tr, this message translates to:
  /// **'Öneri ve şikayetlerinizi iletin'**
  String get feedbackSubtitle;

  /// Settings tile title for ads disclosure
  ///
  /// In tr, this message translates to:
  /// **'Reklamlar ve sponsorlu içerik'**
  String get adsDisclosureTitle;

  /// Settings tile subtitle for ads disclosure
  ///
  /// In tr, this message translates to:
  /// **'Banner ve sponsorlu kartlar Picme\'nin ücretsiz kalmasına yardımcı olur.'**
  String get adsDisclosureSubtitle;

  /// Temporary settings toggle title for showing ads during testing
  ///
  /// In tr, this message translates to:
  /// **'Reklamları göster (test)'**
  String get adsTestingTitle;

  /// Temporary settings toggle subtitle for hiding ads
  ///
  /// In tr, this message translates to:
  /// **'Ekran görüntüsü veya manuel test için bunu geçici olarak kapatabilirsin.'**
  String get adsTestingSubtitle;

  /// Settings tile title for AdMob test device ids
  ///
  /// In tr, this message translates to:
  /// **'AdMob test cihazları'**
  String get admobTestDeviceTitle;

  /// Settings tile subtitle when no AdMob test device ids are configured
  ///
  /// In tr, this message translates to:
  /// **'Henüz test cihazı kimliği eklenmedi.'**
  String get admobTestDeviceSubtitleEmpty;

  /// Settings tile subtitle when AdMob test device ids are configured
  ///
  /// In tr, this message translates to:
  /// **'{count} test cihazı kimliği tanımlı'**
  String admobTestDeviceSubtitleConfigured(int count);

  /// Bottom sheet title for AdMob test device ids
  ///
  /// In tr, this message translates to:
  /// **'AdMob test cihazı kimlikleri'**
  String get admobTestDeviceDialogTitle;

  /// Bottom sheet body for AdMob test device ids
  ///
  /// In tr, this message translates to:
  /// **'Logcat\'te görünen test cihazı hash\'ini buraya yapıştır. Her satıra bir ID yazabilir veya virgülle ayırabilirsin.'**
  String get admobTestDeviceDialogBody;

  /// Hint text for AdMob test device ids field
  ///
  /// In tr, this message translates to:
  /// **'33BE2250B43518CCDA7DE426D04EE231'**
  String get admobTestDeviceDialogHint;

  /// Hint telling user to restart after saving AdMob test device ids
  ///
  /// In tr, this message translates to:
  /// **'Kaydettikten sonra yeni banner istekleri hemen test moduna gecmeli. Acik slot ayni kalirsa ekrani bir kez kapatip yeniden ac.'**
  String get admobTestDeviceRestartHint;

  /// Save button label for AdMob test device ids
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get admobTestDeviceSave;

  /// Snackbar after saving AdMob test device ids
  ///
  /// In tr, this message translates to:
  /// **'Test cihazı kimlikleri kaydedildi'**
  String get admobTestDeviceSaved;

  /// Settings tile title for debug banner source switch
  ///
  /// In tr, this message translates to:
  /// **'Ana banner kaynağı (debug)'**
  String get admobDebugBannerSourceTitle;

  /// Subtitle when real home banner unit is active
  ///
  /// In tr, this message translates to:
  /// **'Kendi gerçek AdMob home banner birimin kullanılıyor.'**
  String get admobDebugBannerSourceReal;

  /// Subtitle when sample home banner unit is active
  ///
  /// In tr, this message translates to:
  /// **'SDK/UI doğrulaması için Google sample banner birimi kullanılıyor.'**
  String get admobDebugBannerSourceSample;

  /// Settings tile title for swipe sponsored debug source switch
  ///
  /// In tr, this message translates to:
  /// **'Swipe sponsorlu kaynak (debug)'**
  String get admobDebugSwipeSourceTitle;

  /// Subtitle when real swipe sponsored unit is active
  ///
  /// In tr, this message translates to:
  /// **'Tanimliysa gercek swipe sponsorlu reklam birimin kullaniliyor.'**
  String get admobDebugSwipeSourceReal;

  /// Subtitle when sample swipe sponsored unit is active
  ///
  /// In tr, this message translates to:
  /// **'Sponsorlu swipe kartinda Google sample banner birimi kullaniliyor.'**
  String get admobDebugSwipeSourceSample;

  /// Badge text on sponsored swipe card
  ///
  /// In tr, this message translates to:
  /// **'REKLAM'**
  String get sponsoredCardBadge;

  /// Headline on sponsored swipe card
  ///
  /// In tr, this message translates to:
  /// **'Reklam'**
  String get sponsoredCardTitle;

  /// Body text on sponsored swipe card
  ///
  /// In tr, this message translates to:
  /// **'Reklam'**
  String get sponsoredCardBody;

  /// Hint shown behind sponsored swipe card
  ///
  /// In tr, this message translates to:
  /// **'Sponsorlu kart • devam etmek için iki yöne de kaydır'**
  String get sponsoredCardSwipeHint;

  /// Hint shown while sponsored card is locked
  ///
  /// In tr, this message translates to:
  /// **'Sponsorlu kart kilitli • sayaç bitene kadar bekle'**
  String get sponsoredCardLockedHint;

  /// Lock chip label shown on early swipe attempts
  ///
  /// In tr, this message translates to:
  /// **'KİLİTLİ'**
  String get sponsoredCardLocked;

  /// Status text while sponsored card is locked
  ///
  /// In tr, this message translates to:
  /// **'{seconds} saniye içinde açılıyor...'**
  String sponsoredCardUnlockingCountdown(int seconds);

  /// Status text once sponsored card becomes swipeable
  ///
  /// In tr, this message translates to:
  /// **'Kilit açıldı • devam etmek için kaydır.'**
  String get sponsoredCardUnlockReady;

  /// Center hint chip on sponsored swipe card
  ///
  /// In tr, this message translates to:
  /// **'DEVAM'**
  String get sponsoredCardContinue;

  /// Hero subtitle when user has saved storage
  ///
  /// In tr, this message translates to:
  /// **'Şu ana kadar {amount} alan açtın'**
  String homeHeroSavings(String amount);

  /// History summary card title
  ///
  /// In tr, this message translates to:
  /// **'Toplam tasarruf'**
  String get historySavingsTitle;

  /// History summary card subtitle
  ///
  /// In tr, this message translates to:
  /// **'{count} silme oturumunda'**
  String historySavingsSubtitle(int count);

  /// History entry description with size
  ///
  /// In tr, this message translates to:
  /// **'{count} öğe silindi · {amount}'**
  String historyItemDeletedWithSize(int count, String amount);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
