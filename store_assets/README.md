# Store Assets Checklist

## Dosyalar / Files
- `privacy_policy.md` — İki dilli gizlilik politikası metni (GitHub Pages/Notion'a yükle)
- `description-tr.md` — Play Store TR açıklamaları
- `description-en.md` — Play Store EN açıklamaları

## Eksik / Still Needed

### App Icon
1. `assets/icon/app_icon.png` — 1024×1024 PNG, saydam arka plan (launcher icon)
2. `assets/icon/app_icon_foreground.png` — Adaptive icon foreground layer (1024×1024)
3. Ardından çalıştır: `flutter pub run flutter_launcher_icons`

### Splash Screen
1. Yukarıdaki `app_icon.png` oluşturulunca splash da hazır.
2. Çalıştır: `flutter pub run flutter_native_splash:create`

### Play Store Görselleri
- `icon-512.png` — 512×512 PNG (Play Store ikonuna)
- `feature-graphic-1024x500.png` — 1024×500 px (Feature Graphic)
- `screenshots/` — en az 2, ideal 4-8 ekran görüntüsü (1080×1920 veya 1080×2400)

### Firebase
- Firebase Console'dan Android projesi ekle (Package: `com.picme.app.picme`)
- `google-services.json` indir → `android/app/` klasörüne koy
- Build ve cihazda test crash'i doğrula

### Privacy Policy URL
- `privacy_policy.md` içeriğini GitHub Pages (veya Notion) üzerinde yayınla
- URL'yi `lib/src/features/home/presentation/settings_screen.dart` ve
  `lib/src/features/onboarding/presentation/welcome_screen.dart` içindeki
  `https://picme.app/privacy` placeholder'ı ile değiştir

### Play Console — Data Safety
- Personal info: **Toplanmıyor**
- Photos and videos: **Accessed** (kullanıcı onayıyla silme)
- App activity: **Crash logs** (Firebase Crashlytics)
