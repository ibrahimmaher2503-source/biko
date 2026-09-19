part of '../driver_screens.dart';

class RequestDetailsScreen extends ConsumerWidget {
  const RequestDetailsScreen({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(driverOrderProvider(orderId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الطلب'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: () => ref.invalidate(driverOrderProvider(orderId)),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: order.when(
          loading: () => const DriverLoadingState(),
          error: (error, _) => DriverErrorState(
            message: driverErrorMessage(error),
            onRetry: () => ref.invalidate(driverOrderProvider(orderId)),
          ),
          data: (value) => _RequestDetailsContent(order: value),
        ),
      ),
    );
  }
}

class BiddingCountdown extends StatefulWidget {
  const BiddingCountdown({required this.deadline, this.onExpired, super.key});

  final DateTime deadline;
  final VoidCallback? onExpired;

  @override
  State<BiddingCountdown> createState() => _BiddingCountdownState();
}

class _BiddingCountdownState extends State<BiddingCountdown> {
  Timer? _timer;
  bool _expiredNotified = false;

  Duration get _remaining {
    final remaining = widget.deadline.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  @override
  void initState() {
    super.initState();
    _startTicker();
  }

  @override
  void didUpdateWidget(covariant BiddingCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deadline != widget.deadline) _startTicker();
  }

  void _startTicker() {
    _timer?.cancel();
    _expiredNotified = false;
    if (_remaining == Duration.zero) {
      _notifyExpired();
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remaining == Duration.zero) {
        timer.cancel();
        setState(() {});
        _notifyExpired();
      } else {
        setState(() {});
      }
    });
  }

  void _notifyExpired() {
    if (_expiredNotified) return;
    _expiredNotified = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onExpired?.call();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _remaining;
    final expired = remaining == Duration.zero;
    final seconds = remaining.inSeconds;
    final countdown =
        '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
        '${(seconds % 60).toString().padLeft(2, '0')}';
    return Semantics(
      container: true,
      liveRegion: true,
      label: expired ? 'انتهت مهلة الطلب' : 'الوقت المتبقي $countdown',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            expired ? Icons.timer_off_outlined : Icons.timer_outlined,
            color: expired ? DriverColors.error : DriverColors.warning,
          ),
          const SizedBox(width: DriverSpace.sm),
          Text(
            expired ? 'انتهت مهلة الطلب' : 'الوقت المتبقي',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (!expired) ...[
            const SizedBox(width: DriverSpace.sm),
            Text(
              countdown,
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ],
      ),
    );
  }
}

class _RequestDetailsContent extends ConsumerStatefulWidget {
  const _RequestDetailsContent({required this.order});

  final DriverOrder order;

  @override
  ConsumerState<_RequestDetailsContent> createState() =>
      _RequestDetailsContentState();
}

class _RequestDetailsContentState
    extends ConsumerState<_RequestDetailsContent> {
  bool _submitting = false;

  Future<void> _submit(double price) async {
    if (_submitting) return;
    final existing = ref.read(driverOfferProvider(widget.order.id));
    if (!existing.hasValue || existing.hasError) return;
    final previousOfferId = existing.value?.id;
    setState(() => _submitting = true);
    final service = ref.read(driverServiceProvider);
    await runDriverMutation(
      ref,
      () async {
        await service.submitOffer(widget.order.id, price);
      },
      refresh: DriverMutationRefresh.offer,
      orderId: widget.order.id,
      isApplied: (_, _, offer) =>
          offer != null && offer.id != previousOfferId && offer.price == price,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ref.read(driverMutationProvider).blocksActions) return;
    final dashboard = ref.read(driverDashboardProvider).asData?.value;
    if (dashboard?.activeOrder case final active?) {
      context.go('/active-order/${active.id}');
    } else if (ref
            .read(driverOfferProvider(widget.order.id))
            .asData
            ?.value
            ?.status ==
        OfferStatus.active) {
      context.go('/waiting/${widget.order.id}');
    }
  }

  Future<void> _counterOffer() async {
    final price = await showBikoBottomSheet<double>(
      context: context,
      builder: (context) => _CounterOfferSheet(order: widget.order),
    );
    if (price != null) await _submit(price);
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final offerState = ref.watch(driverOfferProvider(order.id));
    final blocked =
        ref.watch(driverMutationProvider).blocksActions ||
        !offerState.hasValue ||
        offerState.hasError;
    final offer = offerState.asData?.value;
    if (offer?.status == OfferStatus.active) {
      return DriverEmptyState(
        icon: Icons.hourglass_top_rounded,
        title: 'لديك عرض لهذا الطلب',
        description: 'تم تحديث الحالة من الخادم.',
        actionLabel: 'فتح العرض',
        onAction: () => context.go('/waiting/${order.id}'),
      );
    }
    if (order.status != OrderStatus.bidding) {
      return DriverEmptyState(
        icon: Icons.update_rounded,
        title: 'الطلب لم يعد متاحًا',
        description: 'تم تحديث حالة الطلب قبل إرسال العرض.',
        actionLabel: 'العودة للرئيسية',
        onAction: () => context.go('/home'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(DriverSpace.md),
      children: [
        DriverCard(
          color: DriverColors.primary.withValues(alpha: .06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ServiceTypeBadge(code: order.serviceCode),
              const SizedBox(height: DriverSpace.md),
              const Text(
                'سعر العميل',
                style: TextStyle(color: DriverColors.muted),
              ),
              const SizedBox(height: DriverSpace.xs),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: PriceDisplay(order.proposedPrice),
              ),
            ],
          ),
        ),
        if (order.biddingDeadline case final deadline?) ...[
          const SizedBox(height: DriverSpace.md),
          DriverCard(
            color: DriverColors.warning.withValues(alpha: .08),
            child: BiddingCountdown(
              deadline: deadline,
              onExpired: () {
                ref
                  ..invalidate(driverOrderProvider(order.id))
                  ..invalidate(driverOfferProvider(order.id));
              },
            ),
          ),
        ],
        const SizedBox(height: DriverSpace.md),
        DriverCard(
          child: RouteSummary(
            pickupAddress: order.pickupAddress,
            destinationAddress: order.destinationAddress,
          ),
        ),
        if (order.hasRouteCoordinates) ...[
          const SizedBox(height: DriverSpace.md),
          DriverRouteMap(order: order),
          if (order.driverDistanceMeters case final distance?) ...[
            const SizedBox(height: DriverSpace.sm),
            Text(
              'تبعد نقطة الاستلام ${(distance / 1000).toStringAsFixed(1)} كم.',
              style: const TextStyle(color: DriverColors.muted),
            ),
          ],
        ],
        const SizedBox(height: DriverSpace.lg),
        if (offerState.hasError)
          DriverErrorState(
            message: driverErrorMessage(offerState.error!),
            onRetry: () => ref.invalidate(driverOfferProvider(order.id)),
          ),
        FilledButton(
          onPressed: _submitting || blocked
              ? null
              : () => _submit(order.proposedPrice),
          child: _submitting
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('قبول سعر العميل'),
        ),
        const SizedBox(height: DriverSpace.sm),
        OutlinedButton(
          onPressed: _submitting || blocked ? null : _counterOffer,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(44, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text('تقديم سعر آخر'),
        ),
        const SizedBox(height: DriverSpace.sm),
        TextButton(
          onPressed: _submitting ? null : () => context.go('/home'),
          child: const Text('تجاهل الطلب'),
        ),
      ],
    );
  }
}

class _CounterOfferSheet extends StatefulWidget {
  const _CounterOfferSheet({required this.order});

  final DriverOrder order;

  @override
  State<_CounterOfferSheet> createState() => _CounterOfferSheetState();
}

class _CounterOfferSheetState extends State<_CounterOfferSheet> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final price = double.tryParse(_controller.text.trim());
    if (price == null || !price.isFinite || price <= 0) {
      setState(() => _error = 'أدخل سعرًا صحيحًا أكبر من صفر.');
      return;
    }
    Navigator.of(context).pop(price);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      DriverSpace.md,
      DriverSpace.md,
      DriverSpace.md,
      MediaQuery.viewInsetsOf(context).bottom + DriverSpace.md,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'تقديم سعر آخر',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: DriverSpace.sm),
        Text(
          'سعر العميل: ${formatAmount(widget.order.proposedPrice)} ج.م',
          style: const TextStyle(color: DriverColors.muted),
        ),
        const SizedBox(height: DriverSpace.md),
        TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'عرضك بالجنيه',
            errorText: _error,
          ),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: DriverSpace.md),
        FilledButton(onPressed: _submit, child: const Text('إرسال العرض')),
      ],
    ),
  );
}
