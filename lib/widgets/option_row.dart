import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

Widget buildOptionRow({
  required String title,
  required bool isSelected,
  required ValueChanged<bool?> onChanged,
}) {
  return Container(
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16)),
        Switch.adaptive(
          value: isSelected,
          onChanged: onChanged,
          activeColor: telegramBlue,
        ),
      ],
    ),
  );
}
