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

  // Helper/Utility Colors for modals, buttons, and tests
  static const Color darkOverlayBg = Color(0xFF1E1C38);
  static const Color testButtonBgDark = Colors.white;
  static const Color testButtonBgLight = Colors.black;
  static const Color textRed = Color(0xFFFF3B30); // iOS style red for alert/debug actions

  // Snackbar specific colors
  static const Color snackbarBg = Color(0xFF1C1C35);
  static const Color snackbarSuccess = Color(0xFF00D68F);
  static const Color snackbarError = Color(0xFFFF4D6A);
  static const Color snackbarWarning = Color(0xFFFF8C42);
  static const Color snackbarInfo = Color(0xFF7C5CFC);
  static const Color snackbarSubtitle = Color(0xFF9999BB);

  static Color getSubjectColorByIndex(int index) {
    return subjectColors[index % subjectColors.length];
  }
}
