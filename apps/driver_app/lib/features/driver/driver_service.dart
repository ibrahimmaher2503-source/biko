import 'dart:typed_data';

import 'package:app_core/app_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'driver_models.dart';

const _orderColumns =
    'id,pickup_address,destination_address,pickup_lat,pickup_lng,'
    'destination_lat,destination_lng,proposed_price,agreed_price,status,'
    'created_at,completed_at,bidding_expires_at,route_distance_meters,'
    'route_duration_seconds,'
    'route_polyline,service_types(code,name_ar)';

class DriverService {
  DriverService(this._client, {this.onAuthFailure});

  final SupabaseClient _client;
  final Future<void> Function()? onAuthFailure;

  String? get currentEmail => _client.auth.currentUser?.email;

  Future<DriverAccount?> loadAccount() => _read(() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Session expired', code: 'session_not_found');
    }
    final row = await _client
        .from('drivers')
        .select('id,driver_type,office_id,status,is_online')
        .eq('user_id', userId)
        .maybeSingle();
    return row == null ? null : DriverAccount.fromJson(row);
  });

  Future<List<DriverOrder>> loadAvailableRequests() => _read(() async {
    final rows = await _client.rpc('get_driver_requests');
    return (rows as List)
        .map(
          (row) => DriverOrder.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList(growable: false);
  });

  Future<void> updateLocation({
    required double latitude,
    required double longitude,
    required double accuracyMeters,
    double? headingDegrees,
    double? speedMps,
  }) => _friendly(() async {
    await _client
        .rpc(
          'update_driver_location',
          params: {
            'p_latitude': latitude,
            'p_longitude': longitude,
            'p_accuracy_meters': accuracyMeters,
            'p_heading_degrees': headingDegrees,
            'p_speed_mps': speedMps,
          },
        )
        .timeout(transportTimeout);
  });

  Future<DriverOrder?> loadActiveOrder(String driverId) => _read(() async {
    final row = await _client
        .from('orders')
        .select(_orderColumns)
        .eq('driver_id', driverId)
        .inFilter('status', const [
          'DRIVER_ASSIGNED',
          'DRIVER_ON_WAY',
          'DRIVER_ARRIVED',
          'IN_PROGRESS',
        ])
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : DriverOrder.fromJson(row);
  });

  Future<List<DriverOffer>> loadWaitingOffers({DriverOffer? after}) =>
      _read(() async {
        final rows = await _client.rpc(
          'get_driver_active_offers',
          params: {
            'p_cursor_created_at': after?.createdAt?.toUtc().toIso8601String(),
            'p_cursor_id': after?.id,
            'p_limit': 50,
          },
        );
        return (rows as List)
            .map(
              (row) =>
                  DriverOffer.fromJson(Map<String, dynamic>.from(row as Map)),
            )
            .toList(growable: false);
      });

  Future<DriverOrder> loadOrder(String orderId) => _read(() async {
    final rows =
        await _client.rpc(
              'get_driver_requests',
              params: {'p_order_id': orderId},
            )
            as List;
    if (rows.isEmpty) {
      throw const ReadFailure(ReadFailureKind.unavailable);
    }
    return DriverOrder.fromJson(Map<String, dynamic>.from(rows.single as Map));
  });

  Future<DriverCustomerContact?> loadCustomerContact(String orderId) =>
      _read(() async {
        final userId = _client.auth.currentUser?.id;
        if (userId == null) {
          throw const ReadFailure(ReadFailureKind.auth);
        }
        final data = await _client
            .rpc(
              'get_driver_active_customer_contact',
              params: {'p_order_id': orderId},
            )
            .timeout(recoveryReadTimeout);
        if (_client.auth.currentUser?.id != userId) return null;
        if (data is! List || data.isEmpty || data.first is! Map) return null;
        return DriverCustomerContact.fromJson(
          Map<String, dynamic>.from(data.first as Map),
        );
      });

  Future<DriverOffer?> loadOffer(String orderId) => _read(() async {
    final rows =
        await _client.rpc('get_driver_offer', params: {'p_order_id': orderId})
            as List;
    return rows.isEmpty
        ? null
        : DriverOffer.fromJson(Map<String, dynamic>.from(rows.single as Map));
  });

  Future<List<DriverOrder>> loadHistory(String driverId) => _read(() async {
    final rows = await _client
        .from('orders')
        .select(_orderColumns)
        .eq('driver_id', driverId)
        .inFilter('status', const ['COMPLETED', 'CANCELLED'])
        .order('created_at', ascending: false)
        .limit(50);
    return rows.map(DriverOrder.fromJson).toList(growable: false);
  });

  Future<List<DriverEarningEntry>> loadEarnings() => _read(() async {
    final rows =
        await _client.rpc('get_driver_earnings', params: {'p_limit': 50})
            as List;
    return rows
        .map(
          (row) => DriverEarningEntry.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList(growable: false);
  });

  Future<void> setOnline(bool isOnline) => _friendly(() async {
    await _client.rpc('set_driver_online', params: {'p_is_online': isOnline});
  });

  Future<void> submitIndependentDriverApplication({
    required String fullName,
    required String phone,
    required DateTime dateOfBirth,
    required String plateNumber,
    required String brand,
    required String model,
    required String color,
    int? modelYear,
  }) => _friendly(() async {
    await _client
        .rpc(
          'submit_independent_driver_application',
          params: {
            'p_full_name': fullName,
            'p_phone': phone,
            'p_date_of_birth': _date(dateOfBirth),
            'p_plate_number': plateNumber,
            'p_brand': brand,
            'p_model': model,
            'p_color': color,
            'p_model_year': modelYear,
          },
        )
        .timeout(transportTimeout);
  });

  Future<DriverVerificationOverview> loadVerificationOverview() =>
      _read(() async {
        final rows =
            await _client
                    .rpc('get_driver_verification_overview')
                    .timeout(recoveryReadTimeout)
                as List;
        if (rows.isEmpty) throw const ReadFailure(ReadFailureKind.unavailable);
        return DriverVerificationOverview.fromJson(
          Map<String, dynamic>.from(rows.single as Map),
        );
      });

  Future<void> confirmRideSafetyEquipment() => _friendly(() async {
    await _client
        .rpc('confirm_ride_safety_equipment')
        .timeout(transportTimeout);
  });

  Future<void> submitDriverDocument({
    required String driverId,
    required String type,
    required Uint8List bytes,
    required String extension,
    DateTime? expiryDate,
  }) => _uploadDocument(
    path:
        '$driverId/driver/$type/${DateTime.now().microsecondsSinceEpoch}.$extension',
    bytes: bytes,
    register: (path) => _client.rpc(
      'submit_driver_document',
      params: {
        'p_document_type': type,
        'p_file_path': path,
        'p_expiry_date': _date(expiryDate),
      },
    ),
  );

  Future<void> submitMotorcycleDocument({
    required String driverId,
    required String motorcycleId,
    required String type,
    required Uint8List bytes,
    required String extension,
    DateTime? expiryDate,
  }) => _uploadDocument(
    path:
        '$driverId/motorcycle/$motorcycleId/$type/${DateTime.now().microsecondsSinceEpoch}.$extension',
    bytes: bytes,
    register: (path) => _client.rpc(
      'submit_motorcycle_document',
      params: {
        'p_motorcycle_id': motorcycleId,
        'p_document_type': type,
        'p_file_path': path,
        'p_expiry_date': _date(expiryDate),
      },
    ),
  );

  Future<DriverOffer> submitOffer(String orderId, double price) =>
      _friendly(() async {
        if (!price.isFinite || price <= 0) {
          throw const DriverAppException('أدخل سعرًا صحيحًا أكبر من صفر.');
        }
        final row = await _client.rpc(
          'submit_offer',
          params: {'p_order_id': orderId, 'p_offered_price': price},
        );
        return DriverOffer.fromJson(Map<String, dynamic>.from(row as Map));
      });

  Future<void> withdrawOffer(String offerId) => _friendly(() async {
    await _client.rpc('withdraw_offer', params: {'p_offer_id': offerId});
  });

  Future<void> cancelOrder(String orderId, String reason) =>
      _friendly(() async {
        final trimmed = reason.trim();
        if (trimmed.isEmpty || trimmed.length > 500) {
          throw const DriverAppException('اكتب سبب الإلغاء في 500 حرف أو أقل.');
        }
        await _client.rpc(
          'driver_cancel_order',
          params: {'p_order_id': orderId, 'p_reason': trimmed},
        );
      });

  Future<DriverOrder> advanceOrder(String orderId, DriverTripAction action) =>
      _friendly(() async {
        final row = await _client.rpc(
          switch (action) {
            DriverTripAction.onWay => 'driver_on_way',
            DriverTripAction.arrived => 'driver_arrived',
            DriverTripAction.start => 'start_order',
            DriverTripAction.deliveryPickup => 'confirm_delivery_pickup',
            DriverTripAction.complete => 'complete_order',
            DriverTripAction.deliveryComplete => throw const DriverAppException(
              'أدخل كود تأكيد التسليم أولًا.',
            ),
          },
          params: {'p_order_id': orderId},
        );
        return DriverOrder.fromJson(Map<String, dynamic>.from(row as Map));
      });

  Future<DeliveryCompletionResult> completeDelivery(
    String orderId,
    String code,
  ) => _friendly(() async {
    if (!RegExp(r'^\d{4}$').hasMatch(code)) {
      throw const DriverAppException('أدخل كود التسليم المكوّن من 4 أرقام.');
    }
    final rows =
        await _client
                .rpc(
                  'complete_delivery_with_code',
                  params: {'p_order_id': orderId, 'p_confirmation_code': code},
                )
                .timeout(transportTimeout)
            as List;
    if (rows.isEmpty) {
      throw const DriverAppException('تعذر التحقق من كود التسليم.');
    }
    return DeliveryCompletionResult.fromJson(
      Map<String, dynamic>.from(rows.single as Map),
    );
  });

  Future<bool> launchCustomerCall(
    String phone, {
    Future<bool> Function(Uri uri)? launcher,
  }) {
    final uri = Uri(scheme: 'tel', path: phone);
    return (launcher ??
        (uri) => launchUrl(uri, mode: LaunchMode.externalApplication))(uri);
  }

  Future<void> _uploadDocument({
    required String path,
    required Uint8List bytes,
    required Future<dynamic> Function(String path) register,
  }) => _friendly(() async {
    if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
      throw const DriverAppException('اختر ملفًا صالحًا بحجم لا يتجاوز 10 MB.');
    }
    final extension = path.split('.').last.toLowerCase();
    final contentType = switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      _ => 'application/pdf',
    };
    await _client.storage
        .from('driver-documents')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType),
        )
        .timeout(transportTimeout);
    try {
      await register(path).timeout(transportTimeout);
    } catch (_) {
      try {
        await _client.storage.from('driver-documents').remove([path]);
      } catch (_) {
        // A private orphan is safer than registering an unverified file.
      }
      rethrow;
    }
  });

  static String? _date(DateTime? value) =>
      value?.toIso8601String().split('T').first;

  Future<T> _read<T>(Future<T> Function() action) async {
    try {
      return await action().timeout(recoveryReadTimeout);
    } on PostgrestException catch (error) {
      if (error.message.toLowerCase().contains('location is stale')) {
        throw DriverAppException(
          error.hint?.trim().isNotEmpty == true
              ? error.hint!
              : 'حدّث موقعك الحالي لعرض الطلبات القريبة.',
        );
      }
      final failure = classifyReadError(error);
      if (failure.kind == ReadFailureKind.auth && onAuthFailure != null) {
        try {
          await onAuthFailure!().timeout(transportTimeout);
        } catch (_) {
          /* Auth owns recovery. */
        }
      }
      throw failure;
    } catch (error) {
      final failure = classifyReadError(error);
      if (failure.kind == ReadFailureKind.auth && onAuthFailure != null) {
        try {
          await onAuthFailure!().timeout(transportTimeout);
        } catch (_) {
          /* Auth owns recovery. */
        }
      }
      throw failure;
    }
  }

  Future<T> _friendly<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DriverAppException {
      rethrow;
    } on PostgrestException catch (error) {
      if (classifyMutationError(error) != MutationOutcome.businessFailure) {
        rethrow;
      }
      final message = error.message.toLowerCase();
      if (message.contains('location') &&
          (error.hint?.trim().isNotEmpty ?? false)) {
        throw DriverAppException(error.hint!);
      }
      if (message.contains('online eligibility denied') &&
          (error.hint?.trim().isNotEmpty ?? false)) {
        throw DriverAppException(error.hint!);
      }
      if (message.contains('expected state') ||
          message.contains('not open for bidding') ||
          message.contains('not found')) {
        throw const DriverAppException(
          'تم تحديث حالة الطلب. حدّث الصفحة وحاول مرة أخرى.',
        );
      }
      if (message.contains('invalid offer')) {
        throw const DriverAppException('أدخل سعرًا صحيحًا أكبر من صفر.');
      }
      if (message.contains('active offer already exists')) {
        throw const DriverAppException('اسحب عرضك الحالي قبل إرسال عرض جديد.');
      }
      if (message.contains('withdraw')) {
        throw const DriverAppException('لم يعد من الممكن سحب هذا العرض.');
      }
      if (message.contains('cancellation reason')) {
        throw const DriverAppException('سبب الإلغاء مطلوب.');
      }
      if (message.contains('driver cannot cancel')) {
        throw const DriverAppException(
          'لا يمكن إلغاء الرحلة في حالتها الحالية.',
        );
      }
      if (message.contains('active order') ||
          message.contains('active assignment')) {
        throw const DriverAppException(
          'لديك رحلة نشطة بالفعل. أكملها قبل استقبال طلب جديد.',
        );
      }
      if (message.contains('driver') || message.contains('eligible')) {
        throw const DriverAppException(
          'حساب السائق غير مؤهل لتنفيذ هذا الإجراء الآن.',
        );
      }
      throw const DriverAppException('تعذر إكمال العملية. حاول مرة أخرى.');
    }
  }
}
