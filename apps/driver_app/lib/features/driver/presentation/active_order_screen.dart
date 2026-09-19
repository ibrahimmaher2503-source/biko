part of '../driver_screens.dart';

class ActiveOrderScreen extends ConsumerWidget {
  const ActiveOrderScreen({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(driverOrderProvider(orderId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('الرحلة النشطة'),
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
          data: (value) => _ActiveOrderContent(order: value),
        ),
      ),
    );
  }
}

class DriverCustomerContactActions extends ConsumerStatefulWidget {
  const DriverCustomerContactActions({
    required this.order,
    this.launcher,
    super.key,
  });

  final DriverOrder order;
  final Future<bool> Function(Uri uri)? launcher;

  @override
  ConsumerState<DriverCustomerContactActions> createState() =>
      _DriverCustomerContactActionsState();
}

class _DriverCustomerContactActionsState
    extends ConsumerState<DriverCustomerContactActions> {
  var _calling = false;

  bool get _canContact => canDriverContactCustomer(widget.order.status);

  @override
  Widget build(BuildContext context) {
    if (!_canContact) return const SizedBox.shrink();
    final contact = ref.watch(driverCustomerContactProvider(widget.order.id));
    return contact.when(
      loading: () => const DriverCard(
        child: SizedBox(
          height: 24,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
      error: (_, _) => DriverCard(
        child: Row(
          children: [
            const Expanded(child: Text('تعذر تحميل بيانات العميل الآن.')),
            TextButton(
              onPressed: () => ref.invalidate(
                driverCustomerContactProvider(widget.order.id),
              ),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
      data: (value) {
        final phone = value?.phone == null
            ? null
            : normalizeDriverCallPhone(value!.phone!);
        final name = value?.name.trim() ?? '';
        if (value == null || (name.isEmpty && phone == null)) {
          return const DriverCard(
            child: Text('بيانات اتصال العميل غير متاحة الآن.'),
          );
        }
        return DriverCard(
          color: DriverColors.primary.withValues(alpha: .04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'بيانات العميل',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              if (name.isNotEmpty) ...[
                const SizedBox(height: DriverSpace.xs),
                Text(name, style: const TextStyle(fontSize: 16)),
              ],
              const SizedBox(height: DriverSpace.sm),
              if (phone == null)
                const Text(
                  'رقم العميل غير متاح الآن.',
                  style: TextStyle(color: DriverColors.muted),
                )
              else
                FilledButton.icon(
                  key: const Key('call-customer'),
                  onPressed: _calling ? null : _call,
                  icon: _calling
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.call_rounded),
                  label: Text(
                    _calling ? 'جارٍ فتح الاتصال...' : 'اتصل بالعميل',
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _call() async {
    if (_calling || !_canContact) return;
    final orderId = widget.order.id;
    setState(() => _calling = true);
    try {
      final fresh = await ref
          .read(driverServiceProvider)
          .loadCustomerContact(orderId);
      if (!mounted || widget.order.id != orderId || !_canContact) {
        return;
      }
      final phone = fresh?.phone == null
          ? null
          : normalizeDriverCallPhone(fresh!.phone!);
      if (phone == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('بيانات الاتصال لم تعد متاحة الآن.')),
        );
        return;
      }
      if (!await ref
              .read(driverServiceProvider)
              .launchCustomerCall(phone, launcher: widget.launcher) &&
          mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح تطبيق الاتصال.')),
        );
      }
    } on ReadFailure catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(driverErrorMessage(error))));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر بدء الاتصال. حاول مرة أخرى.')),
        );
      }
    } finally {
      if (mounted) setState(() => _calling = false);
    }
  }
}

class _ActiveOrderContent extends ConsumerStatefulWidget {
  const _ActiveOrderContent({required this.order});

  final DriverOrder order;

  @override
  ConsumerState<_ActiveOrderContent> createState() =>
      _ActiveOrderContentState();
}

class _ActiveOrderContentState extends ConsumerState<_ActiveOrderContent> {
  bool _updating = false;
  bool _locationReady = false;
  late final DriverForegroundLocation _location;

  @override
  void initState() {
    super.initState();
    _location = DriverForegroundLocation(
      ref.read(driverServiceProvider),
      onError: _showLocationError,
    );
    if (widget.order.nextAction != null) {
      unawaited(_startLocation());
    }
  }

  Future<void> _startLocation() async {
    try {
      await _location.start(activeTrip: true);
      if (mounted && widget.order.nextAction != null) {
        setState(() => _locationReady = true);
      }
    } catch (error) {
      if (mounted && widget.order.nextAction != null) {
        _showLocationError(driverLocationErrorMessage(error));
      }
    }
  }

  @override
  void didUpdateWidget(covariant _ActiveOrderContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasActionable = oldWidget.order.nextAction != null;
    final isActionable = widget.order.nextAction != null;
    if (wasActionable == isActionable) return;
    if (isActionable) {
      unawaited(_startLocation());
    } else {
      _locationReady = false;
      unawaited(_location.stop());
    }
  }

  void _showLocationError(String message) {
    if (!mounted) return;
    final hasRecovery = _location.recoveryAction != null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: hasRecovery
            ? SnackBarAction(
                label: 'الإعدادات',
                onPressed: () => unawaited(_location.openRecoverySettings()),
              )
            : null,
      ),
    );
  }

  Future<void> _uploadCurrentLocation() async {
    await _location.uploadNow();
    if (mounted && widget.order.nextAction != null && !_locationReady) {
      setState(() => _locationReady = true);
    }
  }

  @override
  void dispose() {
    unawaited(_location.stop());
    super.dispose();
  }

  Future<void> _advance(DriverTripAction action) async {
    if (_updating) return;
    if (action == DriverTripAction.deliveryComplete) {
      await _completeDelivery();
      return;
    }
    setState(() => _updating = true);
    final service = ref.read(driverServiceProvider);
    final previousStatus = widget.order.status;
    await runDriverMutation(
      ref,
      () async {
        if (const {
          DriverTripAction.arrived,
          DriverTripAction.deliveryPickup,
          DriverTripAction.complete,
        }.contains(action)) {
          await _uploadCurrentLocation();
        }
        await service.advanceOrder(widget.order.id, action);
      },
      refresh: action == DriverTripAction.complete
          ? DriverMutationRefresh.terminal
          : DriverMutationRefresh.lifecycle,
      orderId: widget.order.id,
      isApplied: (_, order, _) =>
          order != null && order.status != previousStatus,
    );
    if (mounted) setState(() => _updating = false);
  }

  Future<void> _completeDelivery() async {
    final code = await showBikoBottomSheet<String>(
      context: context,
      builder: (_) => const _DeliveryConfirmationSheet(),
    );
    if (code == null || _updating || !mounted) return;
    setState(() => _updating = true);
    final service = ref.read(driverServiceProvider);
    await runDriverMutation(
      ref,
      () async {
        await _uploadCurrentLocation();
        final result = await service.completeDelivery(widget.order.id, code);
        if (result.outcome == 'INVALID_CODE') {
          throw DriverAppException(
            'الكود غير صحيح. متبقي ${result.attemptsRemaining ?? 0} محاولات.',
          );
        }
        if (result.outcome == 'LOCKED') {
          throw const DriverAppException(
            'تم إيقاف محاولات الكود مؤقتًا لحماية الطلب.',
          );
        }
      },
      refresh: DriverMutationRefresh.terminal,
      orderId: widget.order.id,
      isApplied: (_, order, _) => order?.status == OrderStatus.completed,
    );
    if (mounted) setState(() => _updating = false);
  }

  Future<void> _cancel() async {
    final reason = await showBikoBottomSheet<String>(
      context: context,
      builder: (_) => const _DriverCancellationSheet(),
    );
    if (reason == null || _updating || !mounted) return;
    setState(() => _updating = true);
    final service = ref.read(driverServiceProvider);
    await runDriverMutation(
      ref,
      () => service.cancelOrder(widget.order.id, reason),
      refresh: DriverMutationRefresh.terminal,
      orderId: widget.order.id,
      isApplied: (_, order, _) => order?.status == OrderStatus.cancelled,
    );
    if (mounted) setState(() => _updating = false);
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final nextAction = order.nextAction;
    if (order.status == OrderStatus.completed) {
      return DriverEmptyState(
        icon: Icons.task_alt_rounded,
        title: 'تمت الرحلة بنجاح',
        description:
            '${order.pickupAddress} ← ${order.destinationAddress}\n${formatAmount(order.displayPrice)} ج.م',
        actionLabel: 'العودة للرئيسية',
        onAction: () => context.go('/home'),
      );
    }
    if (!canDriverContactCustomer(order.status) && nextAction == null) {
      return DriverEmptyState(
        icon: Icons.info_outline_rounded,
        title: orderStatusLabel(order.status),
        description: 'لا يوجد إجراء متاح لهذه الحالة.',
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  StatusBadge(
                    label: orderStatusLabel(order.status),
                    color: DriverColors.primary,
                  ),
                  const Spacer(),
                  Text(
                    order.serviceName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: DriverSpace.lg),
              const Text(
                'السعر المتفق عليه',
                style: TextStyle(color: DriverColors.muted),
              ),
              const SizedBox(height: DriverSpace.xs),
              PriceDisplay(order.displayPrice),
            ],
          ),
        ),
        if (canDriverContactCustomer(order.status)) ...[
          const SizedBox(height: DriverSpace.md),
          DriverCustomerContactActions(order: order),
        ],
        if (order.hasRouteCoordinates) ...[
          const SizedBox(height: DriverSpace.md),
          DriverRouteMap(order: order, currentLocationEnabled: _locationReady),
          const SizedBox(height: DriverSpace.sm),
          OutlinedButton.icon(
            onPressed: () async {
              if (!await openExternalNavigation(order) && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تعذر فتح خرائط Google.')),
                );
              }
            },
            icon: const Icon(Icons.navigation_rounded),
            label: Text(
              order.status == OrderStatus.inProgress
                  ? 'التوجيه إلى الوجهة'
                  : 'التوجيه إلى نقطة الاستلام',
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
        if (nextAction != null) ...[
          const SizedBox(height: DriverSpace.xl),
          FilledButton(
            onPressed:
                _updating || ref.watch(driverMutationProvider).blocksActions
                ? null
                : () => _advance(nextAction),
            child: _updating
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(nextAction.label),
          ),
        ],
        if (order.canDriverCancel) ...[
          const SizedBox(height: DriverSpace.sm),
          TextButton.icon(
            onPressed:
                _updating || ref.watch(driverMutationProvider).blocksActions
                ? null
                : _cancel,
            style: TextButton.styleFrom(foregroundColor: DriverColors.error),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('إلغاء الرحلة'),
          ),
        ],
      ],
    );
  }
}

class _DeliveryConfirmationSheet extends StatefulWidget {
  const _DeliveryConfirmationSheet();

  @override
  State<_DeliveryConfirmationSheet> createState() =>
      _DeliveryConfirmationSheetState();
}

class _DeliveryConfirmationSheetState
    extends State<_DeliveryConfirmationSheet> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _controller.text.trim();
    if (!RegExp(r'^\d{4}$').hasMatch(code)) {
      setState(() => _error = 'أدخل 4 أرقام.');
      return;
    }
    Navigator.of(context).pop(code);
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
          'كود تأكيد التسليم',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: DriverSpace.sm),
        const Text(
          'اطلب من العميل كود التسليم النهائي. لا يوجد كود عند الاستلام.',
          style: TextStyle(color: DriverColors.muted),
        ),
        const SizedBox(height: DriverSpace.md),
        TextField(
          key: const Key('delivery-confirmation-code'),
          controller: _controller,
          autofocus: true,
          maxLength: 4,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(labelText: 'الكود', errorText: _error),
          onSubmitted: (_) => _submit(),
        ),
        FilledButton(onPressed: _submit, child: const Text('تأكيد التسليم')),
      ],
    ),
  );
}

class _DriverCancellationSheet extends StatefulWidget {
  const _DriverCancellationSheet();

  @override
  State<_DriverCancellationSheet> createState() =>
      _DriverCancellationSheetState();
}

class _DriverCancellationSheetState extends State<_DriverCancellationSheet> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _controller.text.trim();
    if (reason.isEmpty || reason.length > 500) {
      setState(() => _error = 'اكتب سبب الإلغاء في 500 حرف أو أقل.');
      return;
    }
    Navigator.of(context).pop(reason);
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
          'سبب إلغاء الرحلة',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: DriverSpace.sm),
        const Text(
          'سيتم إلغاء الطلب ولن يعود تلقائيًا للمزايدة.',
          style: TextStyle(color: DriverColors.muted),
        ),
        const SizedBox(height: DriverSpace.md),
        TextField(
          controller: _controller,
          autofocus: true,
          maxLength: 500,
          maxLines: 3,
          decoration: InputDecoration(labelText: 'السبب', errorText: _error),
        ),
        const SizedBox(height: DriverSpace.sm),
        DestructiveButton(onPressed: _submit, label: 'تأكيد الإلغاء'),
      ],
    ),
  );
}
