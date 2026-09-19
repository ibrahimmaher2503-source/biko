import 'dart:async';

import 'package:app_core/app_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserRealtimeEvents {
  UserRealtimeEvents(
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
        .channel('user-operations-$userId')
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
            if (!_generation.isCurrent(generation)) return;
            try {
              unawaited(
                onEvent(
                  OperationalNotification.fromRealtime(payload.newRecord),
                ),
              );
            } on FormatException {
              // Invalid signals never become navigation or business state.
            }
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
