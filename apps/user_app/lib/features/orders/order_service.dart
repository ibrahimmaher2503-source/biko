import 'package:app_core/app_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/features/orders/order_models.dart';
import 'package:user_app/features/orders/order_rules.dart';

class OrderService {
  OrderService(this._client);

  final SupabaseClient _client;
  final Map<ServiceType, String> _serviceIds = {};
  static const _historyPageSize = 30;

  static const orderColumns = '''
    id,
    pickup_lat,
    pickup_lng,
    pickup_address,
    destination_lat,
    destination_lng,
    destination_address,
    proposed_price,
    agreed_price,
    driver_id,
    status,
    created_at,
    bidding_expires_at,
    cancellation_reason,
    cancellation_type,
    route_distance_meters,
    route_duration_seconds,
    route_polyline,
    suggested_price,
    minimum_customer_price,
    completed_at,
    cancelled_at,
    expired_at,
    service:service_types(code),
    delivery:order_delivery_details(recipient_name,recipient_phone,parcel_weight_kg,declared_value)
  ''';

  String get _customerId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const ReadFailure(ReadFailureKind.auth);
    return id;
  }

  Future<CustomerOrder?> loadActiveOrder() async {
    try {
      final data = await _client
          .from('orders')
          .select(orderColumns)
          .eq('customer_id', _customerId)
          .inFilter('status', const [
            'BIDDING',
            'DRIVER_ASSIGNED',
            'DRIVER_ON_WAY',
            'DRIVER_ARRIVED',
            'IN_PROGRESS',
          ])
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle()
          .timeout(recoveryReadTimeout);
      if (data == null) return null;
      final order = CustomerOrder.fromJson(data);
      if (order.biddingElapsed()) {
        final latest = await expireElapsedOrder(order);
        return isTerminalOrder(latest.status) ? null : latest;
      }
      return order;
    } catch (error) {
      throw classifyReadError(error);
    }
  }

  Future<CustomerOrder> loadOrder(String orderId) async {
    try {
      final data = await _client
          .from('orders')
          .select(orderColumns)
          .eq('customer_id', _customerId)
          .eq('id', orderId)
          .maybeSingle()
          .timeout(recoveryReadTimeout);
      if (data == null) throw const ReadFailure(ReadFailureKind.unavailable);
      return CustomerOrder.fromJson(data);
    } catch (error) {
      throw classifyReadError(error);
    }
  }

  Future<CustomerOrder?> findByCreationIntent(String intentId) async {
    try {
      final data = await _client
          .from('orders')
          .select(orderColumns)
          .eq('customer_id', _customerId)
          .eq('creation_intent_id', intentId)
          .maybeSingle()
          .timeout(recoveryReadTimeout);
      return data == null ? null : CustomerOrder.fromJson(data);
    } catch (error) {
      throw classifyReadError(error);
    }
  }

  Future<List<CustomerOrder>> loadHistory() async =>
      (await loadHistoryPage()).orders;

  Future<OrderHistoryPage> loadHistoryPage({OrderHistoryCursor? after}) async {
    try {
      var query = _client
          .from('orders')
          .select(orderColumns)
          .eq('customer_id', _customerId)
          .inFilter('status', const ['COMPLETED', 'CANCELLED', 'EXPIRED']);
      if (after != null) {
        final timestamp = after.createdAt.toIso8601String();
        query = query.or(
          'created_at.lt.$timestamp,and(created_at.eq.$timestamp,id.lt.${after.id})',
        );
      }
      final data = await query
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .limit(_historyPageSize + 1)
          .timeout(recoveryReadTimeout);
      final orders = (data as List)
          .map((row) => CustomerOrder.fromJson(_asMap(row)!))
          .toList(growable: false);
      final hasMore = orders.length > _historyPageSize;
      final page = hasMore ? orders.take(_historyPageSize).toList() : orders;
      final last = page.isEmpty ? null : page.last;
      return OrderHistoryPage(
        orders: page,
        nextCursor: hasMore && last != null
            ? OrderHistoryCursor(createdAt: last.createdAt, id: last.id)
            : null,
      );
    } catch (error) {
      throw classifyReadError(error);
    }
  }

  Future<List<DriverOffer>> loadOffers(String orderId) async {
    try {
      final data = await _client
          .rpc('get_customer_order_offers', params: {'p_order_id': orderId})
          .timeout(recoveryReadTimeout);
      return (data as List)
          .map((row) => DriverOffer.fromJson(_asMap(row)!))
          .toList(growable: false);
    } catch (error) {
      throw classifyReadError(error);
    }
  }

  Future<DriverSummary?> loadAssignedDriver(String orderId) async {
    try {
      final data = await _client
          .rpc('get_customer_assigned_driver', params: {'p_order_id': orderId})
          .timeout(recoveryReadTimeout);
      final row = _firstRow(data);
      return row == null ? null : DriverSummary.fromJson(row);
    } catch (error) {
      throw classifyReadError(error);
    }
  }

  Future<String?> loadDeliveryConfirmationCode(String orderId) async {
    try {
      final data = await _client
          .rpc(
            'get_delivery_confirmation_code',
            params: {'p_order_id': orderId},
          )
          .timeout(recoveryReadTimeout);
      final code = data?.toString();
      return code != null && RegExp(r'^\d{4}$').hasMatch(code) ? code : null;
    } catch (error) {
      throw classifyReadError(error);
    }
  }

  Future<CustomerOrder> createOrder(OrderDraft draft, String intentId) async {
    final quote = draft.routeQuote;
    if (quote == null) {
      throw const BusinessFailure('احسب المسار والسعر قبل إنشاء الطلب.');
    }
    final serviceTypeId = await _serviceTypeId(draft.service);
    final data = await _client
        .rpc(
          'create_order',
          params: {
            'p_service_type_id': serviceTypeId,
            'p_pickup_lat': quote.pickup.latitude,
            'p_pickup_lng': quote.pickup.longitude,
            'p_pickup_address': draft.pickup.displayAddress,
            'p_destination_lat': quote.destination.latitude,
            'p_destination_lng': quote.destination.longitude,
            'p_destination_address': draft.destination.displayAddress,
            'p_proposed_price': draft.proposedPrice,
            'p_recipient_name': draft.delivery?.recipientName,
            'p_recipient_phone': draft.delivery?.recipientPhone,
            'p_parcel_weight_kg': draft.delivery?.parcelWeightKg,
            'p_declared_value': draft.delivery?.declaredValue,
            'p_creation_intent_id': intentId,
            'p_route_quote_id': quote.id,
          },
        )
        .timeout(mutationWaitTimeout);
    return CustomerOrder.fromJson(
      _decorateRow(_firstRow(data)!, draft.service, draft.delivery),
    );
  }

  Future<RouteQuote> createRouteQuote(
    ServiceType service,
    LocationSelection pickup,
    LocationSelection destination,
  ) async {
    final serviceTypeId = await _serviceTypeId(service);
    try {
      final response = await _client.functions
          .invoke(
            'route-quote',
            body: {
              'service_type_id': serviceTypeId,
              'pickup_lat': pickup.latitude,
              'pickup_lng': pickup.longitude,
              'destination_lat': destination.latitude,
              'destination_lng': destination.longitude,
            },
          )
          .timeout(transportTimeout);
      if (response.status != 200 || response.data is! Map) {
        final message = response.data is Map
            ? (response.data as Map)['error']?.toString()
            : null;
        throw BusinessFailure(
          message == 'Pricing configuration unavailable'
              ? 'إعداد أسعار الخدمة غير متاح بعد.'
              : 'تعذر حساب المسار الآن. حاول مرة أخرى.',
        );
      }
      return RouteQuote.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on BusinessFailure {
      rethrow;
    } catch (_) {
      throw const BusinessFailure('تعذر حساب المسار الآن. حاول مرة أخرى.');
    }
  }

  Future<CustomerOrder> acceptOffer(
    CustomerOrder current,
    String offerId,
  ) async {
    final data = await _client
        .rpc(
          'accept_offer',
          params: {'p_order_id': current.id, 'p_offer_id': offerId},
        )
        .timeout(mutationWaitTimeout);
    return CustomerOrder.fromJson(
      _decorateRow(_firstRow(data)!, current.service, current.delivery),
    );
  }

  Future<CustomerOrder> cancelOrder(
    CustomerOrder current,
    String? reason,
  ) async {
    final data = await _client
        .rpc(
          'cancel_order',
          params: {'p_order_id': current.id, 'p_reason': reason},
        )
        .timeout(mutationWaitTimeout);
    return CustomerOrder.fromJson(
      _decorateRow(_firstRow(data)!, current.service, current.delivery),
    );
  }

  Future<CustomerOrder> expireElapsedOrder(CustomerOrder current) async {
    final data = await _client
        .rpc('expire_customer_order', params: {'p_order_id': current.id})
        .timeout(recoveryReadTimeout);
    return CustomerOrder.fromJson(
      _decorateRow(_firstRow(data)!, current.service, current.delivery),
    );
  }

  Future<String> _serviceTypeId(ServiceType service) async {
    final cached = _serviceIds[service];
    if (cached != null) return cached;
    final data = await _client
        .from('service_types')
        .select('id')
        .eq('code', service.databaseValue)
        .eq('is_enabled', true)
        .single()
        .timeout(recoveryReadTimeout);
    final id = data['id'] as String;
    _serviceIds[service] = id;
    return id;
  }
}

Map<String, dynamic> _decorateRow(
  Map<String, dynamic> row,
  ServiceType service,
  DeliveryDetails? delivery,
) {
  return {
    ...row,
    'service': {'code': service.databaseValue},
    'delivery': delivery == null
        ? null
        : {
            'recipient_name': delivery.recipientName,
            'recipient_phone': delivery.recipientPhone,
            'parcel_weight_kg': delivery.parcelWeightKg,
            'declared_value': delivery.declaredValue,
          },
  };
}

Map<String, dynamic>? _firstRow(dynamic data) {
  if (data is Map) return Map<String, dynamic>.from(data);
  if (data is List && data.isNotEmpty) return _asMap(data.first);
  return null;
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  if (value is List && value.isNotEmpty && value.first is Map) {
    return Map<String, dynamic>.from(value.first as Map);
  }
  return null;
}
