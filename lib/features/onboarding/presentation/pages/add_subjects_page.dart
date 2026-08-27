import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../bloc/navigation_bloc.dart';
import '../../../subjects/domain/entities/subject.dart';
import '../../../subjects/presentation/bloc/subjects_bloc.dart';
import '../../../subjects/presentation/bloc/subjects_event.dart';
import '../../../subjects/presentation/bloc/subjects_state.dart';

class AddSubjectsPage extends StatefulWidget {
  const AddSubjectsPage({super.key});

  @override
  State<AddSubjectsPage> createState() => _AddSubjectsPageState();
}

class _AddSubjectsPageState extends State<AddSubjectsPage> {
  static const List<String> _presetSubjects = [
    'Math',
    'Science',
    'English',
    'History',
    'Biology',
    'Chemistry',
    'Computer Science',
  ];

  Color _getUniqueSubjectColor(List<Subject> currentSubjects, int defaultIndex) {
    final usedColors = currentSubjects.map((s) => s.color.value).toSet();
    for (final color in AppColors.subjectColors) {
      if (!usedColors.contains(color.value)) {
        return color;
      }
    }
    return AppColors.getSubjectColorByIndex(defaultIndex);
  }

  final TextEditingController _nameController = TextEditingController();
  int _selectedColorIndex = 1; // Default select purple (index 1)
  DateTime? _selectedDate;
  String? _nameError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return Theme(
          data: theme.copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: AppColors.darkCardBg,
                    onSurface: AppColors.darkTextPrimary,
                  )
                : const ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: AppColors.lightTextPrimary,
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _addSubject() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _nameError = 'Subject name cannot be empty';
      });
      return;
    }
    if (name.length > 40) {
      setState(() {
        _nameError = 'Subject name cannot exceed 40 characters';
      });
      return;
    }

    final subjects = context.read<SubjectsBloc>().state.subjects;
    if (subjects.any((s) => s.name.toLowerCase() == name.toLowerCase())) {
      setState(() {
        _nameError = 'Subject already added';
      });
      return;
    }

    setState(() {
      _nameError = null;
    });

    final color = AppColors.getSubjectColorByIndex(_selectedColorIndex);
    context.read<SubjectsBloc>().add(
          AddSubjectEvent(name: name, color: color, examDate: _selectedDate),
        );
    AppSnackbar.show(
      context,
      type: SnackbarType.success,
      title: 'Subject Added',
      message: '$name has been added to your plan.',
    );
    _nameController.clear();
    setState(() {
      _selectedDate = null;
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: BlocListener<SubjectsBloc, SubjectsState>(
        listener: (context, state) {
          if (state.status == SubjectsStatus.failure && state.errorMessage != null) {
            AppSnackbar.show(
              context,
              type: SnackbarType.error,
              title: 'Error',
              message: state.errorMessage!,
            );
          }
        },
        child: GradientBackground(
          child: Column(
            children: [
              // Header with back button & Step indicator
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      ),
                      onPressed: () {
                        context.read<NavigationBloc>().add(
                              NavigateToScreenEvent(AppScreen.welcome),
                            );
                      },
                    ),
                    const Spacer(),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Step 2 of 3',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.primaryLight
                              : AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Title section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Your\nSubjects',
                        style: AppTextStyles.headingMedium.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'What subjects are you studying?',
                        style: AppTextStyles.bodyMedium.copyWith(
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
              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Add Presets Section
                      Text(
                        'QUICK ADD PRESETS',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      BlocBuilder<SubjectsBloc, SubjectsState>(
                        builder: (context, state) {
                          final existingNames = state.subjects
                              .map((s) => s.name.trim().toLowerCase())
                              .toSet();

                          return Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: _presetSubjects.map((presetName) {
                              final isAdded = existingNames
                                  .contains(presetName.toLowerCase());
                              final presetIndex =
                                  _presetSubjects.indexOf(presetName);
                              final chipColor = _getUniqueSubjectColor(
                                  state.subjects, presetIndex);

                              return InkWell(
                                onTap: isAdded
                                    ? null
                                    : () {
                                        context.read<SubjectsBloc>().add(
                                              AddSubjectEvent(
                                                name: presetName,
                                                color: chipColor,
                                              ),
                                            );
                                        AppSnackbar.show(
                                          context,
                                          type: SnackbarType.success,
                                          title: 'Subject Added',
                                          message:
                                              '$presetName has been added to your plan.',
                                        );
                                      },
                                borderRadius: BorderRadius.circular(20),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isAdded
                                        ? (isDark
                                            ? Colors.white.withValues(alpha: 0.06)
                                            : Colors.black.withValues(alpha: 0.05))
                                        : (isDark
                                            ? AppColors.darkCardBg
                                            : AppColors.lightCardBg),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isAdded
                                          ? (isDark
                                              ? AppColors.darkBorder
                                              : AppColors.lightBorder)
                                          : chipColor.withValues(alpha: 0.7),
                                      width: isAdded ? 1.0 : 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: isAdded
                                              ? (isDark
                                                  ? Colors.grey
                                                  : Colors.grey.shade400)
                                              : chipColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        presetName,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isAdded
                                              ? FontWeight.w400
                                              : FontWeight.w600,
                                          color: isAdded
                                              ? (isDark
                                                  ? AppColors.darkTextSecondary
                                                  : AppColors.lightTextSecondary)
                                              : (isDark
                                                  ? AppColors.darkTextPrimary
                                                  : AppColors.lightTextPrimary),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        isAdded
                                            ? Icons.check_rounded
                                            : Icons.add_rounded,
                                        size: 14,
                                        color: isAdded
                                            ? AppColors.subjectGreen
                                            : (isDark
                                                ? AppColors.primaryLight
                                                : AppColors.primary),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'OR CUSTOM SUBJECT',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Input Card
                      GlassCard(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _nameController,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : AppColors.lightTextPrimary,
                                fontSize: 16,
                              ),
                              onChanged: (value) {
                                if (_nameError != null) {
                                  final name = value.trim();
                                  if (name.isNotEmpty && name.length <= 40) {
                                    final subjects =
                                        context.read<SubjectsBloc>().state.subjects;
                                    if (!subjects.any((s) =>
                                        s.name.toLowerCase() ==
                                        name.toLowerCase())) {
                                      setState(() {
                                        _nameError = null;
                                      });
                                    }
                                  }
                                }
                              },
                              decoration: InputDecoration(
                                hintText: 'Subject name...',
                                hintStyle: TextStyle(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                                fillColor: Colors.transparent,
                                filled: true,
                                contentPadding: EdgeInsets.zero,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                            ),
                            if (_nameError != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: AppColors.subjectPink,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _nameError!,
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.subjectPink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),
                            // Color Selector Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(
                                AppColors.subjectColors.length,
                                (index) {
                                  final color = AppColors.subjectColors[index];
                                  final isSelected = _selectedColorIndex == index;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedColorIndex = index;
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Exam Date Selection Card
                      GestureDetector(
                        onTap: _pickDate,
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Exam Date',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _selectedDate == null
                                    ? 'Select date'
                                    : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Add Subject Button
                      SecondaryButton(
                        text: 'Add Subject',
                        onPressed: _addSubject,
                      ),
                      const SizedBox(height: 24),
                      // ADDED list section
                      BlocBuilder<SubjectsBloc, SubjectsState>(
                        builder: (context, state) {
                          final subjects = state.subjects;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ADDED (${subjects.length})',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: subjects.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final subject = subjects[index];
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.darkCardBg
                                          : AppColors.lightCardBg,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark
                                            ? AppColors.darkBorder
                                            : AppColors.lightBorder,
                                        width: 1.2,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: IntrinsicHeight(
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 5,
                                              color: subject.color,
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 16.0),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      subject.name,
                                                      style: AppTextStyles.bodyLarge
                                                          .copyWith(
                                                        color: isDark
                                                            ? AppColors
                                                                .darkTextPrimary
                                                            : AppColors
                                                                .lightTextPrimary,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    if (subject.examDate != null) ...[
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'Exam: ${subject.examDate!.day}/${subject.examDate!.month}/${subject.examDate!.year}',
                                                        style: AppTextStyles.bodySmall.copyWith(
                                                          color: isDark
                                                              ? AppColors.darkTextSecondary
                                                              : AppColors.lightTextSecondary,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.delete_outline_rounded,
                                                color: isDark
                                                    ? AppColors.darkTextSecondary
                                                    : AppColors
                                                        .lightTextSecondary,
                                              ),
                                              onPressed: () {
                                                context.read<SubjectsBloc>().add(
                                                      RemoveSubjectEvent(
                                                          subject.id),
                                                    );
                                                AppSnackbar.show(
                                                  context,
                                                  type: SnackbarType.warning,
                                                  title: 'Subject Removed',
                                                  message: 'Subject has been removed.',
                                                );
                                              },
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              // Bottom Continue Button
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: BlocBuilder<SubjectsBloc, SubjectsState>(
                  builder: (context, state) {
                    return PrimaryButton(
                      text: 'Continue',
                      onPressed: () {
                        if (state.subjects.isEmpty) {
                          AppSnackbar.show(
                            context,
                            type: SnackbarType.error,
                            title: 'No Subjects Added',
                            message: 'Please add at least one subject before generating your plan.',
                          );
                          return;
                        }
                        context.read<NavigationBloc>().add(
                              NavigateToScreenEvent(AppScreen.dailySchedule),
                            );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
