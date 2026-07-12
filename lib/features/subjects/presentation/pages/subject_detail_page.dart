import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../bloc/navigation_bloc.dart';
import '../../../bloc/timer_bloc.dart';
import '../../../bloc/subjects_bloc.dart';

class SubjectDetailPage extends StatelessWidget {
  final String subjectId;

  const SubjectDetailPage({
    super.key,
    required this.subjectId,
  });

  String _formatMonthDay(DateTime date) {
    const months = [
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

  void _showDeleteConfirmation(BuildContext context, Subject subject, bool isDark) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delete Subject?',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'This will permanently delete "${subject.name}" and all of today\'s generated tasks for it.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      ),
                      onPressed: () {
                        // 1. Pop Dialog
                        Navigator.pop(dialogContext);
                        
                        // 2. Fire deletion event
                        context.read<SubjectsBloc>().add(RemoveSubjectEvent(subject.id));
                        
                        // 3. Pop Detail Page
                        Navigator.pop(context);
                        
                        // 4. Show warning snackbar with undo option
                        AppSnackbar.show(
                          context,
                          type: SnackbarType.warning,
                          title: 'Subject Removed',
                          message: '${subject.name} and its tasks have been removed.',
                          onUndo: () {
                            context.read<SubjectsBloc>().add(UndoRemoveSubjectEvent());
                          },
                        );
                      },
                      child: const Text(
                        'Delete',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditSubjectBottomSheet(BuildContext context, Subject subject, bool isDark) {
    final nameController = TextEditingController(text: subject.name);
    int selectedColorIndex = AppColors.subjectColors.indexOf(subject.color);
    if (selectedColorIndex == -1) selectedColorIndex = 0;
    
    DateTime? selectedDate = subject.examDate;
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
                        'Edit Subject',
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
                            initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
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
                      // Save Subject Button
                      SecondaryButton(
                        text: 'Save Changes',
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
                            (s) => s.id != subject.id && s.name.toLowerCase() == name.toLowerCase()
                          );
                          if (exists) {
                            setModalState(() {
                              errorMessage = 'Subject with this name already exists';
                            });
                            return;
                          }

                          // Clear error
                          setModalState(() {
                            errorMessage = null;
                          });

                          context.read<SubjectsBloc>().add(
                                UpdateSubjectEvent(
                                  id: subject.id,
                                  name: name,
                                  color: AppColors.getSubjectColorByIndex(selectedColorIndex),
                                  examDate: selectedDate,
                                ),
                              );
                              
                          AppSnackbar.show(
                            context,
                            type: SnackbarType.success,
                            title: 'Subject Updated',
                            message: '$name has been updated successfully.',
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<SubjectsBloc, SubjectsState>(
      builder: (context, state) {
        // Find subject in state
        final subjectIndex = state.subjects.indexWhere((s) => s.id == subjectId);
        if (subjectIndex == -1) {
          return Scaffold(
            appBar: AppBar(title: const Text('Subject Details')),
            body: const Center(child: Text('Subject not found')),
          );
        }

        final subject = state.subjects[subjectIndex];

        // Filter agenda items for this subject tag
        final subjectTasks = state.agendaItems.where(
          (item) => item.tag.toLowerCase() == subject.name.toLowerCase()
        ).toList();

        final completedCount = subjectTasks.where((t) => t.isCompleted).length;
        final totalCount = subjectTasks.length;

        return Scaffold(
          body: GradientBackground(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Bar Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: isDark ? Colors.white : AppColors.lightTextPrimary,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          subject.name,
                          style: AppTextStyles.headingSmall.copyWith(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.edit_rounded,
                            color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                            size: 22,
                          ),
                          onPressed: () => _showEditSubjectBottomSheet(context, subject, isDark),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Overview Progress Card
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                  width: 1.2,
                                ),
                              ),
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: subject.color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          subject.name,
                                          style: AppTextStyles.headingMedium.copyWith(
                                            color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildExamDateChip(subject, isDark),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'TODAY\'S PROGRESS',
                                        style: AppTextStyles.labelSmall.copyWith(
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                          fontSize: 11,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      Text(
                                        '$completedCount of $totalCount completed',
                                        style: TextStyle(
                                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: subject.progress,
                                      backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                      valueColor: AlwaysStoppedAnimation<Color>(subject.color),
                                      minHeight: 8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Section Title
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Text(
                              'Today\'s Study Plan',
                              style: AppTextStyles.headingSmall.copyWith(
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Tasks list
                          subjectTasks.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                                  child: _buildNoTasksState(isDark),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                                  itemCount: subjectTasks.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final item = subjectTasks[index];
                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: item.isCompleted
                                              ? AppColors.subjectGreen.withValues(alpha: 0.4)
                                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          // Checkbox circle
                                          GestureDetector(
                                            onTap: () {
                                              context.read<SubjectsBloc>().add(
                                                ToggleAgendaItemEvent(item.id),
                                              );
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.all(16.0),
                                              child: Icon(
                                                item.isCompleted
                                                    ? Icons.check_circle_rounded
                                                    : Icons.radio_button_unchecked_rounded,
                                                color: item.isCompleted
                                                    ? AppColors.subjectGreen
                                                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                          // Title & Time Detail (interactive timer transition)
                                          Expanded(
                                            child: GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTap: item.isCompleted
                                                  ? null
                                                  : () {
                                                      context
                                                          .read<TimerBloc>()
                                                          .add(
                                                        StartTimerEvent(
                                                          taskId: item.id,
                                                          durationSeconds: item
                                                                  .durationMinutes *
                                                              60,
                                                          taskTitle: item.title,
                                                          subjectName: item.tag,
                                                          subjectColor:
                                                              item.tagColor,
                                                        ),
                                                      );
                                                      // Switch dashboard tab to Focus Timer page
                                                      context.read<NavigationBloc>().add(
                                                        NavigateToScreenEvent(AppScreen.focusTimer),
                                                      );
                                                    },
                                              child: Padding(
                                                padding: const EdgeInsets.only(top: 16.0, bottom: 16.0, right: 16.0),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            item.title,
                                                            style: AppTextStyles.bodyMedium.copyWith(
                                                              fontWeight: FontWeight.w600,
                                                              color: item.isCompleted
                                                                  ? (isDark
                                                                      ? AppColors.darkTextSecondary.withValues(alpha: 0.6)
                                                                      : AppColors.lightTextSecondary.withValues(alpha: 0.6))
                                                                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                                              decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 6),
                                                          Row(
                                                            children: [
                                                              Icon(
                                                                Icons.schedule_rounded,
                                                                size: 13,
                                                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                                              ),
                                                              const SizedBox(width: 4),
                                                              Text(
                                                                '${item.durationMinutes} min',
                                                                style: AppTextStyles.bodySmall.copyWith(
                                                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                                                  fontSize: 11,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    if (!item.isCompleted)
                                                      Icon(
                                                        Icons.play_circle_outline_rounded,
                                                        color: subject.color,
                                                        size: 24,
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),

                          // Delete Button at bottom
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFEF4444),
                                  side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () => _showDeleteConfirmation(context, subject, isDark),
                                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                                label: const Text(
                                  'Delete Subject',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
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
        );
      },
    );
  }

  Widget _buildNoTasksState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.done_all_rounded,
              color: isDark ? Colors.white30 : Colors.black26,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'All Tasks Completed!',
              style: AppTextStyles.bodyLarge.copyWith(
                color: isDark ? Colors.white70 : AppColors.lightTextPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No scheduled tasks left for today. Keep up the amazing study pace!',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
