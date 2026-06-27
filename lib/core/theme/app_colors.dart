import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF8F67F6);
  static const Color primaryLight = Color(0xFFAC8EFF);
  static const Color primaryDark = Color(0xFF6F43DC);

  // Dark Theme Background Gradient Colors
  static const Color darkBgStart = Color(0xFF0A0915);
  static const Color darkBgEnd = Color(0xFF16152B);
  static const Color darkCardBg = Color(0xFF131227);
  static const Color darkBorder = Color(0xFF222042);
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFF8E8D9B);

  // Light Theme Colors
  static const Color lightBgStart = Color(0xFFF7F8FC);
  static const Color lightBgEnd = Color(0xFFFFFFFF);
  static const Color lightCardBg = Colors.white;
  static const Color lightBorder = Color(0xFFE5E5F2);
  static const Color lightTextPrimary = Color(0xFF131227);
  static const Color lightTextSecondary = Color(0xFF6D6B83);

  // Accent Colors for Subjects
  static const Color subjectGreen = Color(0xFF00D180);
  static const Color subjectPurple = Color(0xFF805CFF);
  static const Color subjectOrange = Color(0xFFFD853A);
  static const Color subjectPink = Color(0xFFFD4C6B);
  static const Color subjectBlue = Color(0xFF2A85FF);
  static const Color subjectYellow = Color(0xFFFFD043);

  // List of subject colors for selection
  static const List<Color> subjectColors = [
    subjectGreen,
    subjectPurple,
    subjectOrange,
    subjectPink,
    subjectBlue,
    subjectYellow,
  ];

  static Color getSubjectColorByIndex(int index) {
    return subjectColors[index % subjectColors.length];
  }
}
