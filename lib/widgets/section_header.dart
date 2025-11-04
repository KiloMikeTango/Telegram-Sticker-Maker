import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

Widget buildSectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.only(left: 16.0, top: 20.0, bottom: 8.0),
    child: Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: telegramBlue,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    ),
  );
}
