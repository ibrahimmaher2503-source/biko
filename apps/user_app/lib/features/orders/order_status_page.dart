import 'dart:async';

import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/app/user_theme.dart';
import 'package:user_app/core/widgets/feedback_widgets.dart';
import 'package:user_app/features/orders/widgets/assigned_driver_widgets.dart';
import 'package:user_app/features/orders/widgets/order_status_actions.dart';
import 'package:user_app/features/orders/widgets/offer_widgets.dart';
import 'package:user_app/features/orders/order_providers.dart';
import 'package:user_app/features/orders/order_models.dart';
import 'package:user_app/features/orders/customer_order_contact.dart';
import 'package:user_app/features/orders/order_rules.dart';
import 'package:user_app/features/orders/order_tracking.dart';

class OrderStatusPage extends ConsumerStatefulWidget {
  const OrderStatusPage({required this.initialOrder, super.key});

  final CustomerOrder initialOrder;

  @override
  ConsumerState<OrderStatusPage> createState() => _OrderStatusPageState();
}

class _OrderStatusPageState extends ConsumerState<OrderStatusPage> {
  late CustomerOrder _order;
  late final MutationReconciler _reconciler;
  final _cancellationReason = TextEditingController();
  List<DriverOffer> _offers = const [];
  DriverSummary? _driver;
  String? _deliveryCode;
  ReadFailure? _readFailure;
  String? _actionMessage;
  bool _refreshing = false;
  bool _showCancellation = false;

  bool get _actionsBlocked => _reconciler.blocksActions || _refreshing;

  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
    _reconciler = MutationReconciler()..addListener(_reconcilerChanged);
    unawaited(_loadSupportingData());
  }

  @override
  void didUpdateWidget(covariant OrderStatusPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.initialOrder, widget.initialOrder)) {
      _order = widget.initialOrder;
      _offers = const [];
      _driver = null;
      _deliveryCode = null;
      _readFailure = null;
      unawaited(_loadSupportingData());
    }
  }

  void _reconcilerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _reconciler.removeListener(_reconcilerChanged);
    _reconciler.dispose();
    _cancellationReason.dispose();
    super.dispose();
  }

  Future<void> _loadSupportingData() async {
    final generation = ++_supportingDataGeneration;
    // Expiry is checked by the active-order read and the one-shot countdown.
    // Repeated server snapshots must not create a local-clock retry loop.
    if (_order.status == OrderStatus.bidding) {
      await _loadOffers(generation);
    } else if (_order.driverId != null) {
      await _loadDriver(generation);
    }
  }

  int _supportingDataGeneration = 0;

  Future<void> _loadOffers([int? expectedGeneration]) async {
    final generation = expectedGeneration ?? ++_supportingDataGeneration;
    try {
      final offers = await ref.read(orderServiceProvider).loadOffers(_order.id);
      if (mounted &&
          generation == _supportingDataGeneration &&
          _order.status == OrderStatus.bidding) {
        setState(() {
          _offers = offers;
          _readFailure = null;
        });
      }
    } catch (error) {
      if (mounted &&
          generation == _supportingDataGeneration &&
          _order.status == OrderStatus.bidding) {
        setState(() => _readFailure = classifyReadError(error));
      }
    }
  }

  Future<void> _loadDriver([int? expectedGeneration]) async {
    final generation = expectedGeneration ?? ++_supportingDataGeneration;
    try {
      final service = ref.read(orderServiceProvider);
      final shouldLoadCode =
          _order.service == ServiceType.delivery &&
          !isTerminalOrder(_order.status);
      final results = await Future.wait<Object?>([
        service.loadAssignedDriver(_order.id),
        shouldLoadCode
            ? service.loadDeliveryConfirmationCode(_order.id)
            : Future<String?>.value(null),
      ]);
      if (mounted &&
          generation == _supportingDataGeneration &&
          !isTerminalOrder(_order.status) &&
          _order.status != OrderStatus.bidding &&
          _order.driverId != null) {
        setState(() {
          _driver = results[0] as DriverSummary?;
          _deliveryCode = results[1] as String?;
          _readFailure = null;
        });
      }
    } catch (error) {
      if (mounted &&
          generation == _supportingDataGeneration &&
          !isTerminalOrder(_order.status) &&
          _order.status != OrderStatus.bidding &&
          _order.driverId != null) {
        setState(() => _readFailure = classifyReadError(error));
      }
    }
  }

  Future<void> _refresh({bool expireElapsed = false}) async {
    if (_refreshing) return;
    final generation = ++_supportingDataGeneration;
    var stateLoaded = false;
    setState(() {
      _refreshing = true;
      _readFailure = null;
      _actionMessage = null;
    });
    try {
      final service = ref.read(orderServiceProvider);
      var latest = await service.loadOrder(_order.id);
      if (!mounted || generation != _supportingDataGeneration) return;
      if ((expireElapsed || latest.biddingElapsed()) &&
          latest.biddingElapsed()) {
        latest = await service.expireElapsedOrder(latest);
      }
      if (!mounted || generation != _supportingDataGeneration) return;
      // The authoritative state must survive failures in optional detail reads.
      setState(() {
        if (isTerminalOrder(latest.status) ||
            latest.status == OrderStatus.bidding ||
            latest.driverId != _order.driverId) {
          _driver = null;
          _deliveryCode = null;
        }
        _order = latest;
        _offers = const [];
        _showCancellation = false;
      });
      stateLoaded = true;
      List<DriverOffer> offers = const [];
      DriverSummary? driver = _driver;
      String? deliveryCode = _deliveryCode;
      if (latest.status == OrderStatus.bidding) {
        offers = await service.loadOffers(latest.id);
      } else if (!isTerminalOrder(latest.status) &&
          latest.driverId != null &&
          driver == null) {
        driver = await service.loadAssignedDriver(latest.id);
      }
      if (!mounted || generation != _supportingDataGeneration) return;
      if (latest.service == ServiceType.delivery &&
          latest.driverId != null &&
          !isTerminalOrder(latest.status)) {
        deliveryCode = await service.loadDeliveryConfirmationCode(latest.id);
      } else {
        deliveryCode = null;
      }
      if (!mounted || generation != _supportingDataGeneration) return;
      setState(() {
        _offers = offers;
        _driver = driver;
        _deliveryCode = deliveryCode;
        _showCancellation = false;
      });
    } catch (error) {
      if (mounted && generation == _supportingDataGeneration) {
        setState(() => _readFailure = classifyReadError(error));
      }
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
        if (stateLoaded && generation == _supportingDataGeneration) {
          ref.invalidate(activeOrderProvider);
          if (isTerminalOrder(_order.status)) {
            ref.invalidate(orderHistoryProvider);
            ref.invalidate(orderHistoryPageProvider);
          }
        }
      }
    }
  }

  Future<void> _accept(DriverOffer offer) async {
    if (_actionsBlocked) return;
    _supportingDataGeneration++;
    setState(() {
      _actionMessage = null;
      _readFailure = null;
    });
    CustomerOrder? confirmed;
    final service = ref.read(orderServiceProvider);
    await _reconciler.run(
      mutate: () async {
        confirmed = await service.acceptOffer(_order, offer.id);
        _order = confirmed!;
        _driver = offer.toSummary();
        _offers = const [];
      },
      refresh: () async {
        if (confirmed != null) return true;
        final latest = await service.loadOrder(_order.id);
        _order = latest;
        if (latest.driverId != null) {
          _driver = await service.loadAssignedDriver(latest.id);
          _deliveryCode = latest.service == ServiceType.delivery
              ? await service.loadDeliveryConfirmationCode(latest.id)
              : null;
        }
        return latest.status != OrderStatus.bidding;
      },
      revalidateAuth: ref.read(authServiceProvider).revalidateSession,
    );
    if (!mounted) return;
    if (_reconciler.outcome == MutationOutcome.businessFailure) {
      setState(
        () => _actionMessage = customerMutationMessage(_reconciler.error),
      );
      await _loadOffers();
    } else if (_order.status != OrderStatus.bidding) {
      setState(() {});
      ref.invalidate(activeOrderProvider);
      await _loadDriver();
    }
  }

  Future<void> _cancel() async {
    if (_actionsBlocked || !customerCanCancel(_order.status)) return;
    _supportingDataGeneration++;
    final reason = _cancellationReason.text.trim();
    if (cancellationReasonRequired(_order.status) && reason.isEmpty) {
      setState(() => _actionMessage = 'سبب الإلغاء مطلوب في هذه المرحلة.');
      return;
    }
    setState(() {
      _actionMessage = null;
      _readFailure = null;
    });
    CustomerOrder? confirmed;
    final service = ref.read(orderServiceProvider);
    await _reconciler.run(
      mutate: () async {
        confirmed = await service.cancelOrder(
          _order,
          reason.isEmpty ? null : reason,
        );
        _order = confirmed!;
        _offers = const [];
      },
      refresh: () async {
        if (confirmed != null) return true;
        final latest = await service.loadOrder(_order.id);
        _order = latest;
        return latest.status == OrderStatus.cancelled;
      },
      revalidateAuth: ref.read(authServiceProvider).revalidateSession,
    );
    if (!mounted) return;
    if (_reconciler.outcome == MutationOutcome.businessFailure) {
      setState(
        () => _actionMessage = customerMutationMessage(_reconciler.error),
      );
    } else if (_order.status == OrderStatus.cancelled) {
      setState(() => _showCancellation = false);
      ref.invalidate(activeOrderProvider);
      ref.invalidate(orderHistoryProvider);
      ref.invalidate(orderHistoryPageProvider);
    }
  }

  Future<void> _retryMutationRead() async {
    await _reconciler.retryRead();
    if (mounted) {
      // The read completed but proved that the write was not visible. Only
      // this explicit user action unlocks a fresh attempt; no write is replayed.
      if (_reconciler.phase == RecoveryPhase.unavailable &&
          _reconciler.readError == null) {
        _reconciler.resetForSessionChange();
        await _loadSupportingData();
      }
      setState(() {});
      if (_order.status != OrderStatus.bidding) {
        ref.invalidate(activeOrderProvider);
      }
    }
  }

  void _bookAgain() {
    final draft = _order.bookAgainDraft();
    ref.invalidate(activeOrderProvider);
    context.push(
      '/book/${draft.service == ServiceType.ride ? 'ride' : 'delivery'}',
      extra: draft,
    );
  }

  void _returnHome() {
    ref.invalidate(activeOrderProvider);
    ref.invalidate(orderHistoryProvider);
    ref.invalidate(orderHistoryPageProvider);
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final terminal = isTerminalOrder(_order.status);
    final bidding = _order.status == OrderStatus.bidding;
    return Scaffold(
      appBar: AppTopBar(
        title: bidding ? 'العروض' : 'حالة الطلب',
        actions: [
          IconButton(
            tooltip: 'تحديث الحالة',
            onPressed: _actionsBlocked ? null : _refresh,
            icon: _refreshing
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            BikoSpace.md,
            BikoSpace.sm,
            BikoSpace.md,
            BikoSpace.xl,
          ),
          children: [
            Row(
              children: [
                ServiceTypeBadge(code: _order.service.databaseValue),
                const Spacer(),
                StatusBadge(
                  label: orderStatusLabel(_order.status),
                  color: orderStatusColor(context, _order.status),
                ),
              ],
            ),
            const SizedBox(height: BikoSpace.md),
            if (terminal)
              _TerminalSummary(order: _order)
            else
              Card(
                color: bidding ? UserColors.primarySoft : null,
                child: Padding(
                  padding: const EdgeInsets.all(BikoSpace.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        bidding
                            ? 'نبحث عن عروض السائقين'
                            : _activeOrderHeading(_order),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: BikoSpace.md),
                      RouteSummary(
                        pickupAddress: _order.pickup.displayAddress,
                        destinationAddress: _order.destination.displayAddress,
                        compact: bidding,
                      ),
                      const Divider(height: BikoSpace.xl),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              bidding ? 'سعرك المقترح' : 'السعر المتفق عليه',
                            ),
                          ),
                          PriceDisplay(
                            _order.agreedPrice ?? _order.proposedPrice,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            if (bidding) ...[
              const SizedBox(height: BikoSpace.md),
              BiddingCountdown(
                expiresAt: _order.biddingExpiresAt!,
                onElapsed: () => _refresh(expireElapsed: true),
              ),
              const SizedBox(height: BikoSpace.md),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'عروض السائقين (${_offers.length})',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton(
                    onPressed: _actionsBlocked ? null : _refresh,
                    child: const Text('تحديث'),
                  ),
                ],
              ),
              const SizedBox(height: BikoSpace.sm),
              DriverOffersSection(
                offers: _offers,
                disabled: _actionsBlocked,
                onSelect: _accept,
              ),
            ],
            if (!terminal && !bidding && _order.driverId != null) ...[
              const SizedBox(height: BikoSpace.md),
              Text(
                'تحقّق من السائق والدراجة',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: BikoSpace.sm),
              if (_driver == null)
                UserInlineMessage(
                  message:
                      'تعذر تحميل ملخص السائق الآن. حالة الطلب ما زالت محفوظة.',
                  actionLabel: 'إعادة المحاولة',
                  onAction: _loadDriver,
                )
              else
                DriverSummaryCard(driver: _driver!),
              const SizedBox(height: BikoSpace.sm),
              CustomerOrderContactActions(order: _order),
            ],
            if (_order.service == ServiceType.delivery &&
                !isTerminalOrder(_order.status) &&
                _deliveryCode != null) ...[
              const SizedBox(height: BikoSpace.sm),
              DeliveryConfirmationCodeCard(code: _deliveryCode!),
            ],
            if (!terminal && !bidding && _order.driverId != null) ...[
              const SizedBox(height: BikoSpace.md),
              Text(
                'موقع السائق ووقت الوصول',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: BikoSpace.sm),
              AssignedDriverTrackingCard(
                order: _order,
                service: ref.read(orderTrackingServiceProvider),
              ),
            ],
            if (_readFailure != null) ...[
              const SizedBox(height: BikoSpace.md),
              UserInlineMessage(
                message: _readFailure!.message,
                actionLabel: 'إعادة المحاولة',
                onAction: _refresh,
                icon: Icons.cloud_off_outlined,
              ),
            ],
            if (_actionMessage != null) ...[
              const SizedBox(height: BikoSpace.md),
              UserInlineMessage(
                message: _actionMessage!,
                icon: Icons.info_outline_rounded,
              ),
            ],
            if (_reconciler.phase != RecoveryPhase.idle) ...[
              const SizedBox(height: BikoSpace.md),
              ConnectionStateView(
                phase: _reconciler.phase,
                onRetry: _reconciler.phase == RecoveryPhase.unavailable
                    ? _retryMutationRead
                    : null,
              ),
            ],
            if (customerCanCancel(_order.status) && !_showCancellation) ...[
              const SizedBox(height: BikoSpace.lg),
              OutlinedButton.icon(
                key: const Key('show-cancellation'),
                onPressed: _actionsBlocked
                    ? null
                    : () => setState(() => _showCancellation = true),
                icon: const Icon(Icons.close_rounded),
                label: const Text('إلغاء الطلب'),
              ),
            ],
            if (_showCancellation) ...[
              const SizedBox(height: BikoSpace.section),
              CancellationPanel(
                reasonController: _cancellationReason,
                reasonRequired: cancellationReasonRequired(_order.status),
                isLate: const {
                  OrderStatus.driverOnWay,
                  OrderStatus.driverArrived,
                }.contains(_order.status),
                busy: _actionsBlocked,
                onConfirm: _cancel,
                onBack: () => setState(() => _showCancellation = false),
              ),
            ],
            if (_order.status == OrderStatus.inProgress) ...[
              const SizedBox(height: BikoSpace.section),
              UserInlineMessage(
                message: _order.service == ServiceType.delivery
                    ? 'بدأ التوصيل. الإلغاء المباشر غير متاح، وتحتاج الحالات الطارئة إلى الدعم.'
                    : 'بدأت الرحلة. الإلغاء المباشر غير متاح، وتحتاج الحالات الطارئة إلى الدعم.',
                icon: Icons.support_agent_rounded,
              ),
            ],
            if (terminal) ...[
              const SizedBox(height: BikoSpace.lg),
              TerminalActions(
                order: _order,
                onBookAgain: _bookAgain,
                onHome: _returnHome,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _activeOrderHeading(CustomerOrder order) => switch (order.status) {
  OrderStatus.driverAssigned => 'تم اختيار السائق',
  OrderStatus.driverOnWay => 'السائق في الطريق',
  OrderStatus.driverArrived => 'وصل السائق',
  OrderStatus.inProgress =>
    order.service == ServiceType.delivery ? 'التوصيل جارٍ' : 'الرحلة جارية',
  _ => 'حالة الطلب',
};

class _TerminalSummary extends StatelessWidget {
  const _TerminalSummary({required this.order});
  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final color = orderStatusColor(context, order.status);
    final title = switch (order.status) {
      OrderStatus.completed => 'اكتمل طلبك',
      OrderStatus.cancelled => 'تم إلغاء الطلب',
      _ => 'انتهت مهلة الطلب',
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(BikoRadius.large),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BikoSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              switch (order.status) {
                OrderStatus.completed => Icons.check_circle_rounded,
                OrderStatus.cancelled => Icons.cancel_rounded,
                _ => Icons.timer_off_rounded,
              },
              color: color,
              size: 40,
            ),
            const SizedBox(height: BikoSpace.sm),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: BikoSpace.sm),
            RouteSummary(
              pickupAddress: order.pickup.displayAddress,
              destinationAddress: order.destination.displayAddress,
              compact: true,
            ),
            const SizedBox(height: BikoSpace.md),
            Center(
              child: PriceDisplay(
                order.agreedPrice ?? order.proposedPrice,
                label: order.status == OrderStatus.completed
                    ? 'المبلغ النقدي'
                    : 'السعر السابق',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
