import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:picme/l10n/app_localizations.dart';
import 'package:picme/src/app/app_locale_controller.dart';
import 'package:picme/src/app/root_gate.dart';

class PicmeApp extends StatelessWidget {
  const PicmeApp({super.key});

  @override
  Widget build(BuildContext context) {
    const baseBg = Color(0xFFF7F2F2);
    const coral = Color(0xFFE07A5F);
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: coral,
          brightness: Brightness.light,
        ).copyWith(
          surface: Colors.transparent,
          surfaceContainerHighest: Colors.white.withValues(alpha: 0.78),
          primary: const Color(0xFF1F1F1F),
          onPrimary: Colors.white,
          secondary: coral,
        );

    return ValueListenableBuilder<Locale?>(
      valueListenable: AppLocaleController.locale,
      builder: (context, selectedLocale, _) {
        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          locale: selectedLocale,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            colorScheme: colorScheme,
            scaffoldBackgroundColor: baseBg,
            canvasColor: baseBg,
            useMaterial3: true,
            fontFamily: 'Inter',
            snackBarTheme: const SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
            ),
            chipTheme: ChipThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              side: BorderSide.none,
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              color: Colors.white.withValues(alpha: 0.78),
              surfaceTintColor: Colors.transparent,
              margin: EdgeInsets.zero,
            ),
            listTileTheme: const ListTileThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
            dividerColor: const Color(0x14000000),
            scrollbarTheme: const ScrollbarThemeData(
              thumbVisibility: WidgetStatePropertyAll(false),
            ),
          ),
          builder: (context, child) {
            final page = child ?? const SizedBox.shrink();
            return DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.72, -0.32),
                  radius: 1.25,
                  colors: [
                    Color(0xFFDFC0C6),
                    Color(0xFFF1DDDA),
                    Color(0xFFF7F2F2),
                  ],
                  stops: [0.0, 0.48, 1.0],
                ),
              ),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x11FFFFFF),
                      Color(0x22E9D0D0),
                      Color(0x08FFFFFF),
                    ],
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
                child: page,
              ),
            );
          },
          home: const RootGate(),
        );
      },
    );
  }
}
