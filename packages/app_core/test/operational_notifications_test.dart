import 'package:app_core/app_core.dart';
import 'package:flutter_test/flutter_test.dart';

const eventId = '11111111-1111-4111-8111-111111111111';
const orderId = '22222222-2222-4222-8222-222222222222';

void main() {
  test('notification identity and safe target parse', () {
    final event = OperationalNotification.fromPush({
      'notification_id': eventId,
      'event_type': 'DRIVER_ON_WAY',
      'target_type': 'ORDER',
      'order_id': orderId,
      'title': 'تحديث',
      'body': 'الحالة الحالية متاحة.',
    });

    expect(event.id, eventId);
    expect(event.orderId, orderId);
    expect(OperationalNotification.tryPayload(event.payload)?.id, eventId);
    expect(
      OperationalNotification.tryPush({
        'notification_id': eventId,
        'event_type': 'DRIVER_ON_WAY',
        'target_type': 'ORDER',
        'order_id': 'not-a-uuid',
      }),
      isNull,
    );
  });

  test('Realtime and Push duplicate identity is accepted once', () {
    final dedupe = OperationalEventDedupe(capacity: 2);

    expect(dedupe.take(eventId), isTrue);
    expect(dedupe.take(eventId), isFalse);
    expect(dedupe.take('33333333-3333-4333-8333-333333333333'), isTrue);
    expect(dedupe.take('44444444-4444-4444-8444-444444444444'), isTrue);
    expect(dedupe.take(eventId), isTrue, reason: 'bounded oldest eviction');
  });

  test('session change invalidates an older subscription generation', () {
    final generation = OperationalSubscriptionGeneration();
    final firstSession = generation.begin();
    final nextSession = generation.begin();

    expect(generation.isCurrent(firstSession), isFalse);
    expect(generation.isCurrent(nextSession), isTrue);
    generation.cancel();
    expect(generation.isCurrent(nextSession), isFalse);
  });
}
