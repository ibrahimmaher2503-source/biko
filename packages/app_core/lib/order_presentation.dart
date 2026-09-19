import 'package:flutter/material.dart';
import 'app_core.dart' show OrderStatus;
import 'biko_design.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.label, required this.color, super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => StatusChip(label: label, color: color);
}

class PriceDisplay extends StatelessWidget {
  const PriceDisplay(this.value, {this.compact = false, this.label, super.key});

  final double value;
  final bool compact;
  final String? label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${label == null ? '' : '$label، '}${formatAmount(value)} جنيه مصري',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: BikoSpace.xs),
        ],
        ExcludeSemantics(
          child: Text(
            '${formatAmount(value)} ج.م',
            textDirection: TextDirection.rtl,
            style:
                (compact
                        ? Theme.of(context).textTheme.titleLarge
                        : Theme.of(context).textTheme.displaySmall)
                    ?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
          ),
        ),
      ],
    ),
  );
}

class RouteSummary extends StatelessWidget {
  const RouteSummary({
    required this.pickupAddress,
    required this.destinationAddress,
    this.compact = false,
    super.key,
  });

  final String pickupAddress;
  final String destinationAddress;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        _RouteLine(
          icon: Icons.radio_button_checked_rounded,
          color: colors.tertiary,
          label: 'الاستلام',
          value: pickupAddress,
          maxLines: compact ? 1 : 2,
        ),
        SizedBox(height: compact ? BikoSpace.sm : BikoSpace.md),
        _RouteLine(
          icon: Icons.location_on_rounded,
          color: colors.primary,
          label: 'الوجهة',
          value: destinationAddress,
          maxLines: compact ? 1 : 2,
        ),
      ],
    );
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.maxLines,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final int maxLines;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    ],
  );
}

String orderStatusLabel(OrderStatus status) => switch (status) {
  OrderStatus.draft => 'مسودة',
  OrderStatus.bidding => 'بانتظار العروض',
  OrderStatus.driverAssigned => 'تم الإسناد',
  OrderStatus.driverOnWay => 'في الطريق للعميل',
  OrderStatus.driverArrived => 'وصل السائق',
  OrderStatus.inProgress => 'الرحلة جارية',
  OrderStatus.completed => 'مكتملة',
  OrderStatus.cancelled => 'ملغاة',
  OrderStatus.expired => 'منتهية',
};

Color orderStatusColor(BuildContext context, OrderStatus status) {
  final colors = Theme.of(context).colorScheme;
  return switch (status) {
    OrderStatus.completed => colors.tertiary,
    OrderStatus.cancelled || OrderStatus.expired => colors.error,
    OrderStatus.bidding => colors.secondary,
    _ => colors.primary,
  };
}

String formatOrderDate(DateTime date) =>
    '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

String formatAmount(double amount) => amount == amount.roundToDouble()
    ? amount.toStringAsFixed(0)
    : amount.toStringAsFixed(2);

String serviceTypeLabel(String code) => switch (code) {
  'RIDE' => 'رحلة',
  'DELIVERY' => 'توصيل',
  _ => 'خدمة',
};

class ServiceTypeBadge extends StatelessWidget {
  const ServiceTypeBadge({required this.code, super.key});
  final String code;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return StatusBadge(
      label: serviceTypeLabel(code),
      color: code == 'DELIVERY' ? colors.secondary : colors.primary,
    );
  }
}
