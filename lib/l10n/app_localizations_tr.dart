// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Picme';

  @override
  String get navClean => 'Temizle';

  @override
  String get navReview => 'İncele';

  @override
  String get categories => 'Kategoriler';

  @override
  String categoriesShowAll(int count) {
    return 'Tümünü göster ($count)';
  }

  @override
  String get categoriesCollapse => 'Daha az göster';

  @override
  String get recent => 'Son Eklenenler';

  @override
  String get homeHeroTitle => 'Galerini hafiflet';

  @override
  String get homeHeroSubtitle => 'Sola kaydır ve sırala, sağa kaydır ve sakla.';

  @override
  String get statsTotal => 'Toplam';

  @override
  String get statsQueued => 'Kuyrukta';

  @override
  String get statsKept => 'Saklanan';

  @override
  String get settingsSectionPermissions => 'İzinler';

  @override
  String get settingsSectionLanguage => 'Dil';

  @override
  String get settingsSectionData => 'Verilerim';

  @override
  String get settingsSectionGuide => 'Yardım';

  @override
  String get settingsSectionAbout => 'Hakkında';

  @override
  String get languageTitle => 'Uygulama dili';

  @override
  String get languageSystem => 'Sistem dilini kullan';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get languageEnglish => 'İngilizce';

  @override
  String get sortNewest => 'En Yeni';

  @override
  String get sortOldest => 'En Eski';

  @override
  String get sortLargest => 'En Büyük';

  @override
  String get catAllMedia => 'Tüm Medya';

  @override
  String get catPhotos => 'Fotoğraflar';

  @override
  String get catVideos => 'Videolar';

  @override
  String get catScreenshots => 'Ekran Görüntüleri';

  @override
  String get catDownloads => 'İndirilenler';

  @override
  String get permissionTitle => 'Galeri erişimi gerekli';

  @override
  String get permissionBody =>
      'Picme galerini görebilmen için fotoğraflara erişim izni vermen gerekiyor.';

  @override
  String get retryButton => 'Tekrar dene';

  @override
  String get openSettingsButton => 'Ayarları aç';

  @override
  String itemsDeleted(int count) {
    return '$count öğe silindi';
  }

  @override
  String deleteError(String error) {
    return 'Silinemedi: $error';
  }

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get galleryPermTitle => 'Galeri izin ayarlarını aç';

  @override
  String get galleryPermSubtitle => 'Sistem izin ekranını açar';

  @override
  String get clearQueueTitle => 'Silme kuyruğunu temizle';

  @override
  String clearQueueSubtitle(int count) {
    return '$count öğe sırada';
  }

  @override
  String get clearQueueDialogTitle => 'Kuyruk temizlensin mi?';

  @override
  String get clearQueueDialogBody =>
      'Kuyruktaki öğeler silinmez, sadece listeden çıkar.';

  @override
  String get clearQueueConfirm => 'Temizle';

  @override
  String get clearQueueSuccess => 'Kuyruk temizlendi';

  @override
  String get resetKeptTitle => 'Tutulanları sıfırla';

  @override
  String get resetKeptSubtitleEmpty => 'Henüz tutulan öğe yok';

  @override
  String resetKeptSubtitle(int count) {
    return '$count öğe tekrar deste başına gelir';
  }

  @override
  String get resetKeptDialogTitle => 'Tutulanlar sıfırlansın mı?';

  @override
  String get resetKeptDialogBody =>
      'Sağa atarak \"tut\" dediğin öğeler tekrar deste başına gelir.';

  @override
  String get resetKeptConfirm => 'Sıfırla';

  @override
  String get resetKeptSuccess => 'Tutulanlar sıfırlandı';

  @override
  String get restartTourTitle => 'Rehberi tekrar göster';

  @override
  String get restartTourSubtitle =>
      'Uygulama içi tanıtım turunu yeniden başlat';

  @override
  String get settingsAbout =>
      'Hızlı galeri temizliği. Kuyruktaki ve tutulan öğeler uygulama kapansa da korunur.';

  @override
  String get cancel => 'Vazgeç';

  @override
  String reviewQueueTitle(int count) {
    return 'İnceleme Kuyruğu ($count)';
  }

  @override
  String get queueEmpty => 'Kuyruk boş.';

  @override
  String deleteItemsButton(int count) {
    return '$count öğeyi sil';
  }

  @override
  String get confirmDeleteTitle => 'Silmeyi Onayla';

  @override
  String confirmDeleteBody(int count) {
    return '$count öğe kalıcı olarak silinecek.';
  }

  @override
  String get delete => 'Sil';

  @override
  String get historyTitle => 'Silme Geçmişi';

  @override
  String get historyEmpty => 'Henüz silme geçmişi yok';

  @override
  String historyItemDeleted(int count) {
    return '$count öğe kalıcı silindi';
  }

  @override
  String get swipeHint => 'Sol: Sil  •  Sağ: Tut';

  @override
  String get keep => 'TUT';

  @override
  String get deleteLabel => 'SİL';

  @override
  String get undoButton => 'Geri al';

  @override
  String get undoLastMove => 'Son hamleyi geri al';

  @override
  String get allScanned => 'Tüm medyalar tarandı.';

  @override
  String get coachSkip => 'Atla';

  @override
  String get coachNext => 'Sonraki';

  @override
  String get coachDone => 'Tamam';

  @override
  String get coachStart => 'Başla';

  @override
  String get coachHomeStartTitle => 'Hadi başlayalım';

  @override
  String get coachHomeStartDesc =>
      'Tüm Medya\'ya dokun ve sola/sağa kaydırarak fotoğraflarını yönetmeye başla.';

  @override
  String get coachHomeSettingsTitle => 'Ayarlar';

  @override
  String get coachHomeSettingsDesc =>
      'Buradan galeri izinlerini, kuyruğu ve tutulanları yönetebilirsin.';

  @override
  String get coachHomeCategoryTitle => 'Bir kategori seç';

  @override
  String get coachHomeCategoryDesc =>
      'Tüm Medya, Fotoğraflar, Videolar gibi kategorilerden birine dokunarak temizliğe başla.';

  @override
  String get coachHomeHistoryTitle => 'Silme geçmişi';

  @override
  String get coachHomeHistoryDesc =>
      'Kalıcı olarak sildiğin paketlerin kaydını buradan görebilirsin.';

  @override
  String get coachHomeQueueTitle => 'Silme kuyruğu';

  @override
  String get coachHomeQueueDesc =>
      'Sola kaydırdığın öğeler kuyrukta birikir; toplu kalıcı silmeyi buradan yaparsın.';

  @override
  String get coachSwipeDecideTitle => 'Sola sil, sağa sakla';

  @override
  String get coachSwipeDecideDesc =>
      'Galerini bir desteye çevirdik. Beğendiğin fotoğrafı sağa, gözden çıkardığını sola kaydır. Tek dokun büyük önizleme açar.';

  @override
  String get swipeIntroCta => 'Anladım, başlayalım';

  @override
  String get coachSwipeUndoTitle => 'Geri al';

  @override
  String get coachSwipeUndoDesc =>
      'Son hamleni buradan geri al. Sağa atılan sağdan, sola atılan soldan geri gelir.';

  @override
  String get coachSwipeQueueTitle => 'Silme kuyruğu';

  @override
  String get coachSwipeQueueDesc =>
      'Sola attıkların burada birikir. Hepsini gözden geçirip toplu kalıcı silme yapabilirsin.';

  @override
  String get welcomeTitle => 'Picme\'ye Hoş Geldin';

  @override
  String get welcomeSubtitle => 'Galerinizi hızlıca temizleyin';

  @override
  String get welcomeFeature1Title => 'Tamamen Yerel';

  @override
  String get welcomeFeature1Body =>
      'Galerin yalnızca cihazında taranır. Hiçbir veri sunucuya gönderilmez.';

  @override
  String get welcomeFeature2Title => 'Sen Onaylamadan Silinmez';

  @override
  String get welcomeFeature2Body =>
      'Öğeler önce kuyruğa alınır; kalıcı silme ancak senin onayınla gerçekleşir.';

  @override
  String get welcomeFeature3Title => 'Gizlilik Önce Gelir';

  @override
  String get welcomeFeature3Body =>
      'Fotoğraf analizi, reklam hedefleme veya üçüncü taraf paylaşımı yoktur.';

  @override
  String get welcomeContinueButton => 'Galerime İzin Ver';

  @override
  String get welcomePrivacyNote =>
      'Devam ederek Gizlilik Politikası\'nı kabul etmiş olursun.';

  @override
  String get permissionWhyTitle => 'Neden galeri erişimi?';

  @override
  String get permissionWhyBody =>
      'Picme, fotoğraf ve videolarınızı listeleyip kaydırayarak gözden geçirmenizi sağlamak için galeri okuma iznine ihtiyaç duyar. Hiçbir dosya izinsiz silinmez ve verileriniz cihazınızda kalır.';

  @override
  String get permissionWhyClose => 'Anladım';

  @override
  String get limitedAccessBanner => 'Yalnızca seçili medyalara erişim var.';

  @override
  String get limitedAccessAction => 'Daha fazla seç';

  @override
  String queueSummary(int count, String mb) {
    return '$count öğe • ~$mb MB';
  }

  @override
  String deleteItemsButtonWithSize(int count, String mb) {
    return '$count öğeyi sil (~$mb MB)';
  }

  @override
  String confirmDeleteBodyWithSize(int count, String mb) {
    return '$count öğe (~$mb MB) kalıcı olarak silinecek. Bu işlem geri alınamaz.';
  }

  @override
  String get privacyPolicyTitle => 'Gizlilik Politikası';

  @override
  String get privacyPolicySubtitle =>
      'Verilerinizin nasıl kullanıldığını öğrenin';

  @override
  String get viewKeptTitle => 'Tutulanları görüntüle';

  @override
  String viewKeptSubtitle(int count) {
    return '$count öğe tutuluyor';
  }

  @override
  String keptListTitle(int count) {
    return 'Tutulanlar ($count)';
  }

  @override
  String get keptListEmpty => 'Henüz tutulan öğe yok.';

  @override
  String get unkeepTooltip => 'Tutulanlardan çıkar';

  @override
  String get categoryNotFoundTitle => 'Klasör bulunamadı';

  @override
  String categoryNotFoundSubtitle(String category) {
    return 'Bu cihazda \"$category\" klasörü yok.';
  }

  @override
  String get goBack => 'Geri dön';

  @override
  String get filterTitle => 'Filtrele';

  @override
  String get filterDateLabel => 'Tarih';

  @override
  String get filterSizeLabel => 'Boyut';

  @override
  String get filterDateAll => 'Hepsi';

  @override
  String get filterDate1Year => '1 yıldan eski';

  @override
  String get filterDate3Years => '3 yıldan eski';

  @override
  String get filterDate5Years => '5 yıldan eski';

  @override
  String get filterSizeAll => 'Hepsi';

  @override
  String get filterSize10MB => '10 MB üzeri';

  @override
  String get filterSize50MB => '50 MB üzeri';

  @override
  String get filterSize100MB => '100 MB üzeri';

  @override
  String get filterReset => 'Sıfırla';

  @override
  String get filterApply => 'Uygula';

  @override
  String filterActiveLabel(int count) {
    return '$count filtre aktif';
  }

  @override
  String get rateAppTitle => 'Uygulamayı değerlendir';

  @override
  String get rateAppSubtitle => 'Play Store\'da yıldız ver';

  @override
  String get feedbackTitle => 'Geri bildirim gönder';

  @override
  String get feedbackSubtitle => 'Öneri ve şikayetlerinizi iletin';

  @override
  String homeHeroSavings(String amount) {
    return 'Şu ana kadar $amount alan açtın';
  }

  @override
  String get historySavingsTitle => 'Toplam tasarruf';

  @override
  String historySavingsSubtitle(int count) {
    return '$count silme oturumunda';
  }

  @override
  String historyItemDeletedWithSize(int count, String amount) {
    return '$count öğe silindi · $amount';
  }
}
