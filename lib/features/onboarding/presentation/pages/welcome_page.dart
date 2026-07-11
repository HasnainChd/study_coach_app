import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../bloc/navigation_bloc.dart';
import '../../../home/presentation/pages/home_dashboard_page.dart';

class WelcomePage extends StatelessWidget {
  WelcomePage({super.key});

  final _formKey = GlobalKey<FormState>();
  static final _nameController = TextEditingController();

  Future<void> _handleGetStarted(BuildContext context) async {
    if (_formKey.currentState?.validate() ?? false) {
      final name = _nameController.text.trim();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', name);
      HomeDashboardPage.userNameNotifier.value = name;

      if (context.mounted) {
        context.read<NavigationBloc>().add(
              NavigateToScreenEvent(AppScreen.addSubjects),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: GradientBackground(
        child: Stack(
          children: [
            // Centered main content
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Form(
                          key: _formKey,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Step Indicator
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                                  child: Row(
                                    children: [
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
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
                                          'Step 1 of 3',
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
                                const Spacer(),
                                // Circular glowing book icon
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDark
                                        ? AppColors.primary.withValues(alpha: 0.8)
                                        : AppColors.primary,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.4),
                                        blurRadius: 24,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.menu_book_rounded,
                                      color: Colors.white,
                                      size: 36,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                // Title
                                Text(
                                  'StudyCoach AI',
                                  style: AppTextStyles.headingLarge.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                // Subtitle
                                Text(
                                  'Your AI-powered path to\nacademic excellence',
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 32),

                                // Name Input Field
                                TextFormField(
                                  controller: _nameController,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your name';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Enter your name',
                                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                    filled: true,
                                    fillColor: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                        width: 1.5,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: AppColors.primary,
                                        width: 1.5,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: AppColors.subjectPink,
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: AppColors.subjectPink,
                                        width: 1.5,
                                      ),
                                    ),
                                    errorStyle: const TextStyle(
                                      color: AppColors.subjectPink,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const Spacer(flex: 2),
                                const SizedBox(height: 120), // bottom button placeholder
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Pinned Get Started Button
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0),
                  child: PrimaryButton(
                    text: 'Get Started',
                    onPressed: () => _handleGetStarted(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
