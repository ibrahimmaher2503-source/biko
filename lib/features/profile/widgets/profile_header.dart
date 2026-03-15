import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:flutter/material.dart';

/// Profile header with large avatar, camera badge, name, and phone
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    required this.name,
    required this.phone,
    this.avatarUrl,
    this.onAvatarTap,
    this.isUploading = false,
    super.key,
  });

  final String name;
  final String phone;
  final String? avatarUrl;
  final VoidCallback? onAvatarTap;
  final bool isUploading;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: ext.surfaceElevated,
        border: Border(bottom: BorderSide(color: ext.borderSubtle)),
      ),
      child: Column(
        children: [
          // Avatar with ring border and camera badge
          Stack(
            children: [
              GestureDetector(
                onTap: onAvatarTap,
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 49,
                    backgroundImage: avatarUrl != null
                        ? NetworkImage(avatarUrl!)
                        : null,
                    backgroundColor: ext.surfaceContainer,
                    child: isUploading
                        ? const AppLoading()
                        : avatarUrl == null
                            ? Icon(
                                Icons.person,
                                size: 48,
                                color: ext.textMuted,
                              )
                            : null,
                  ),
                ),
              ),
              // Camera badge
              PositionedDirectional(
                bottom: 2,
                end: 2,
                child: GestureDetector(
                  onTap: onAvatarTap,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            phone,
            style: theme.textTheme.bodyMedium?.copyWith(color: ext.textMuted),
            textDirection: TextDirection.ltr,
          ),
        ],
      ),
    );
  }
}
