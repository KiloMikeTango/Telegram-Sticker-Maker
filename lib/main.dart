import 'package:flutter/material.dart';
import 'package:sticker_maker/theme/app_theme.dart';
import 'package:sticker_maker/screens/splash_screen.dart';

void main() => runApp(const StickerMakerApp());

class StickerMakerApp extends StatelessWidget {
  const StickerMakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Telegram Sticker Maker',
      theme: AppTheme.themeData,
      home: const SplashScreen(),
    );
  }
}
