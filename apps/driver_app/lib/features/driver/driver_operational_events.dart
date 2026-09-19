import 'dart:async';

import 'package:app_core/app_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum DriverOperationalResource {
  activeOrder,
  requests,
  waitingOffers,
  history,
  order,
  offer,
  verification,
}

Set<DriverOperationalResource> driverResourcesFor(
  OperationalNotification event,
) {
  if (event.type == 'NEW_WORK') return {DriverOperationalResource.requests};
  if (event.targetType == 'PROFILE') {
    return {DriverOperationalResource.verification};
  }
  return {
    DriverOperationalResource.activeOrder,
    if (event.orderId != null) ...{
      DriverOperationalResource.order,
      DriverOperationalResource.offer,
    },
    if (event.type == 'OFFER_SELECTED' || event.type == 'OFFER_CLOSED')
      DriverOperationalResource.waitingOffers,
    if (const {'COMPLETED', 'CANCELLED', 'EXPIRED'}.contains(event.type))
      DriverOperationalResource.history,
  };
}

class DriverOperationalEvents {
  DriverOperationalEvents(
    this._client, {
    required this.onEvent,
    required this.onRecovery,
  });

  final SupabaseClient _client;
  final Future<void> Function(OperationalNotification event) onEvent;
  final Future<void> Function() onRecovery;
  RealtimeChannel? _channel;
  bool _subscribed = false;
  final _generation = OperationalSubscriptionGeneration();

  Future<void> start(String userId) async {
    final generation = _generation.begin();
    await _removeCurrent();
    if (!_generation.isCurrent(generation)) return;
    _channel = _client
        .channel('driver-operations-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notification_outbox',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'target_user_id',
            value: userId,
          ),
          callback: (payload) {
            if (_generation.isCurrent(generation)) {
              _readNotification(payload.newRecord);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'driver_work_signals',
          callback: (payload) {
            if (!_generation.isCurrent(generation)) return;
            final row = payload.newRecord;
            final id = row['id']?.toString();
            final orderId = row['order_id']?.toString();
            if (id == null || orderId == null) return;
            _readNotification({
              'id': id,
              'event_type': 'NEW_WORK',
              'target_type': 'REQUESTS',
              'order_id': orderId,
              'title': 'طلب جديد قريب',
              'body': 'قد يوجد طلب مناسب بالقرب منك.',
            });
          },
        )
        .subscribe((status, _) {
          if (!_generation.isCurrent(generation)) return;
          if (status == RealtimeSubscribeStatus.subscribed) {
            if (!_subscribed) unawaited(onRecovery());
            _subscribed = true;
          } else {
            _subscribed = false;
          }
        });
  }

  void _readNotification(Map<String, dynamic> row) {
    try {
      unawaited(onEvent(OperationalNotification.fromRealtime(row)));
    } on FormatException {
      // Invalid signals never become navigation or business state.
    }
  }

  Future<void> stop() async {
    _generation.cancel();
    await _removeCurrent();
  }

  Future<void> _removeCurrent() async {
    _subscribed = false;
    final channel = _channel;
    _channel = null;
    if (channel != null) await _client.removeChannel(channel);
  }
}
