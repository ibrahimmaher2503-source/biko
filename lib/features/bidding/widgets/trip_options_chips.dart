import 'package:biko/core/models/enums.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/features/bidding/controllers/bidding_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Row of tappable chips for payment method, passenger count, and trip note.
///
/// Each chip opens a bottom sheet picker on tap.
/// Uses Obx to reactively read/write BiddingController state.
class TripOptionsChips extends GetView<BiddingController> {
  const TripOptionsChips({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Obx(
        () => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Payment method chip
            _OptionChip(
              icon: Icons.payments_outlined,
              label: _paymentLabel(controller.paymentMethod.value),
              onTap: () => _showPaymentPicker(context),
            ),

            // Passenger count chip
            _OptionChip(
              icon: Icons.person_outline,
              label: controller.passengerCount.value == 1
                  ? '1 ${'trip.passenger'.tr}'
                  : '${controller.passengerCount.value} ${'trip.passengers'.tr}',
              onTap: () => _showPassengerPicker(context),
            ),

            // Add Note chip
            _OptionChip(
              icon: controller.tripNote.value.isNotEmpty
                  ? Icons.check
                  : Icons.note_alt_outlined,
              label: controller.tripNote.value.isNotEmpty
                  ? 'trip.note_added'.tr
                  : 'trip.add_note'.tr,
              onTap: () => _showNoteDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Get localized label for a payment method.
  String _paymentLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'trip.cash'.tr;
      case PaymentMethod.wallet:
        return 'trip.wallet'.tr;
      case PaymentMethod.card:
        return 'trip.card'.tr;
      case PaymentMethod.vodafoneCash:
        return 'trip.vodafone_cash'.tr;
      case PaymentMethod.fawry:
        return 'trip.fawry'.tr;
    }
  }

  /// Show payment method picker bottom sheet.
  void _showPaymentPicker(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('trip.payment_method'.tr, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...PaymentMethod.values.map(
              (method) => ListTile(
                leading: Icon(
                  _paymentIcon(method),
                  color: controller.paymentMethod.value == method
                      ? AppTheme.primary
                      : colors.textMuted,
                ),
                title: Text(_paymentLabel(method)),
                trailing: controller.paymentMethod.value == method
                    ? const Icon(Icons.check, color: AppTheme.primary)
                    : null,
                onTap: () {
                  controller.setPaymentMethod(method);
                  Get.back();
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Get icon for a payment method.
  IconData _paymentIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.payments_outlined;
      case PaymentMethod.wallet:
        return Icons.account_balance_wallet_outlined;
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.vodafoneCash:
        return Icons.phone_android;
      case PaymentMethod.fawry:
        return Icons.store_outlined;
    }
  }

  /// Show passenger count picker bottom sheet.
  void _showPassengerPicker(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('trip.passenger_count'.tr, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...[1, 2, 3].map(
              (count) => ListTile(
                leading: Icon(
                  Icons.person,
                  color: controller.passengerCount.value == count
                      ? AppTheme.primary
                      : colors.textMuted,
                ),
                title: Text(
                  count == 1
                      ? '1 ${'trip.passenger'.tr}'
                      : '$count ${'trip.passengers'.tr}',
                ),
                trailing: controller.passengerCount.value == count
                    ? const Icon(Icons.check, color: AppTheme.primary)
                    : null,
                onTap: () {
                  controller.setPassengerCount(count);
                  Get.back();
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Show note dialog with text field.
  void _showNoteDialog(BuildContext context) {
    final textController = TextEditingController(
      text: controller.tripNote.value,
    );

    Get.dialog(
      AlertDialog(
        title: Text('trip.add_note'.tr),
        content: TextField(
          controller: textController,
          maxLength: 200,
          maxLines: 3,
          decoration: InputDecoration(hintText: 'trip.note_hint'.tr),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          ElevatedButton(
            onPressed: () {
              controller.setNote(textController.text);
              Get.back();
            },
            child: Text('trip.note_save'.tr),
          ),
        ],
      ),
    );
  }
}

/// Individual option chip with icon and label.
class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: colors.textMuted),
            const SizedBox(width: 6),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
