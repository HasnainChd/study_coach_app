import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class GradeHintBanner extends StatefulWidget {
  final String? gradeLevel;
  final VoidCallback onTapSetGrade;
  final bool isDark;

  const GradeHintBanner({
    super.key,
    required this.gradeLevel,
    required this.onTapSetGrade,
    required this.isDark,
  });

  @override
  State<GradeHintBanner> createState() => _GradeHintBannerState();
}

class _GradeHintBannerState extends State<GradeHintBanner> {
  bool _dismissed = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkDismissedStatus();
  }

  Future<void> _checkDismissedStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _dismissed = prefs.getBool('grade_hint_dismissed') ?? false;
        _loading = false;
      });
    }
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('grade_hint_dismissed', true);
    if (mounted) {
      setState(() {
        _dismissed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _dismissed || widget.gradeLevel != null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: widget.isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: widget.isDark ? 0.35 : 0.25),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.school_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set Your Grade Level',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: widget.isDark ? Colors.white : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Select your grade in Settings to get study tasks matched to your level.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: widget.isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: widget.onTapSetGrade,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: Text(
                      'Set Grade →',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _dismiss,
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                color: widget.isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
