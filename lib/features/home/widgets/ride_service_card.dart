import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Prominent "Take a Ride" service card matching the reference design.
///
/// Features a "POPULAR" badge, title, description, motorcycle
/// illustration (with icon fallback), and a "Book Now" CTA button.
class RideServiceCard extends StatefulWidget {
  const RideServiceCard({required this.onBookNow, super.key, this.onCardTap});

  final VoidCallback onBookNow;
  final VoidCallback? onCardTap;

  @override
  State<RideServiceCard> createState() => _RideServiceCardState();
}

class _RideServiceCardState extends State<RideServiceCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onCardTap ?? widget.onBookNow,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.all(20),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left content (text + button)
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // POPULAR badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'home.popular'.tr,
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Title
                    Text(
                      'home.take_a_ride'.tr,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    // Description
                    Text(
                      'home.ride_description'.tr,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: ext.textMuted),
                    ),
                    const SizedBox(height: 16),
                    // Book Now button
                    GestureDetector(
                      onTap: widget.onBookNow,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          'home.book_now'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Right — motorcycle illustration
              Expanded(
                flex: 4,
                child: SizedBox(height: 112, child: _buildMotorcycleImage()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMotorcycleImage() {
    return Image.asset(
      'assets/images/home/motorcycle.png',
      height: 112,
      width: 112,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        Icons.two_wheeler,
        size: 64,
        color: AppTheme.primary.withValues(alpha: 0.6),
      ),
    );
  }
}
