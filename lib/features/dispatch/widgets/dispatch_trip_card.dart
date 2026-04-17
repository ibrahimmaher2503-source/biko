import 'package:biko/core/models/enums.dart';
import 'package:biko/core/models/trip_model.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Compact card showing a trip's key info for the dispatcher.
///
/// Shows pickup/dropoff, price, elapsed wait time, and action buttons.
class DispatchTripCard extends StatelessWidget {
  const DispatchTripCard({
    super.key,
    required this.trip,
    required this.onAssign,
    this.onCancel,
    this.showCancel = true,
  });

  final TripModel trip;
  final VoidCallback onAssign;
  final VoidCallback? onCancel;
  final bool showCancel;

  String _waitTime() {
    final diff = DateTime.now().difference(trip.createdAt);
    if (diff.inMinutes < 1) return '< 1 ${'dispatch.min'.tr}';
    return '${diff.inMinutes} ${'dispatch.min'.tr}';
  }

  String _tripTypeLabel() {
    return trip.type == TripType.ride
        ? 'dispatch.type_ride'.tr
        : 'dispatch.type_delivery'.tr;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return Card(
      margin: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row: type badge + wait time ──
            Row(
              children: [
                _Badge(
                  label: _tripTypeLabel(),
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                _Badge(
                  label: trip.status.toJson(),
                  color: colors.warning,
                  textColor: Colors.black87,
                ),
                const Spacer(),
                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: colors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  _waitTime(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Pickup ──
            _LocationRow(
              icon: Icons.radio_button_on_rounded,
              iconColor: colors.success,
              text: trip.pickup.address,
            ),
            const SizedBox(height: 4),

            // ── Dropoff ──
            _LocationRow(
              icon: Icons.location_on_rounded,
              iconColor: theme.colorScheme.primary,
              text: trip.dropoff.address,
            ),
            const SizedBox(height: 10),

            // ── Price + distance row ──
            Row(
              children: [
                Text(
                  '${trip.customerPrice.toStringAsFixed(0)} EGP',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (trip.distanceKm != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '· ${trip.distanceKm!.toStringAsFixed(1)} ${'dispatch.km'.tr}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colors.textMuted),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // ── Action buttons ──
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'dispatch.assign'.tr,
                    onPressed: onAssign,
                    variant: ButtonVariant.primary,
                  ),
                ),
                if (showCancel && onCancel != null) ...[
                  const SizedBox(width: 8),
                  AppButton(
                    text: 'dispatch.cancel_trip'.tr,
                    onPressed: onCancel,
                    variant: ButtonVariant.outline,
                    width: null,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  final IconData icon;
  final Color iconColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colors.textMuted),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    this.textColor,
  });

  final String label;
  final Color color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor ?? color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
