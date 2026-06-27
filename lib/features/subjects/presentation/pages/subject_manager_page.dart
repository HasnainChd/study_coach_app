import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../bloc/subjects_bloc.dart';

class SubjectManagerPage extends StatelessWidget {
  const SubjectManagerPage({super.key});

  void _showAddSubjectBottomSheet(BuildContext context, bool isDark) {
    final nameController = TextEditingController();
    int selectedColorIndex = 0;
    DateTime? selectedDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (stateContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(stateContext).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardBg : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add New Subject',
                      style: AppTextStyles.headingSmall.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Subject Name Input
                    TextField(
                      controller: nameController,
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Enter subject name...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Color dots selection
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        AppColors.subjectColors.length,
                        (index) {
                          final color = AppColors.subjectColors[index];
                          final isSelected = selectedColorIndex == index;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedColorIndex = index;
                              });
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(
                                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                        width: 2.5,
                                      )
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Exam Date Select Row
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: stateContext,
                          initialDate: DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setModalState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBgStart : AppColors.lightBgStart,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Exam Date',
                              style: TextStyle(
                                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              selectedDate == null
                                  ? 'Select Date'
                                  : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                              style: TextStyle(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Create Subject Button
                    SecondaryButton(
                      text: 'Add Subject',
                      onPressed: () {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;

                        context.read<SubjectsBloc>().add(
                              AddSubjectEvent(
                                name: name,
                                color: AppColors.getSubjectColorByIndex(selectedColorIndex),
                                examDate: selectedDate,
                              ),
                            );
                        Navigator.pop(modalContext);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatMonthDay(DateTime? date) {
    if (date == null) return 'NO EXAM';
    final months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    return 'EXAM: ${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: GradientBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header title
            Padding(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 12.0),
              child: Text(
                'Subjects',
                style: AppTextStyles.headingMedium.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Subjects list
            Expanded(
              child: BlocBuilder<SubjectsBloc, SubjectsState>(
                builder: (context, state) {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    itemCount: state.subjects.length + 1, // list + bottom add button
                    itemBuilder: (context, index) {
                      if (index == state.subjects.length) {
                        // Dashed Outlined Add button
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24.0, top: 8.0),
                          child: GestureDetector(
                            onTap: () => _showAddSubjectBottomSheet(context, isDark),
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder,
                                  width: 1.5,
                                  style: BorderStyle.solid, // solid fallback for dashed style
                                ),
                                color: isDark
                                    ? AppColors.darkCardBg.withOpacity(0.4)
                                    : AppColors.lightCardBg.withOpacity(0.4),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_rounded,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Add New Subject',
                                    style: AppTextStyles.buttonText.copyWith(
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      final subject = state.subjects[index];
                      final percentProgress = (subject.progress * 100).toInt();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              width: 1.2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: IntrinsicHeight(
                              child: Row(
                                children: [
                                  // Left side color stripe
                                  Container(
                                    width: 5,
                                    color: subject.color,
                                  ),
                                  const SizedBox(width: 16),
                                  // Main content column
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 18.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Title & Chevron Row
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                subject.name,
                                                style: AppTextStyles.headingSmall.copyWith(
                                                  color: isDark
                                                      ? AppColors.darkTextPrimary
                                                      : AppColors.lightTextPrimary,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(right: 16.0),
                                                child: Icon(
                                                  Icons.chevron_right_rounded,
                                                  color: isDark
                                                      ? AppColors.darkTextSecondary
                                                      : AppColors.lightTextSecondary,
                                                  size: 20,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          // Exam Pill Tag
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? AppColors.darkBorder.withOpacity(0.6)
                                                  : AppColors.lightBorder.withOpacity(0.6),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _formatMonthDay(subject.examDate),
                                              style: TextStyle(
                                                color: isDark
                                                    ? AppColors.darkTextSecondary
                                                    : AppColors.lightTextSecondary,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          // Progress Bar Row
                                          Padding(
                                            padding: const EdgeInsets.only(right: 16.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'PROGRESS',
                                                  style: AppTextStyles.labelSmall.copyWith(
                                                    color: isDark
                                                        ? AppColors.darkTextSecondary
                                                        : AppColors.lightTextSecondary,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                                Text(
                                                  '$percentProgress%',
                                                  style: TextStyle(
                                                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          // Progress Bar
                                          Padding(
                                            padding: const EdgeInsets.only(right: 16.0),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value: subject.progress,
                                                backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                                valueColor: AlwaysStoppedAnimation<Color>(subject.color),
                                                minHeight: 5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
