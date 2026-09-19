import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/app/user_shell.dart';
import 'package:user_app/features/onboarding/user_auth_entry.dart';
import 'package:user_app/features/orders/order_models.dart';
import 'package:user_app/features/orders/create_order_page.dart';
import 'package:user_app/features/orders/order_details_page.dart';

GoRouter createUserRouter({
  required AuthService authService,
  required Listenable refreshListenable,
}) {
  return createAuthRouter(
    authService: authService,
    refreshListenable: refreshListenable,
    authBuilder: (_) => const UserAuthEntry(),
    homeBuilder: (_) => const UserRootPage(),
    authenticatedRoutes: [
      GoRoute(
        path: '/orders/:id',
        builder: (context, state) =>
            OrderDetailsPage(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/book/:service',
        builder: (context, state) => CreateOrderPage(
          service: state.pathParameters['service'] == 'delivery'
              ? ServiceType.delivery
              : ServiceType.ride,
          prefill: state.extra is OrderDraft
              ? state.extra! as OrderDraft
              : null,
        ),
      ),
    ],
  );
}
