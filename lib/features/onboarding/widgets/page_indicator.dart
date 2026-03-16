import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Pagination dots for onboarding — active dot is wider (w-32dp),
/// inactive dots are small circles (w-8dp)
class PageIndicator extends StatelessWidget {
  const PageIndicator({
    required this.currentPage,
    required this.pageCount,
    super.key,
  });

  final int currentPage;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: isActive ? 32 : 8,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary : colors.border,
            borderRadius: BorderRadius.circular(AppTheme.radiusDefault / 2),
          ),
        );
      }),
    );
  }
}
