import 'dart:async';

import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:user_app/app/user_theme.dart';
import 'package:user_app/core/widgets/driver_avatar.dart';
import 'package:user_app/core/widgets/feedback_widgets.dart';
import 'package:user_app/features/orders/order_models.dart';

class BiddingCountdown extends StatefulWidget {
  const BiddingCountdown({
    required this.expiresAt,
    required this.onElapsed,
    super.key,
  });

  final DateTime expiresAt;
  final VoidCallback onElapsed;

  @override
  State<BiddingCountdown> createState() => _BiddingCountdownState();
}

class _BiddingCountdownState extends State<BiddingCountdown> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _notified = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant BiddingCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt) _start();
  }

  void _start() {
    _timer?.cancel();
    _notified = false;
    _tick();
    if (_remaining > Duration.zero) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  void _tick() {
    final value = widget.expiresAt.toUtc().difference(DateTime.now().toUtc());
    final next = value.isNegative ? Duration.zero : value;
    if (mounted) setState(() => _remaining = next);
    if (next == Duration.zero && !_notified) {
      _notified = true;
      _timer?.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onElapsed());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seconds = _remaining.inSeconds;
    final label =
        '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
        '${(seconds % 60).toString().padLeft(2, '0')}';
    return Semantics(
      liveRegion: true,
      label: 'الوقت المتبقي $label',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: UserColors.warning.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(BikoRadius.medium),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BikoSpace.md,
            vertical: BikoSpace.sm,
          ),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, color: UserColors.warning),
              const SizedBox(width: BikoSpace.sm),
              Expanded(
                child: Text(
                  'الوقت المتبقي لاستقبال العروض',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                label,
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  color: UserColors.warning,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DriverOffersSection extends StatelessWidget {
  const DriverOffersSection({
    required this.offers,
    required this.disabled,
    required this.onSelect,
    super.key,
  });

  final List<DriverOffer> offers;
  final bool disabled;
  final ValueChanged<DriverOffer> onSelect;

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) {
      return Card(
        color: UserColors.surfaceSecondary,
        child: const Padding(
          padding: EdgeInsets.all(BikoSpace.md),
          child: UserInlineMessage(
            message:
                'لم يصل أي عرض حتى الآن. ستظهر العروض تلقائيًا، ويمكنك التحديث يدويًا.',
            icon: Icons.hourglass_empty_rounded,
          ),
        ),
      );
    }
    return Column(
      children: [
        for (final offer in offers) ...[
          DriverOfferCard(
            offer: offer,
            onSelect: disabled ? null : () => onSelect(offer),
          ),
          if (offer != offers.last) const SizedBox(height: BikoSpace.gap),
        ],
      ],
    );
  }
}

class DriverOfferCard extends StatelessWidget {
  const DriverOfferCard({required this.offer, this.onSelect, super.key});

  final DriverOffer offer;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(BikoSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              DriverAvatar(
                name: offer.driverFirstName,
                url: offer.driverPhotoUrl,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.driverFirstName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: BikoSpace.xs),
                    Text(
                      offer.driverType == DriverType.independent
                          ? 'سائق مستقل'
                          : 'سائق مكتب${offer.officeDisplayName == null ? '' : '، ${offer.officeDisplayName}'}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text('${offer.completedTripCount} رحلة مكتملة'),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: BikoSpace.lg),
          Row(
            children: [
              const Text(
                'عرض السائق',
                style: TextStyle(color: UserColors.muted),
              ),
              const Spacer(),
              PriceDisplay(offer.price, compact: true),
            ],
          ),
          const SizedBox(height: BikoSpace.sm),
          PrimaryButton(
            onPressed: onSelect,
            label: 'اختيار',
            icon: Icons.check_rounded,
          ),
        ],
      ),
    ),
  );
}
