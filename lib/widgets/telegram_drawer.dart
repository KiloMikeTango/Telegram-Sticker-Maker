import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';

Drawer buildTelegramDrawer(BuildContext context, Future<void> Function(String) launchUrlFunc) {
  const String TELEGRAM_USERNAME = 'Kilo532';
  final String telegramUrl = 'https://t.me/$TELEGRAM_USERNAME';

  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        DrawerHeader(
          decoration: const BoxDecoration(color: telegramBlue),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: const <Widget>[
              Center(
                child: CircleAvatar(
                  radius: 33,
                  backgroundImage: AssetImage('lib/assets/images/pfp.jpg'),
                ),
              ),
              SizedBox(height: 8.0),
              Center(
                child: Text(
                  '@$TELEGRAM_USERNAME',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 4.0),
              Center(
                child: Text(
                  'Telegram Sticker Maker',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.send, color: telegramBlue),
          title: const Text('Contact Me (Telegram)'),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () {
            Navigator.pop(context);
            launchUrlFunc(telegramUrl);
          },
        ),
      ],
    ),
  );
}
