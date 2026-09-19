part of '../driver_screens.dart';

class DriverHomeScreen extends ConsumerWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(driverDashboardProvider);
    return DriverShell(
      selectedIndex: 0,
      title: 'بيكو للسائق',
      child: dashboard.when(
        loading: () => const DriverLoadingState(),
        error: (error, _) => DriverErrorState(
          message: driverErrorMessage(error),
          onRetry: () => ref.invalidate(driverDashboardProvider),
        ),
        data: (data) => _HomeContent(data: data),
      ),
    );
  }
}

class _HomeContent extends ConsumerStatefulWidget {
  const _HomeContent({required this.data});

  final DriverDashboardData data;

  @override
  ConsumerState<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends ConsumerState<_HomeContent> {
  bool _availabilityBusy = false;
  bool _locationReady = false;
  late final DriverForegroundLocation _location;

  @override
  void initState() {
    super.initState();
    _location = DriverForegroundLocation(
      ref.read(driverServiceProvider),
      onError: _showLocationError,
    );
    _syncLocation(null, widget.data);
  }

  @override
  void didUpdateWidget(covariant _HomeContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncLocation(oldWidget.data, widget.data);
  }

  void _syncLocation(DriverDashboardData? oldData, DriverDashboardData data) {
    final shouldTrack =
        data.activeOrder != null || data.account?.isOnline == true;
    final activeTrip = data.activeOrder != null;
    final wasTracking =
        oldData?.activeOrder != null || oldData?.account?.isOnline == true;
    final wasActiveTrip = oldData?.activeOrder != null;
    if (oldData != null &&
        shouldTrack == wasTracking &&
        activeTrip == wasActiveTrip) {
      return;
    }
    final operation = shouldTrack
        ? _location.start(activeTrip: activeTrip)
        : _location.stop();
    unawaited(
      operation
          .then((_) {
            if (mounted && shouldTrack) setState(() => _locationReady = true);
          })
          .catchError((Object error) {
            if (mounted) setState(() => _locationReady = false);
            _showLocationError(driverLocationErrorMessage(error));
          }),
    );
  }

  void _showLocationError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    unawaited(_location.stop());
    super.dispose();
  }

  Future<void> _refresh() async {
    ref
      ..invalidate(driverAccountProvider)
      ..invalidate(driverActiveOrderProvider)
      ..invalidate(driverRequestsProvider)
      ..invalidate(driverWaitingOffersProvider)
      ..invalidate(driverVerificationProvider);
    try {
      await ref.read(driverDashboardProvider.future);
    } catch (_) {
      /* Render typed provider error. */
    }
  }

  Future<void> _setOnline(bool value) async {
    if (_availabilityBusy) return;
    setState(() => _availabilityBusy = true);
    var applied = false;
    try {
      if (!value) await _location.pauseForOffline();
      if (value) await _location.prepareForOnline();
      await runDriverMutation(
        ref,
        () async {
          if (value) await _location.uploadNow();
          await ref.read(driverServiceProvider).setOnline(value);
        },
        refresh: DriverMutationRefresh.availability,
        isApplied: (data, _, _) => data.account?.isOnline == value,
      );
      applied =
          ref.read(driverDashboardProvider).asData?.value.account?.isOnline ==
          value;
      if (applied) {
        if (value) await _location.start(uploadFirst: false);
      }
    } finally {
      if (!applied) {
        if (value) {
          await _location.pauseForOffline();
        } else {
          await _location.resumeAfterFailedOffline();
        }
      }
      if (mounted) setState(() => _availabilityBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final account = data.account;
    if (account == null) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 100),
            DriverEmptyState(
              icon: Icons.badge_outlined,
              title: 'لا يوجد حساب سائق',
              description: 'قدّم بياناتك لبدء مراجعة طلب الانضمام كسائق مستقل.',
              actionLabel: 'تقديم طلب انضمام',
              onAction: () => context.go('/onboarding'),
            ),
          ],
        ),
      );
    }

    final hasActiveOrder = data.activeOrder != null;
    final earningsState = ref.watch(driverEarningsProvider);
    final verificationState = ref.watch(driverVerificationProvider);
    final verification = verificationState.asData?.value;
    final verificationLoading = verificationState.isLoading;
    final waitingOffersState = hasActiveOrder
        ? null
        : ref.watch(driverWaitingOffersProvider);
    final requestsState = hasActiveOrder || !account.isOnline
        ? null
        : ref.watch(driverRequestsProvider);
    final canToggle =
        account.canGoOnline &&
        (account.isOnline || (verification?.readyForNewWork ?? false)) &&
        !hasActiveOrder &&
        !_availabilityBusy &&
        !ref.watch(driverMutationProvider).blocksActions;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          DriverSpace.md,
          DriverSpace.sm,
          DriverSpace.md,
          DriverSpace.xl,
        ),
        children: [
          if (data.activeOrder case final order?) ...[
            const _SectionTitle('الرحلة النشطة'),
            const SizedBox(height: DriverSpace.sm),
            _ActiveOrderCard(
              key: const Key('active-order-priority'),
              order: order,
            ),
            if (order.hasRouteCoordinates) ...[
              const SizedBox(height: DriverSpace.sm),
              DriverRouteMap(
                key: const Key('home-route-map'),
                order: order,
                currentLocationEnabled: _locationReady,
              ),
            ],
            const SizedBox(height: DriverSpace.lg),
          ],
          earningsState.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (earnings) => _HomeTodaySummary(data: earnings),
          ),
          const SizedBox(height: DriverSpace.lg),
          DriverCard(
            key: const Key('online-status-card'),
            color: account.isOnline
                ? DriverColors.primary.withValues(alpha: .06)
                : null,
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        (account.isOnline
                                ? DriverColors.success
                                : DriverColors.muted)
                            .withValues(alpha: .12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    account.isOnline
                        ? Icons.wifi_tethering_rounded
                        : Icons.pause_circle_outline_rounded,
                    color: account.isOnline
                        ? DriverColors.success
                        : DriverColors.muted,
                  ),
                ),
                const SizedBox(width: DriverSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _availabilityTitle(
                          account,
                          busy: _availabilityBusy,
                          verificationLoading: verificationLoading,
                        ),
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: DriverSpace.xs),
                      Text(
                        hasActiveOrder
                            ? 'لديك رحلة نشطة. استقبال الطلبات الجديدة متوقف.'
                            : _availabilityDescription(
                                account,
                                busy: _availabilityBusy,
                                verificationLoading: verificationLoading,
                                verification: verification,
                              ),
                        style: const TextStyle(color: DriverColors.muted),
                      ),
                      if (!hasActiveOrder &&
                          !account.isOnline &&
                          verification?.readyForNewWork == false)
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton(
                            onPressed: () => context.push('/verification'),
                            child: const Text('استكمال التحقق'),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_availabilityBusy)
                  const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Switch.adaptive(
                    value: account.isOnline,
                    onChanged: canToggle ? _setOnline : null,
                  ),
              ],
            ),
          ),
          if (!account.canGoOnline) ...[
            const SizedBox(height: DriverSpace.md),
            DriverCard(
              color: DriverColors.warning.withValues(alpha: .08),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: DriverColors.warning),
                  const SizedBox(width: DriverSpace.sm),
                  Expanded(
                    child: Text(
                      'حالة الحساب: ${driverStatusLabel(account.status)}. لا يمكن استقبال الطلبات الآن.',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!hasActiveOrder &&
              (waitingOffersState?.hasValue == true ||
                  requestsState?.hasValue == true)) ...[
            const SizedBox(height: DriverSpace.lg),
            DriverCard(
              key: const Key('request-summary-card'),
              child: Row(
                children: [
                  if (requestsState?.asData?.value case final requests?)
                    Expanded(
                      child: _HomeSummaryValue(
                        label: 'طلبات متاحة',
                        value: requests.length.toString(),
                      ),
                    ),
                  if (requestsState?.asData?.value != null &&
                      waitingOffersState?.asData?.value != null)
                    const VerticalDivider(width: DriverSpace.lg),
                  if (waitingOffersState?.asData?.value case final offers?)
                    Expanded(
                      child: _HomeSummaryValue(
                        label: 'عروض قيد الانتظار',
                        value: offers.length.toString(),
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (!hasActiveOrder) ...[
            const SizedBox(height: DriverSpace.lg),
            const _SectionTitle('العروض قيد الانتظار'),
            waitingOffersState!.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => DriverErrorState(
                message: driverErrorMessage(error),
                onRetry: () => ref.invalidate(driverWaitingOffersProvider),
              ),
              data: (offers) => WaitingOffersList(offers: offers),
            ),
          ],
          const SizedBox(height: DriverSpace.lg),
          Row(
            children: [
              const Expanded(child: _SectionTitle('الطلبات المتاحة')),
              IconButton(
                tooltip: 'تحديث',
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: DriverSpace.sm),
          if (hasActiveOrder)
            const Text('استقبال الطلبات متوقف حتى انتهاء الرحلة الحالية.')
          else if (!account.isOnline)
            const DriverEmptyState(
              icon: Icons.power_settings_new_rounded,
              title: 'فعّل الاتصال لاستقبال الطلبات',
              description: 'لن تظهر طلبات جديدة وأنت غير متصل.',
            )
          else
            requestsState!.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => DriverErrorState(
                message: driverErrorMessage(error),
                onRetry: () => ref.invalidate(driverRequestsProvider),
              ),
              data: (orders) => orders.isEmpty
                  ? const DriverEmptyState(
                      icon: Icons.inbox_outlined,
                      title: 'لا توجد طلبات مناسبة الآن',
                      description: 'اسحب للأسفل أو استخدم زر التحديث لاحقًا.',
                    )
                  : Column(
                      children: [
                        for (final order in orders) ...[
                          _RequestCard(order: order),
                          const SizedBox(height: DriverSpace.md),
                        ],
                      ],
                    ),
            ),
        ],
      ),
    );
  }
}

class DriverHomeDaySummary {
  const DriverHomeDaySummary({
    required this.trips,
    required this.earnings,
    required this.earningsKnown,
  });

  final int trips;
  final double earnings;
  final bool earningsKnown;
}

DriverHomeDaySummary driverHomeTodaySummary(
  DriverEarningsData data,
  DateTime today,
) {
  final entries = data.entries.where(
    (entry) => DateUtils.isSameDay(entry.completedAt, today),
  );
  return DriverHomeDaySummary(
    trips: entries.length,
    earnings: entries.fold<double>(
      0,
      (sum, entry) =>
          sum +
          (data.driverType == DriverType.independent
              ? (entry.driverNet ?? 0)
              : entry.grossFare),
    ),
    earningsKnown:
        data.driverType == DriverType.officeDriver ||
        entries.every((entry) => entry.driverNet != null),
  );
}

class _HomeTodaySummary extends StatelessWidget {
  const _HomeTodaySummary({required this.data});

  final DriverEarningsData data;

  @override
  Widget build(BuildContext context) {
    final summary = driverHomeTodaySummary(data, DateTime.now());
    return DriverCard(
      key: const Key('today-summary-card'),
      child: Row(
        children: [
          Expanded(
            child: _HomeSummaryValue(
              label: 'رحلات اليوم',
              value: summary.trips.toString(),
            ),
          ),
          const VerticalDivider(width: DriverSpace.lg),
          Expanded(
            child: summary.earningsKnown
                ? PriceDisplay(
                    summary.earnings,
                    compact: true,
                    label: data.driverType == DriverType.independent
                        ? 'صافي اليوم'
                        : 'قيمة رحلات اليوم',
                  )
                : const _HomeSummaryValue(
                    label: 'صافي اليوم',
                    value: 'غير محسوب',
                  ),
          ),
        ],
      ),
    );
  }
}

String _availabilityReason(DriverAccount account) => switch (account.status) {
  DriverStatus.active => 'فعّل الاتصال لاستقبال الطلبات المناسبة.',
  DriverStatus.pending => 'طلبك قيد المراجعة.',
  DriverStatus.suspended => 'الحساب موقوف مؤقتًا.',
  DriverStatus.rejected => 'تعذر اعتماد حساب السائق.',
};

String _availabilityTitle(
  DriverAccount account, {
  required bool busy,
  required bool verificationLoading,
}) {
  if (busy) {
    return account.isOnline ? 'جاري إيقاف الاتصال' : 'جاري تفعيل الاتصال';
  }
  if (!account.isOnline && verificationLoading && account.canGoOnline) {
    return 'جاري التحقق من الجاهزية';
  }
  return account.isOnline ? 'أنت متصل' : 'أنت غير متصل';
}

String _availabilityDescription(
  DriverAccount account, {
  required bool busy,
  required bool verificationLoading,
  required DriverVerificationOverview? verification,
}) {
  if (busy) return 'نحدّث حالة اتصالك الآن.';
  if (!account.isOnline && verificationLoading && account.canGoOnline) {
    return 'نتحقق من المستندات والجاهزية قبل التفعيل.';
  }
  if (!account.isOnline && verification?.readyForNewWork == false) {
    return verification!.safetyReason ?? 'أكمل التحقق لاستقبال طلبات جديدة.';
  }
  return _availabilityReason(account);
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
  );
}

class _RequestCard extends ConsumerWidget {
  const _RequestCard({required this.order});

  final DriverOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metadata = <String>[
      if (order.driverDistanceMeters case final distance?)
        'يبعد عنك ${_formatDistance(distance)}',
      if (order.routeDistanceMeters case final distance?)
        'المسافة ${_formatDistance(distance)}',
      if (order.routeDurationSeconds case final seconds? when seconds > 0)
        'حوالي ${(seconds / 60).ceil()} دقيقة',
    ];
    return DriverCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ServiceTypeBadge(code: order.serviceCode),
              const Spacer(),
              PriceDisplay(order.proposedPrice, compact: true),
            ],
          ),
          if (order.biddingDeadline case final deadline?) ...[
            const SizedBox(height: DriverSpace.md),
            BiddingCountdown(
              deadline: deadline,
              onExpired: () => ref.invalidate(driverRequestsProvider),
            ),
          ],
          const SizedBox(height: DriverSpace.lg),
          RouteSummary(
            pickupAddress: order.pickupAddress,
            destinationAddress: order.destinationAddress,
          ),
          if (metadata.isNotEmpty) ...[
            const SizedBox(height: DriverSpace.md),
            Wrap(
              spacing: DriverSpace.sm,
              runSpacing: DriverSpace.xs,
              children: [
                for (final value in metadata)
                  Text(
                    value,
                    style: const TextStyle(color: DriverColors.muted),
                  ),
              ],
            ),
          ],
          const SizedBox(height: DriverSpace.lg),
          FilledButton(
            onPressed: () => context.push('/request/${order.id}'),
            child: const Text('عرض التفاصيل'),
          ),
        ],
      ),
    );
  }
}

class _HomeSummaryValue extends StatelessWidget {
  const _HomeSummaryValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: DriverSpace.xs),
      Text(label, style: const TextStyle(color: DriverColors.muted)),
    ],
  );
}

String _formatDistance(int meters) => meters < 1000
    ? '$meters م'
    : '${(meters / 1000).toStringAsFixed(meters % 1000 == 0 ? 0 : 1)} كم';

class _ActiveOrderCard extends StatelessWidget {
  const _ActiveOrderCard({required this.order, super.key});

  final DriverOrder order;

  @override
  Widget build(BuildContext context) => DriverCard(
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
            PriceDisplay(order.displayPrice, compact: true),
          ],
        ),
        const SizedBox(height: DriverSpace.md),
        Text(
          '${order.pickupAddress} ← ${order.destinationAddress}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: DriverSpace.md),
        FilledButton.icon(
          onPressed: () => context.push('/active-order/${order.id}'),
          icon: const Icon(Icons.navigation_rounded),
          label: Text(order.nextAction?.label ?? 'فتح الرحلة'),
        ),
      ],
    ),
  );
}

class WaitingOffersList extends ConsumerStatefulWidget {
  const WaitingOffersList({required this.offers, super.key});
  final List<DriverOffer> offers;
  @override
  ConsumerState<WaitingOffersList> createState() => _WaitingOffersListState();
}

class _WaitingOffersListState extends ConsumerState<WaitingOffersList> {
  final List<DriverOffer> _more = [];
  final WaitingOffersGeneration _generation = WaitingOffersGeneration();
  bool _loading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void didUpdateWidget(covariant WaitingOffersList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.offers, widget.offers)) {
      _generation.reset();
      _more.clear();
      _hasMore = true;
      _loading = false;
      _error = null;
    }
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    final generation = _generation.capture();
    final current = [...widget.offers, ..._more];
    if (current.isEmpty || current.last.createdAt == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref
          .read(driverServiceProvider)
          .loadWaitingOffers(after: current.last);
      if (!mounted || !_generation.accepts(generation)) return;
      setState(() {
        final ids = {
          ...widget.offers.map((o) => o.id),
          ..._more.map((o) => o.id),
        };
        _more.addAll(page.where((o) => ids.add(o.id)));
        _hasMore = page.length == 50;
      });
    } catch (error) {
      if (mounted && _generation.accepts(generation)) {
        setState(() => _error = driverErrorMessage(error));
      }
    } finally {
      if (mounted && _generation.accepts(generation)) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final offer in [...widget.offers, ..._more])
        Padding(
          key: ValueKey(offer.id),
          padding: const EdgeInsets.only(top: 8),
          child: DriverCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'طلب ${offer.orderId}',
                  style: const TextStyle(color: DriverColors.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${offer.pickupAddress} ← ${offer.destinationAddress}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                PriceDisplay(offer.price, compact: true),
                TextButton(
                  onPressed: () => context.push('/waiting/${offer.orderId}'),
                  child: const Text('عرض الملخص أو سحب العرض'),
                ),
              ],
            ),
          ),
        ),
      if (_error != null) Text(_error!),
      if (widget.offers.length == 50 && _hasMore)
        TextButton(
          onPressed: _loading ? null : _loadMore,
          child: Text(_loading ? 'جاري التحميل...' : 'عرض المزيد'),
        ),
    ],
  );
}
