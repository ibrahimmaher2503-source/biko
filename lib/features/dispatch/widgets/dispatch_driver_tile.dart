import 'package:biko/core/models/driver_location_model.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// List tile for an online driver shown in the dispatcher app.
class DispatchDriverTile extends StatelessWidget {
  const DispatchDriverTile({
    super.key,
    required this.driver,
    this.onSelect,
    this.isSelectable = false,
  });

  final DriverLocationModel driver;
  final VoidCallback? onSelect;
  final bool isSelectable;

  String _shortUid() {
    if (driver.uid.length <= 8) return driver.uid;
    return '${driver.uid.substring(0, 8)}…';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return ListTile(
      contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 4),
      leading: CircleAvatar(
        backgroundColor: colors.successBg,
        child: Icon(
          _vehicleIcon(),
          color: colors.success,
          size: 20,
        ),
      ),
      title: Text(
        _shortUid(),
        style: theme.textTheme.bodyMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        driver.vehicleType,
        style: theme.textTheme.bodySmall?.copyWith(color: colors.textMuted),
      ),
      trailing: isSelectable
          ? TextButton(
              onPressed: onSelect,
              child: Text('dispatch.assign'.tr),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Online',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: colors.success),
                ),
              ],
            ),
    );
  }

  IconData _vehicleIcon() {
    switch (driver.vehicleType) {
      case 'scooter':
        return Icons.electric_scooter_rounded;
      case 'ebike':
        return Icons.electric_bike_rounded;
      default:
        return Icons.two_wheeler_rounded;
    }
  }
}
