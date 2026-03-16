import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Bottom sheet language selector widget.
///
/// Shared across profile and settings features.
/// Language names use native script — standard UX pattern.
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({
    required this.currentLang,
    required this.onLanguageChanged,
    super.key,
  });

  final String currentLang;
  final void Function(String lang) onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.borderSubtle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'profile.select_language'.tr,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          // Language names use native script (not .tr) — standard UX pattern
          _LanguageOption(
            label: 'العربية',
            subtitle: 'Arabic',
            langCode: 'ar',
            isSelected: currentLang == 'ar',
            onTap: () {
              onLanguageChanged('ar');
              Get.back<void>();
            },
          ),
          const SizedBox(height: 8),
          _LanguageOption(
            label: 'English',
            subtitle: 'الإنجليزية',
            langCode: 'en',
            isSelected: currentLang == 'en',
            onTap: () {
              onLanguageChanged('en');
              Get.back<void>();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.subtitle,
    required this.langCode,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final String langCode;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.1)
              : colors.surfaceContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: isSelected ? AppTheme.primary : colors.borderSubtle,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }
}
