import 'package:biko/core/models/promo_code_model.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DeletePromoDialog extends StatelessWidget {
  const DeletePromoDialog({
    required this.promo,
    super.key,
  });

  final PromoCodeModel promo;

  static Future<bool?> show(
    BuildContext context, {
    required PromoCodeModel promo,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => DeletePromoDialog(promo: promo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'admin.promos.delete_title'.tr,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(
                '${'admin.promos.delete_confirm'.tr} "${promo.code}"?',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      label: 'admin.promos.code'.tr,
                      value: promo.code,
                    ),
                    const SizedBox(height: 4),
                    _InfoRow(
                      label: 'admin.promos.discount'.tr,
                      value: promo.formattedDiscount,
                    ),
                    const SizedBox(height: 4),
                    _InfoRow(
                      label: 'admin.promos.status'.tr,
                      value: promo.isValid
                          ? 'admin.promos.active'.tr
                          : 'admin.promos.inactive'.tr,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 120,
                    child: AppButton(
                      text: 'common.cancel'.tr,
                      variant: ButtonVariant.outline,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusDefault,
                          ),
                        ),
                        minimumSize: const Size(120, 44),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('common.delete'.tr),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: colors.textMuted, fontSize: 13),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
