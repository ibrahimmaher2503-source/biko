import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:user_app/app/user_theme.dart';
import 'package:user_app/core/widgets/driver_avatar.dart';
import 'package:user_app/features/orders/order_models.dart';

class DriverSummaryCard extends StatelessWidget {
  const DriverSummaryCard({required this.driver, super.key});
  final DriverSummary driver;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(BikoSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DriverAvatar(
                name: driver.driverFirstName,
                url: driver.driverPhotoUrl,
              ),
              const SizedBox(width: BikoSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.driverFirstName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: BikoSpace.xs),
                    Wrap(
                      spacing: BikoSpace.sm,
                      runSpacing: BikoSpace.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusChip(
                          label: driver.driverVerified
                              ? 'هوية معتمدة'
                              : 'التحقق غير متاح',
                          color: driver.driverVerified
                              ? UserColors.success
                              : UserColors.warning,
                        ),
                        Text(
                          driver.driverType == DriverType.independent
                              ? 'سائق مستقل'
                              : 'سائق مكتب${driver.officeDisplayName == null ? '' : '، ${driver.officeDisplayName}'}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: BikoSpace.xs),
                    Text('${driver.completedTripCount} رحلة مكتملة'),
                  ],
                ),
              ),
            ],
          ),
          if (driver.motorcyclePlateNumber case final plate?) ...[
            const SizedBox(height: BikoSpace.md),
            DecoratedBox(
              key: const Key('driver-plate'),
              decoration: BoxDecoration(
                color: UserColors.text,
                borderRadius: BorderRadius.circular(BikoRadius.medium),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: BikoSpace.sm,
                  vertical: BikoSpace.sm,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.two_wheeler_rounded,
                      size: 18,
                      color: UserColors.surface,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'رقم اللوحة',
                      style: TextStyle(color: UserColors.surface),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        plate,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: UserColors.surface,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (driver.motorcycleBrand != null ||
              driver.motorcycleModel != null) ...[
            const SizedBox(height: BikoSpace.xs),
            Text(
              [
                driver.motorcycleBrand,
                driver.motorcycleModel,
              ].whereType<String>().join(' '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    ),
  );
}

class DeliveryConfirmationCodeCard extends StatelessWidget {
  const DeliveryConfirmationCodeCard({required this.code, super.key});
  final String code;

  @override
  Widget build(BuildContext context) => Card(
    color: UserColors.text,
    child: Padding(
      padding: const EdgeInsets.all(BikoSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_shipping_outlined,
                color: UserColors.surface,
              ),
              const SizedBox(width: BikoSpace.sm),
              Text(
                'رمز تسليم الشحنة',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: UserColors.surface),
                // The charcoal card intentionally separates this operational
                // confirmation from authentication UI.
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
          const SizedBox(height: BikoSpace.md),
          SelectableText(
            code,
            key: const Key('delivery-confirmation-code'),
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: UserColors.surface,
              fontWeight: FontWeight.w900,
              letterSpacing: 12,
            ),
          ),
          const SizedBox(height: BikoSpace.sm),
          const Text(
            'أعطِ هذا الكود للمستلم ليقدمه للسائق عند استلام الشحنة.',
            textAlign: TextAlign.center,
            style: TextStyle(color: UserColors.surface),
          ),
        ],
      ),
    ),
  );
}
