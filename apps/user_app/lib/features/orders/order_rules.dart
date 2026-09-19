import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_core/app_core.dart';
import 'package:user_app/features/orders/order_models.dart';

bool customerCanCancel(OrderStatus status) => const {
  OrderStatus.bidding,
  OrderStatus.driverAssigned,
  OrderStatus.driverOnWay,
  OrderStatus.driverArrived,
}.contains(status);

bool cancellationReasonRequired(OrderStatus status) => const {
  OrderStatus.driverAssigned,
  OrderStatus.driverOnWay,
  OrderStatus.driverArrived,
}.contains(status);

bool isTerminalOrder(OrderStatus status) => const {
  OrderStatus.completed,
  OrderStatus.cancelled,
  OrderStatus.expired,
}.contains(status);

String newCreationIntentId({Random? random}) {
  final source = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => source.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final value = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
      '${value.substring(12, 16)}-${value.substring(16, 20)}-'
      '${value.substring(20)}';
}

String? requiredText(String? value, String message) =>
    (value ?? '').trim().isEmpty ? message : null;

String? positivePrice(String? value) {
  final amount = double.tryParse((value ?? '').trim());
  return amount == null || !amount.isFinite || amount <= 0
      ? 'أدخل سعرًا صحيحًا أكبر من صفر.'
      : null;
}

String? proposedPriceForQuote(String? value, RouteQuote? quote) {
  final base = positivePrice(value);
  if (base != null) return base;
  final price = double.parse(value!.trim());
  final minimum = quote?.minimumCustomerPrice;
  return minimum != null && price < minimum
      ? 'الحد الأدنى ${formatAmount(minimum)} ج.م.'
      : null;
}

String? parcelWeight(String? value) {
  final amount = double.tryParse((value ?? '').trim());
  return amount == null || !amount.isFinite || amount <= 0 || amount > 8
      ? 'الوزن يجب أن يكون أكبر من صفر وحتى 8 كجم.'
      : null;
}

String? declaredValue(String? value) {
  final amount = double.tryParse((value ?? '').trim());
  return amount == null || !amount.isFinite || amount < 0 || amount > 3000
      ? 'القيمة المعلنة من 0 حتى 3000 ج.م.'
      : null;
}

String customerMutationMessage(Object? error) {
  if (error is BusinessFailure) return error.message;
  if (error is PostgrestException) {
    final message = error.message.toLowerCase();
    if (message.contains('creation intent conflicts')) {
      return 'تغيّرت بيانات الطلب أثناء الاستعادة. ابدأ محاولة جديدة.';
    }
    if (message.contains('route quote') && message.contains('expired')) {
      return 'انتهت صلاحية حساب المسار. أعد حساب المسار والسعر.';
    }
    if (message.contains('route quote') ||
        message.contains('coordinates do not match')) {
      return 'تغيّر المسار. أعد حساب المسار والسعر قبل الإرسال.';
    }
    if (message.contains('below the trusted minimum')) {
      return 'السعر أقل من الحد الأدنى المسموح.';
    }
    if (message.contains('recipient name')) {
      return 'اسم المستلم مطلوب.';
    }
    if (message.contains('recipient phone')) {
      return 'هاتف المستلم مطلوب.';
    }
    if (message.contains('parcel weight')) {
      return 'وزن الطرد يجب ألا يتجاوز 8 كجم.';
    }
    if (message.contains('declared value')) {
      return 'القيمة المعلنة يجب ألا تتجاوز 3000 ج.م.';
    }
    if (message.contains('reason is required')) {
      return 'سبب الإلغاء مطلوب في هذه المرحلة.';
    }
    if (message.contains('offer') &&
        (message.contains('active') || message.contains('eligible'))) {
      return 'هذا العرض لم يعد متاحًا. حدّث العروض واختر عرضًا آخر.';
    }
    if (message.contains('driver') &&
        (message.contains('available') || message.contains('assignment'))) {
      return 'السائق غير متاح الآن. حدّث العروض واختر عرضًا آخر.';
    }
    if (message.contains('bidding') || message.contains('expired')) {
      return 'انتهت مهلة استقبال العروض.';
    }
    if (message.contains('current state') ||
        message.contains('cannot be cancelled')) {
      return 'لا يمكن تنفيذ الإجراء في حالة الطلب الحالية.';
    }
    if (error.code == '42501') return 'ليس لديك صلاحية لتنفيذ هذا الإجراء.';
  }
  final outcome = error == null ? null : classifyMutationError(error);
  if (outcome == MutationOutcome.authFailure) {
    return 'انتهت الجلسة. سجل الدخول مرة أخرى.';
  }
  if (outcome == MutationOutcome.uncertain) {
    return 'تعذر تأكيد النتيجة. نتحقق من حالة الطلب بدون تكرار الإجراء.';
  }
  return 'تعذر إكمال العملية. أعد المحاولة.';
}
