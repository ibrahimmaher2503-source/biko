import 'dart:async';

import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/app/user_theme.dart';
import 'package:user_app/features/orders/order_models.dart';

final orderTrackingServiceProvider = Provider<OrderTrackingService>(
  (ref) => OrderTrackingService(Supabase.instance.client),
);

class OrderTracking {
  const OrderTracking({
    required this.latitude,
    required this.longitude,
    required this.locationUpdatedAt,
    required this.isStale,
    this.headingDegrees,
    this.etaSeconds,
    this.etaUpdatedAt,
  });

  factory OrderTracking.fromJson(Map<String, dynamic> json) => OrderTracking(
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    headingDegrees: (json['heading_degrees'] as num?)?.toDouble(),
    locationUpdatedAt: DateTime.parse(
      json['driver_location_updated_at'] as String,
    ).toUtc(),
    etaSeconds: (json['eta_seconds'] as num?)?.toInt(),
    etaUpdatedAt: json['eta_updated_at'] == null
        ? null
        : DateTime.parse(json['eta_updated_at'] as String).toUtc(),
    isStale: json['is_stale'] == true,
  );

  final double latitude;
  final double longitude;
  final double? headingDegrees;
  final DateTime locationUpdatedAt;
  final int? etaSeconds;
  final DateTime? etaUpdatedAt;
  final bool isStale;
}

bool isTrackingStale(OrderTracking tracking, {DateTime? now}) =>
    tracking.isStale ||
    (now ?? DateTime.now()).toUtc().difference(tracking.locationUpdatedAt) >=
        const Duration(seconds: 120);

bool hasFreshEta(OrderTracking tracking, {DateTime? now}) =>
    tracking.etaSeconds != null &&
    tracking.etaUpdatedAt != null &&
    (now ?? DateTime.now()).toUtc().difference(tracking.etaUpdatedAt!) <
        const Duration(seconds: 60);

class OrderTrackingRequestGuard {
  int _generation = 0;
  int begin() => ++_generation;
  void cancel() => ++_generation;
  bool isCurrent(int value) => value == _generation;
}

class OrderTrackingService {
  OrderTrackingService(this.client);
  final SupabaseClient client;

  Future<OrderTracking?> load(String orderId) async {
    final data = await client
        .rpc('get_customer_order_tracking', params: {'p_order_id': orderId})
        .timeout(recoveryReadTimeout);
    final row = data is List && data.isNotEmpty && data.first is Map
        ? Map<String, dynamic>.from(data.first as Map)
        : null;
    return row == null ? null : OrderTracking.fromJson(row);
  }

  Future<OrderTracking?> refreshEta(String orderId) async {
    final response = await client.functions
        .invoke('customer-order-eta', body: {'order_id': orderId})
        .timeout(transportTimeout);
    if (response.status != 200 || response.data is! Map) return null;
    return OrderTracking.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}

class AssignedDriverTrackingCard extends StatefulWidget {
  const AssignedDriverTrackingCard({
    required this.order,
    required this.service,
    super.key,
  });

  final CustomerOrder order;
  final OrderTrackingService service;

  @override
  State<AssignedDriverTrackingCard> createState() =>
      _AssignedDriverTrackingCardState();
}

class _AssignedDriverTrackingCardState extends State<AssignedDriverTrackingCard>
    with WidgetsBindingObserver {
  RealtimeChannel? _channel;
  Timer? _staleTimer;
  GoogleMapController? _map;
  OrderTracking? _tracking;
  bool _loading = true;
  bool _foreground = true;
  DateTime? _lastEtaRequest;
  final _requestGuard = OrderTrackingRequestGuard();
  String? _sessionUserId;
  int _loadSequence = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void didUpdateWidget(covariant AssignedDriverTrackingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.id != widget.order.id ||
        oldWidget.order.status != widget.order.status) {
      unawaited(_restart());
      _tracking = null;
      _loading = true;
      _lastEtaRequest = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (_foreground == foreground) return;
    _foreground = foreground;
    if (foreground) {
      _start();
    } else {
      unawaited(_stop());
    }
  }

  Future<void> _start() async {
    if (!_foreground || !mounted || _channel != null) return;
    final generation = _requestGuard.begin();
    _sessionUserId = widget.service.client.auth.currentUser?.id;
    if (!mounted ||
        !_foreground ||
        _channel != null ||
        !_requestGuard.isCurrent(generation))
      return;
    if (widget.service.client.auth.currentSession == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    _channel = widget.service.client
        .channel('order-tracking-${widget.order.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'order_driver_tracking',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'order_id',
            value: widget.order.id,
          ),
          callback: (_) => unawaited(_load(generation)),
        )
        .subscribe((status, _) {
          if (status == RealtimeSubscribeStatus.subscribed &&
              _requestGuard.isCurrent(generation)) {
            unawaited(_load(generation));
          } else if (status == RealtimeSubscribeStatus.channelError ||
              status == RealtimeSubscribeStatus.timedOut) {
            if (mounted && _requestGuard.isCurrent(generation)) {
              setState(() => _loading = false);
            }
          }
        });
    _staleTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _restart() async {
    await _stop();
    if (mounted && _foreground) await _start();
  }

  Future<void> _stop() async {
    _requestGuard.cancel();
    _sessionUserId = null;
    _staleTimer?.cancel();
    _staleTimer = null;
    final channel = _channel;
    _channel = null;
    _map = null;
    if (channel != null) await widget.service.client.removeChannel(channel);
  }

  Future<void> _load(int generation) async {
    final sequence = ++_loadSequence;
    try {
      final tracking = await widget.service.load(widget.order.id);
      if (!mounted ||
          !_foreground ||
          !_requestGuard.isCurrent(generation) ||
          sequence != _loadSequence ||
          widget.service.client.auth.currentUser?.id != _sessionUserId)
        return;
      setState(() {
        _tracking = tracking;
        _loading = false;
      });
      if (tracking != null) {
        unawaited(_moveMap(tracking));
      }
      final now = DateTime.now();
      if (tracking != null &&
          !isTrackingStale(tracking) &&
          (_lastEtaRequest == null ||
              now.difference(_lastEtaRequest!) >=
                  const Duration(seconds: 30))) {
        _lastEtaRequest = now;
        final eta = await widget.service.refreshEta(widget.order.id);
        if (mounted &&
            _foreground &&
            _requestGuard.isCurrent(generation) &&
            sequence == _loadSequence &&
            widget.service.client.auth.currentUser?.id == _sessionUserId &&
            eta != null)
          setState(() => _tracking = eta);
      }
    } catch (_) {
      if (mounted &&
          _foreground &&
          _requestGuard.isCurrent(generation) &&
          sequence == _loadSequence) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_stop());
    super.dispose();
  }

  Future<void> _moveMap(OrderTracking tracking) async {
    try {
      await _map?.animateCamera(
        CameraUpdate.newLatLng(LatLng(tracking.latitude, tracking.longitude)),
      );
    } catch (_) {
      // A stale map controller is not tracking state.
    }
  }

  @override
  Widget build(BuildContext context) {
    final tracking = _tracking;
    if (_loading)
      return const SizedBox(
        height: 72,
        child: Center(child: CircularProgressIndicator()),
      );
    if (tracking == null || isTrackingStale(tracking)) {
      return const _TrackingMessage(
        'موقع السائق غير متاح الآن. سنحدّث الخريطة عند وصول موقع جديد.',
      );
    }
    final driver = LatLng(tracking.latitude, tracking.longitude);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(BikoRadius.large),
          child: SizedBox(
            height: 220,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: driver, zoom: 14),
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              markers: {
                Marker(
                  markerId: const MarkerId('driver'),
                  position: driver,
                  rotation: tracking.headingDegrees ?? 0,
                  flat: tracking.headingDegrees != null,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed,
                  ),
                ),
                Marker(
                  markerId: const MarkerId('pickup'),
                  position: LatLng(
                    widget.order.pickup.latitude,
                    widget.order.pickup.longitude,
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  ),
                ),
                Marker(
                  markerId: const MarkerId('destination'),
                  position: LatLng(
                    widget.order.destination.latitude,
                    widget.order.destination.longitude,
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure,
                  ),
                ),
              },
              onMapCreated: (controller) {
                _map = controller;
                unawaited(
                  controller.animateCamera(CameraUpdate.newLatLng(driver)),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: BikoSpace.sm),
        _TrackingMessage(_etaLabel(widget.order, tracking)),
      ],
    );
  }
}

String _etaLabel(CustomerOrder order, OrderTracking tracking) {
  if (!hasFreshEta(tracking)) return 'وقت الوصول غير متاح الآن.';
  if (tracking.etaSeconds == 0) {
    return order.status == OrderStatus.driverArrived
        ? 'السائق وصل إلى نقطة الاستلام.'
        : 'وقت الوصول غير متاح الآن.';
  }
  final minutes = (tracking.etaSeconds! / 60).ceil();
  final place = order.status == OrderStatus.inProgress
      ? 'الوجهة'
      : 'نقطة الاستلام';
  return 'الوصول إلى $place خلال نحو $minutes دقيقة.';
}

class _TrackingMessage extends StatelessWidget {
  const _TrackingMessage(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('assigned-driver-tracking-message'),
    padding: const EdgeInsets.all(BikoSpace.sm),
    decoration: BoxDecoration(
      color: UserColors.primarySoft,
      borderRadius: BorderRadius.circular(BikoRadius.medium),
    ),
    child: Text(message),
  );
}
