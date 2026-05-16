import 'package:flutter/material.dart';

// reusable widget for onboarding / intro screens
Widget buildImageContainer(
  Color color,
  String title,
  String subtitle,
  String imagePath,
) {
  return SizedBox(
    width: double.infinity,

    // color: const Color.fromARGB(255, 10, 3, 97),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: 300, child: Image.asset(imagePath, fit: BoxFit.cover)),
        const SizedBox(height: 65),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.deepPurple,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}
