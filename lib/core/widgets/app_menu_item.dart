import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Reusable menu item with tinted icon container and bordered layout.
///
/// Used across profile, settings, and other feature screens.
class AppMenuItem extends StatelessWidget {
  const AppMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
    this.subtitle,
    this.iconColor,
    this.showDivider = true,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? iconColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = Theme.of(context).extension<AppColorsExtension>()!;
    final color = iconColor ?? AppTheme.primary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  // Tinted icon container
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusLarge,
                      ),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  // Title + subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: ext.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Trailing widget or chevron (flips for RTL)
                  trailing ??
                      Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.chevron_left_rounded
                            : Icons.chevron_right_rounded,
                        color: ext.textMuted,
                        size: 22,
                      ),
                ],
              ),
            ),
            if (showDivider)
              Divider(color: ext.borderSubtle, height: 1, indent: 58),
          ],
        ),
      ),
    );
  }
}
