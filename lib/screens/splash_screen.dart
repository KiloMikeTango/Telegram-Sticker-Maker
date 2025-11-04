import 'package:flutter/material.dart';
import 'package:sticker_maker/screens/sticker_maker_screen.dart';

// --- TELEGRAM COLORS ---
const Color telegramBlue = Color(0xFF50A7EA);
const Color telegramGrey = Color(0xFFF0F0F0);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 5), () {});
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const StickerMakerScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'lib/assets/images/icon.png',
              width: MediaQuery.of(context).size.width * 0.4,
              height: MediaQuery.of(context).size.height * 0.2,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 30),

            // --- App Title ---
            const Text(
              'Telegram Sticker Maker',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15), // Spacing below title
            // --- Developer Info ---
            const Text(
              'Dev - @Kilo532',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 18,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
