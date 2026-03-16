import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Bottom card showing driver info with call/chat actions.
class DriverInfoCard extends StatelessWidget {
  const DriverInfoCard({
    required this.driverName,
    required this.vehicleType,
    required this.plateNumber,
    required this.driverRating,
    this.driverPhotoUrl,
    this.driverPhone,
    this.onChatPressed,
    super.key,
  });

  final String driverName;
  final String vehicleType;
  final String plateNumber;
  final double driverRating;
  final String? driverPhotoUrl;
  final String? driverPhone;
  final VoidCallback? onChatPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Driver avatar
            CircleAvatar(
              radius: 28,
              backgroundImage: driverPhotoUrl != null
                  ? NetworkImage(driverPhotoUrl!)
                  : null,
              backgroundColor: colors.surfaceContainer,
              child: driverPhotoUrl == null
                  ? Icon(Icons.person, color: colors.textMuted, size: 28)
                  : null,
            ),
            const SizedBox(width: 12),

            // Driver details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    driverName,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$vehicleType \u00b7 $plateNumber',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Rating stars
                  Row(
                    children: List.generate(5, (i) {
                      return Icon(
                        i < driverRating.round()
                            ? Icons.star
                            : Icons.star_border,
                        size: 14,
                        color: AppTheme.orange,
                      );
                    }),
                  ),
                ],
              ),
            ),

            // Action buttons
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Call button
                SizedBox(
                  width: 44,
                  height: 44,
                  child: AppButton(
                    text: '',
                    variant: ButtonVariant.outline,
                    leadingIcon: Icons.phone,
                    width: 44,
                    height: 44,
                    onPressed: driverPhone != null && driverPhone!.isNotEmpty
                        ? _callDriver
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                // Chat button
                SizedBox(
                  width: 44,
                  height: 44,
                  child: AppButton(
                    text: '',
                    variant: ButtonVariant.outline,
                    leadingIcon: Icons.chat_outlined,
                    width: 44,
                    height: 44,
                    onPressed: onChatPressed,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _callDriver() async {
    if (driverPhone == null) return;
    final uri = Uri(scheme: 'tel', path: driverPhone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
