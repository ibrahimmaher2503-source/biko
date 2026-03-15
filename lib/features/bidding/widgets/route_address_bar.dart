import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Displays pickup and dropoff addresses in a vertical layout.
///
/// Pickup: red circle icon + address text
/// Dropoff: location pin icon + address text
/// Separated by a subtle divider, matching the stitch design.
class RouteAddressBar extends StatelessWidget {
  const RouteAddressBar({
    required this.pickupAddress,
    required this.dropoffAddress,
    super.key,
  });

  final String pickupAddress;
  final String dropoffAddress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return Column(
      children: [
        // Pickup row
        _AddressRow(
          icon: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary,
              border: Border.all(color: AppTheme.primary, width: 2),
            ),
          ),
          address: pickupAddress,
          textStyle: theme.textTheme.bodyLarge!,
        ),

        // Divider
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 36),
          child: Divider(color: colors.borderSubtle, height: 1),
        ),

        // Dropoff row
        _AddressRow(
          icon: Icon(Icons.location_on, color: colors.textMuted, size: 20),
          address: dropoffAddress,
          textStyle: theme.textTheme.bodyLarge!,
        ),
      ],
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({
    required this.icon,
    required this.address,
    required this.textStyle,
  });

  final Widget icon;
  final String address;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          SizedBox(width: 20, child: Center(child: icon)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              address,
              style: textStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
