import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Two-column grid with Package Delivery and Merchant Orders cards.
class ServiceCardGrid extends StatelessWidget {
  const ServiceCardGrid({
    required this.onDeliveryTap,
    required this.onMerchantTap,
    super.key,
  });

  final VoidCallback onDeliveryTap;
  final VoidCallback onMerchantTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _DeliveryCard(onTap: onDeliveryTap)),
        const SizedBox(width: 16),
        Expanded(child: _MerchantCard(onTap: onMerchantTap)),
      ],
    );
  }
}

// ==================== Package Delivery Card ====================

class _DeliveryCard extends StatefulWidget {
  const _DeliveryCard({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_DeliveryCard> createState() => _DeliveryCardState();
}

class _DeliveryCardState extends State<_DeliveryCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: 192,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ext.surfaceElevated,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: ext.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Orange icon container
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppTheme.orange,
                  size: 28,
                ),
              ),
              // Title + description
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'home.package_delivery'.tr,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'home.delivery_description'.tr,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: ext.textMuted),
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

// ==================== Merchant Orders Card ====================

class _MerchantCard extends StatefulWidget {
  const _MerchantCard({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_MerchantCard> createState() => _MerchantCardState();
}

class _MerchantCardState extends State<_MerchantCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: 192,
          padding: const EdgeInsets.all(16),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primary, AppTheme.primaryDark],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -40,
                left: -40,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // White icon container
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.storefront_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  // Title + description
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'home.merchant_orders'.tr,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'home.merchant_description'.tr,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
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
