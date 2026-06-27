import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final List<BoxShadow>? customShadows;
  final Color? customBgColor;
  final Color? customBorderColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20.0,
    this.customShadows,
    this.customBgColor,
    this.customBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = customBgColor ?? (isDark ? AppColors.darkCardBg : AppColors.lightCardBg);
    final borderColor = customBorderColor ?? (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor,
          width: 1.2,
        ),
        boxShadow: customShadows ??
            [
              if (isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              else
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
            ],
      ),
      child: child,
    );
  }
}
