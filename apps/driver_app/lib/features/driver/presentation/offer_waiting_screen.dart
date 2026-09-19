part of '../driver_screens.dart';

class OfferWaitingScreen extends ConsumerWidget {
  const OfferWaitingScreen({required this.orderId, super.key});

  final String orderId;

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(driverOfferProvider(orderId));
    try {
      await ref.read(driverOfferProvider(orderId).future);
    } catch (_) {
      /* Render typed provider error. */
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offer = ref.watch(driverOfferProvider(orderId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('حالة العرض'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: () => _refresh(ref),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: offer.when(
          loading: () => const DriverLoadingState(),
          error: (error, _) => DriverErrorState(
            message: driverErrorMessage(error),
            onRetry: () => ref.invalidate(driverOfferProvider(orderId)),
          ),
          data: (value) => _OfferWaitingContent(
            orderId: orderId,
            offer: value,
            onRefresh: () => _refresh(ref),
          ),
        ),
      ),
    );
  }
}

class _OfferWaitingContent extends ConsumerStatefulWidget {
  const _OfferWaitingContent({
    required this.orderId,
    required this.offer,
    required this.onRefresh,
  });

  final String orderId;
  final DriverOffer? offer;
  final Future<void> Function() onRefresh;

  @override
  ConsumerState<_OfferWaitingContent> createState() =>
      _OfferWaitingContentState();
}

class _OfferWaitingContentState extends ConsumerState<_OfferWaitingContent> {
  bool _withdrawing = false;

  Future<void> _withdraw() async {
    if (_withdrawing || widget.offer?.canWithdraw != true) return;
    setState(() => _withdrawing = true);
    final service = ref.read(driverServiceProvider);
    await runDriverMutation(
      ref,
      () => service.withdrawOffer(widget.offer!.id),
      refresh: DriverMutationRefresh.offer,
      orderId: widget.orderId,
      isApplied: (_, _, offer) => offer?.status == OfferStatus.withdrawn,
    );
    if (mounted) setState(() => _withdrawing = false);
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    if (offer == null) {
      return DriverEmptyState(
        icon: Icons.search_off_rounded,
        title: 'لا يوجد عرض لهذا الطلب',
        description: 'قد يكون الطلب منتهيًا أو لم يتم إرسال العرض.',
        actionLabel: 'العودة للرئيسية',
        onAction: () => context.go('/home'),
      );
    }
    if (offer.hasActiveTrip) {
      return DriverEmptyState(
        icon: Icons.check_circle_rounded,
        title: 'تم اختيارك للرحلة',
        description: 'افتح الرحلة وابدأ التوجه إلى العميل.',
        actionLabel: 'فتح الرحلة',
        onAction: () => context.go('/active-order/${widget.orderId}'),
      );
    }
    if (offer.status != OfferStatus.active ||
        offer.orderStatus != OrderStatus.bidding) {
      return DriverEmptyState(
        icon: Icons.info_outline_rounded,
        title: offer.closedLabel,
        description: 'لم يعد هذا العرض نشطًا. يمكنك العودة للطلبات المتاحة.',
        actionLabel: 'العودة للرئيسية',
        onAction: () => context.go('/home'),
      );
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(DriverSpace.md),
        children: [
          const SizedBox(height: DriverSpace.lg),
          const Icon(
            Icons.hourglass_top_rounded,
            size: 58,
            color: DriverColors.warning,
          ),
          const SizedBox(height: DriverSpace.md),
          const Text(
            'تم إرسال عرضك',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: DriverSpace.sm),
          const Text(
            'في انتظار اختيار العميل. حدّث الحالة عند الحاجة.',
            textAlign: TextAlign.center,
            style: TextStyle(color: DriverColors.muted),
          ),
          const SizedBox(height: DriverSpace.lg),
          if (offer.biddingDeadline case final deadline?) ...[
            DriverCard(
              color: DriverColors.warning.withValues(alpha: .08),
              child: BiddingCountdown(
                deadline: deadline,
                onExpired: widget.onRefresh,
              ),
            ),
            const SizedBox(height: DriverSpace.md),
          ],
          if (offer.customerPrice case final customerPrice?) ...[
            DriverCard(
              key: const ValueKey('offer-price-comparison'),
              child: Row(
                children: [
                  Expanded(
                    child: _OfferPriceCell(
                      label: 'سعر العميل',
                      value: customerPrice,
                    ),
                  ),
                  const SizedBox(width: DriverSpace.md),
                  Expanded(
                    child: _OfferPriceCell(label: 'عرضك', value: offer.price),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DriverSpace.md),
          ],
          DriverCard(
            child: Column(
              children: [
                const Text('عرضك', style: TextStyle(color: DriverColors.muted)),
                const SizedBox(height: DriverSpace.xs),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.center,
                  child: PriceDisplay(offer.price),
                ),
              ],
            ),
          ),
          const SizedBox(height: DriverSpace.md),
          DriverCard(
            child: RouteSummary(
              pickupAddress: offer.pickupAddress,
              destinationAddress: offer.destinationAddress,
            ),
          ),
          const SizedBox(height: DriverSpace.lg),
          FilledButton.icon(
            onPressed: _withdrawing ? null : widget.onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('تحديث الحالة'),
          ),
          const SizedBox(height: DriverSpace.sm),
          OutlinedButton.icon(
            onPressed:
                _withdrawing ||
                    !offer.canWithdraw ||
                    ref.watch(driverMutationProvider).blocksActions
                ? null
                : _withdraw,
            icon: _withdrawing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.undo_rounded),
            label: const Text('سحب العرض'),
          ),
          TextButton(
            onPressed: () => context.go('/home'),
            child: const Text('العودة للرئيسية'),
          ),
        ],
      ),
    );
  }
}

class _OfferPriceCell extends StatelessWidget {
  const _OfferPriceCell({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: DriverColors.muted)),
      const SizedBox(height: DriverSpace.xs),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: PriceDisplay(value, compact: true),
      ),
    ],
  );
}
