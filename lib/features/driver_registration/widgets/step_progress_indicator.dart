import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// 4-step horizontal progress bar — active step is wider and fully colored,
/// inactive steps are transparent primary
class StepProgressIndicator extends StatelessWidget {
  const StepProgressIndicator({
    required this.currentStep,
    super.key,
    this.totalSteps = 4,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final isActive = index == currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: isActive ? 32 : 32,
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.primary
                : AppTheme.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppTheme.radiusDefault / 2),
          ),
        );
      }),
    );
  }
}
