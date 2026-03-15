import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Floating search bar that navigates to destination search on tap.
///
/// This is NOT an actual text input — it's a tappable container
/// that looks like a search bar.
class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ext.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ext.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Search icon container
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.search,
                color: AppTheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Placeholder text
            Expanded(
              child: Text(
                'home.search_placeholder'.tr,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: ext.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
