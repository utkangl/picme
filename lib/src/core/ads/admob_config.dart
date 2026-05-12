import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum PicmeAdPlacement { homeBanner, swipeSponsoredCard }

/// Central AdMob config for Picme.
abstract final class PicmeAdMobConfig {
  // Android App ID is read from `android/admob.properties` via a manifest
  // placeholder.
  // Home banner and swipe sponsored banner are wired to the real AdMob unit
  // IDs provided by the user.
  static const String _androidHomeBannerUnitId =
      'ca-app-pub-2315837443386911/7272311937';
  static const String _androidSwipeSponsoredUnitId =
      'ca-app-pub-2315837443386911/2279151341';
  static Future<InitializationStatus>? _initializationFuture;

  static bool get isSupportedPlatform => !kIsWeb && Platform.isAndroid;

  static Future<InitializationStatus?> ensureInitialized() async {
    if (!isSupportedPlatform) return Future<InitializationStatus?>.value(null);
    return _initializationFuture ??= MobileAds.instance.initialize();
  }

  static bool isPlacementEnabled(PicmeAdPlacement placement) {
    if (!isSupportedPlatform) return false;
    switch (placement) {
      case PicmeAdPlacement.homeBanner:
        return _androidHomeBannerUnitId.isNotEmpty;
      case PicmeAdPlacement.swipeSponsoredCard:
        return _androidSwipeSponsoredUnitId.isNotEmpty;
    }
  }

  static String bannerUnitId(PicmeAdPlacement placement) {
    if (!isSupportedPlatform) {
      throw UnsupportedError('AdMob is only enabled on Android in Picme.');
    }
    switch (placement) {
      case PicmeAdPlacement.homeBanner:
        return _androidHomeBannerUnitId;
      case PicmeAdPlacement.swipeSponsoredCard:
        return _androidSwipeSponsoredUnitId;
    }
  }

  static AdSize bannerSize(PicmeAdPlacement placement) {
    switch (placement) {
      case PicmeAdPlacement.homeBanner:
        return AdSize.banner;
      case PicmeAdPlacement.swipeSponsoredCard:
        return AdSize.mediumRectangle;
    }
  }

  static Duration loadDelay(PicmeAdPlacement placement) {
    switch (placement) {
      case PicmeAdPlacement.homeBanner:
        return const Duration(milliseconds: 650);
      case PicmeAdPlacement.swipeSponsoredCard:
        return const Duration(milliseconds: 250);
    }
  }
}
