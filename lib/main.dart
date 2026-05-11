import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:picme/src/app/app_locale_controller.dart';
import 'package:picme/src/app/picme_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLocaleController.load();
  // For the Play Store app we rely on the native Android Firebase config
  // (`android/app/google-services.json`) instead of committing generated
  // FlutterFire option files with client API keys into the repo.
  await Firebase.initializeApp();

  // Forward Flutter framework errors to Crashlytics.
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Forward Dart async errors (e.g. isolate errors) to Crashlytics.
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(const PicmeApp());
}
