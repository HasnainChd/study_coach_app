import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../bloc/subjects_bloc.dart';
import 'subject_detail_page.dart';

class SubjectManagerPage extends StatelessWidget {
  const SubjectManagerPage({super.key});

  void _showAddSubjectBottomSheet(BuildContext context, bool isDark) {
    final nameController = TextEditingController();
    int selectedColorIndex = 0;
    DateTime? selectedDate;
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (stateContext, setModalState) {
            return SafeArea(
              child: Padding(
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
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
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
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Subject Name Input
                      TextField(
                        controller: nameController,
                        style: TextStyle(
                          color:
                              isDark ? Colors.white : AppColors.lightTextPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter subject name...',
                          errorText: errorMessage,
                          errorStyle: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.bold,
                          ),
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
                                          color: isDark
                                              ? Colors.white
                                              : AppColors.lightTextPrimary,
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
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setModalState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkBgStart
                                : AppColors.lightBgStart,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Exam Date',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                selectedDate == null
                                    ? 'Select Date'
                                    : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
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
                          if (name.isEmpty) {
                            setModalState(() {
                              errorMessage = 'Subject name cannot be empty';
                            });
                            return;
                          }
                          if (name.length > 40) {
                            setModalState(() {
                              errorMessage = 'Subject name cannot exceed 40 characters';
                            });
                            return;
                          }
                          
                          final currentSubjects = context.read<SubjectsBloc>().state.subjects;
                          final exists = currentSubjects.any(
                            (s) => s.name.toLowerCase() == name.toLowerCase()
                          );
                          if (exists) {
                            setModalState(() {
                              errorMessage = 'Subject with this name already exists';
                            });
                            return;
                          }

                          // Clear error and add
                          setModalState(() {
                            errorMessage = null;
                          });

                          context.read<SubjectsBloc>().add(
                                AddSubjectEvent(
                                  name: name,
                                  color: AppColors.getSubjectColorByIndex(
                                      selectedColorIndex),
                                  examDate: selectedDate,
                                ),
                              );
                          AppSnackbar.show(
                            context,
                            type: SnackbarType.info,
                            title: 'Subject Added',
                            message: 'Regenerate plan to include $name in your schedule.',
                          );
                          Navigator.pop(modalContext);
                        },
                      ),
                    ],
                  ),
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
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC'
    ];
    return 'EXAM: ${months[date.month - 1]} ${date.day}';
  }

  Widget _buildExamDateChip(Subject subject, bool isDark) {
    final examDate = subject.examDate;
    final Color chipColor;
    final String text;

    if (examDate == null) {
      chipColor = const Color(0xFF555577);
      text = 'No exam set';
    } else {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final exam = DateTime(
        examDate.year, 
        examDate.month, 
        examDate.day
      );
      final days = exam.difference(today).inDays;

      if (days < 0) {
        chipColor = const Color(0xFFFF4D6A);
        text = 'EXAM PASSED';
      } else if (days == 0) {
        chipColor = const Color(0xFFFF4D6A);
        text = 'EXAM TODAY!';
      } else if (days <= 7) {
        chipColor = const Color(0xFFFF4D6A);
        text = 'EXAM IN $days DAYS';
      } else if (days <= 14) {
        chipColor = const Color(0xFFFF8C42);
        text = _formatMonthDay(examDate);
      } else {
        chipColor = const Color(0xFF555577);
        text = _formatMonthDay(examDate);
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDismissibleBackground() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20.0),
      child: const Icon(
        Icons.delete_outline_rounded,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.book_rounded,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No subjects yet',
              style: AppTextStyles.headingSmall.copyWith(
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add subjects to start organizing and generating your study plan.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => _showAddSubjectBottomSheet(context, isDark),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1.5,
                  ),
                  color: isDark
                      ? AppColors.darkCardBg.withValues(alpha: 0.4)
                      : AppColors.lightCardBg.withValues(alpha: 0.4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add New Subject',
                      style: AppTextStyles.buttonText.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
              padding:
                  const EdgeInsets.only(left: 24.0, right: 24.0, top: 12.0),
              child: Text(
                'Subjects',
                style: AppTextStyles.headingMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: BlocBuilder<SubjectsBloc, SubjectsState>(
                builder: (context, state) {
                  if (state.subjects.isEmpty) {
                    return _buildEmptyState(context, isDark);
                  }
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
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                  width: 1.5,
                                  style: BorderStyle.solid,
                                ),
                                color: isDark
                                    ? AppColors.darkCardBg.withValues(alpha: 0.4)
                                    : AppColors.lightCardBg.withValues(alpha: 0.4),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_rounded,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Add New Subject',
                                    style: AppTextStyles.buttonText.copyWith(
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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
                        child: Dismissible(
                          key: Key(subject.id),
                          direction: DismissDirection.endToStart,
                          background: Container(),
                          secondaryBackground: _buildDismissibleBackground(),
                          onDismissed: (direction) {
                            final deletedName = subject.name;
                            context.read<SubjectsBloc>().add(RemoveSubjectEvent(subject.id));
                            AppSnackbar.show(
                              context,
                              type: SnackbarType.warning,
                              title: 'Subject Removed',
                              message: '$deletedName and its tasks have been removed.',
                              onUndo: () {
                                context.read<SubjectsBloc>().add(UndoRemoveSubjectEvent());
                              },
                            );
                          },
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SubjectDetailPage(subjectId: subject.id),
                                ),
                              );
                            },
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
                                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.only(right: 16.0),
                                                    child: Icon(
                                                      Icons.chevron_right_rounded,
                                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                                      size: 20,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              _buildExamDateChip(subject, isDark),
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
                                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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
