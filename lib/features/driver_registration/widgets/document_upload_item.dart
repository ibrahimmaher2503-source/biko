import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Document upload row — icon, name, hint text, and status indicator
/// (dashed circle with add for pending, green check for uploaded)
class DocumentUploadItem extends StatelessWidget {
  const DocumentUploadItem({
    required this.icon,
    required this.name,
    required this.hint,
    required this.isUploaded,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String name;
  final String hint;
  final bool isUploaded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ext.surfaceContainer,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: ext.borderSubtle),
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ext.surfaceElevated,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(icon, color: AppTheme.primary, size: 24),
              ),
              const SizedBox(width: 16),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hint,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: ext.textMuted),
                    ),
                  ],
                ),
              ),
              // Status indicator
              if (isUploaded)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: ext.successBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, color: ext.success, size: 16),
                )
              else
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ext.border, width: 2),
                  ),
                  child: Icon(Icons.add, size: 14, color: ext.textMuted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
