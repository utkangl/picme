import 'package:flutter/material.dart';
import 'package:picme/src/features/home/presentation/home_screen.dart';

class PicmeApp extends StatelessWidget {
  const PicmeApp({super.key});

  @override
  Widget build(BuildContext context) {
    const baseBg = Color(0xFFF7F2F2);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.black,
      brightness: Brightness.light,
    ).copyWith(surface: baseBg);

    return MaterialApp(
      title: 'Picme',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: baseBg,
        canvasColor: baseBg,
        useMaterial3: true,
        fontFamily: 'Inter',
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      builder: (context, child) {
        final page = child ?? const SizedBox.shrink();
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.72, -0.32),
              radius: 1.25,
              colors: [Color(0xFFDFC0C6), Color(0xFFF1DDDA), Color(0xFFF7F2F2)],
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
      home: const HomeScreen(),
    );
  }
}
