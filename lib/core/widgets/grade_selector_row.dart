import 'package:flutter/material.dart';
import '../constants/grade_bands.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class GradeSelectorRow extends StatelessWidget {
  final String? selectedGrade;
  final ValueChanged<String?> onGradeSelected;
  final bool isDark;

  const GradeSelectorRow({
    super.key,
    required this.selectedGrade,
    required this.onGradeSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: kGradeOptions.map((grade) {
          final isSelected = selectedGrade == grade;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () {
                if (isSelected) {
                  onGradeSelected(null); // Deselect (skippable)
                } else {
                  onGradeSelected(grade);
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [
                            AppColors.primary,
                            Color(0xFF805CFF),
                          ],
                        )
                      : null,
                  color: isSelected
                      ? null
                      : (isDark
                          ? AppColors.darkCardBg
                          : AppColors.lightCardBg),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      grade,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary),
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
