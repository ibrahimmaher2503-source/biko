import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/features/orders/order_service.dart';
import 'package:user_app/features/orders/order_models.dart';

const orderHistoryLimit = 30;

final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService(Supabase.instance.client);
});

final activeOrderProvider = FutureProvider<CustomerOrder?>((ref) {
  return ref.watch(orderServiceProvider).loadActiveOrder();
});

final orderHistoryProvider = FutureProvider<List<CustomerOrder>>((ref) {
  return ref.watch(orderHistoryPageProvider.future).then((page) => page.orders);
});

final orderHistoryPageProvider = FutureProvider<OrderHistoryPage>((ref) {
  return ref.watch(orderServiceProvider).loadHistoryPage();
});

final orderDetailsProvider = FutureProvider.autoDispose
    .family<CustomerOrder, String>((ref, orderId) {
      return ref.watch(orderServiceProvider).loadOrder(orderId);
    });
