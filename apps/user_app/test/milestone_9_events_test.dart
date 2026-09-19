import 'package:app_core/app_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/notifications/notification_routing.dart';

OperationalNotification event(String type) => OperationalNotification(
  id: '11111111-1111-4111-8111-111111111111',
  type: type,
  targetType: 'ORDER',
  orderId: '22222222-2222-4222-8222-222222222222',
  title: 'تحديث',
  body: 'الحالة الحالية متاحة.',
);

void main() {
  test(
    'new offer and lifecycle signals refresh authoritative active order',
    () {
      expect(userResourcesFor(event('NEW_OFFER')), {
        UserOperationalResource.activeOrder,
      });
      expect(userResourcesFor(event('DRIVER_ASSIGNED')), {
        UserOperationalResource.activeOrder,
      });
    },
  );

  test('terminal signal also invalidates bounded history', () {
    expect(userResourcesFor(event('CANCELLED')), {
      UserOperationalResource.activeOrder,
      UserOperationalResource.history,
    });
  });
}
