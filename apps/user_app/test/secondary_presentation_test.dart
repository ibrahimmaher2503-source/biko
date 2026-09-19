import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/orders/order_history_view.dart';
import 'package:user_app/features/orders/order_models.dart';
import 'package:user_app/features/orders/order_providers.dart';
import 'package:user_app/features/profile/profile_model.dart';
import 'package:user_app/features/profile/profile_provider.dart';
import 'package:user_app/features/profile/profile_view.dart';

import 'widget_test.dart' show testApp;

void main() {
  testWidgets('history keeps terminal labels and long routes usable', (
    tester,
  ) async {
    final longAddress =
        'عنوان عربي طويل جدًا في مدينة نصر بجوار الحديقة الدولية وميدان الساعة';
    final orders = [
      for (final status in [
        OrderStatus.completed,
        OrderStatus.cancelled,
        OrderStatus.expired,
      ])
        CustomerOrder(
          id: status.name,
          service: ServiceType.delivery,
          pickup: LocationSelection(
            displayAddress: longAddress,
            latitude: 30.05,
            longitude: 31.33,
          ),
          destination: LocationSelection(
            displayAddress: longAddress,
            latitude: 30.06,
            longitude: 31.34,
          ),
          proposedPrice: 80,
          status: status,
          createdAt: DateTime.utc(2026, 9, 1),
        ),
    ];
    await tester.pumpWidget(
      testApp(
        const OrderHistoryView(),
        overrides: [
          orderHistoryPageProvider.overrideWith(
            (_) async => OrderHistoryPage(orders: orders, nextCursor: null),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('مكتملة'), findsOneWidget);
    expect(find.text('ملغاة'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('منتهية'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('منتهية'), findsOneWidget);
    expect(find.textContaining(longAddress), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Profile constrains long identity lines and opens Arabic editing', (
    tester,
  ) async {
    const name = 'اسم عميل طويل جدًا لا ينبغي أن يكسر بطاقة الحساب';
    const email =
        'a-very-long-customer-identity-address-that-must-stay-readable@example.com';
    await tester.pumpWidget(
      testApp(
        const ProfileView(),
        overrides: [
          profileProvider.overrideWith(
            (_) async => const CustomerProfile(
              fullName: name,
              email: email,
              phone: '01000000000',
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(name), findsOneWidget);
    expect(find.text(email), findsOneWidget);
    expect(find.text('تسجيل الخروج'), findsOneWidget);
    expect(find.byKey(const Key('edit-profile')), findsOneWidget);
    await tester.tap(find.byKey(const Key('edit-profile')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-name')), findsOneWidget);
    expect(find.byKey(const Key('profile-phone')), findsOneWidget);
    expect(find.text('للتواصل فقط، وليس لتسجيل الدخول.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
