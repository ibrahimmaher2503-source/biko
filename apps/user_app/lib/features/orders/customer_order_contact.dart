import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:user_app/core/widgets/feedback_widgets.dart';
import 'package:user_app/features/orders/order_models.dart';

class AssignedDriverContact {
  const AssignedDriverContact(this.phone);

  final String phone;

  factory AssignedDriverContact.fromJson(Map<String, dynamic> json) =>
      AssignedDriverContact(json['driver_phone'] as String);
}

class CustomerOrderContactService {
  CustomerOrderContactService(this._client);

  final SupabaseClient _client;

  Future<AssignedDriverContact?> load(String orderId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw const ReadFailure(ReadFailureKind.auth);
      final data = await _client
          .rpc(
            'get_customer_active_driver_contact',
            params: {'p_order_id': orderId},
          )
          .timeout(recoveryReadTimeout);
      if (_client.auth.currentUser?.id != userId) return null;
      if (data is! List || data.isEmpty || data.first is! Map) return null;
      final phone = (data.first as Map)['driver_phone']?.toString().trim();
      return phone == null || phone.isEmpty
          ? null
          : AssignedDriverContact.fromJson({'driver_phone': phone});
    } catch (error) {
      throw classifyReadError(error);
    }
  }
}

final customerOrderContactServiceProvider =
    Provider<CustomerOrderContactService>((ref) {
      return CustomerOrderContactService(Supabase.instance.client);
    });

final customerOrderContactProvider = FutureProvider.autoDispose
    .family<AssignedDriverContact?, String>((ref, orderId) {
      return ref.watch(customerOrderContactServiceProvider).load(orderId);
    });

Future<bool> launchDriverCall(
  String phone, {
  Future<bool> Function(Uri uri)? launcher,
}) {
  final uri = Uri(scheme: 'tel', path: phone);
  return (launcher ??
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication))(uri);
}

String? normalizeCallPhone(String value) {
  final phone = value.trim();
  if (!RegExp(r'^\+?[0-9() -]+$').hasMatch(phone)) return null;
  final compact = phone.replaceAll(RegExp(r'[() -]'), '');
  final digits = compact.replaceAll('+', '');
  return digits.length >= 6 && digits.length <= 32 ? compact : null;
}

class CustomerOrderContactActions extends ConsumerStatefulWidget {
  const CustomerOrderContactActions({
    required this.order,
    this.launcher,
    super.key,
  });

  final CustomerOrder order;
  final Future<bool> Function(Uri uri)? launcher;

  @override
  ConsumerState<CustomerOrderContactActions> createState() =>
      _CustomerOrderContactActionsState();
}

class _CustomerOrderContactActionsState
    extends ConsumerState<CustomerOrderContactActions> {
  var _calling = false;

  bool get _canContactDriver => const {
    OrderStatus.driverAssigned,
    OrderStatus.driverOnWay,
    OrderStatus.driverArrived,
    OrderStatus.inProgress,
  }.contains(widget.order.status);

  @override
  Widget build(BuildContext context) {
    if (!_canContactDriver) return const SizedBox.shrink();
    final contact = ref.watch(customerOrderContactProvider(widget.order.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        contact.when(
          loading: () => const SizedBox(height: BikoSpace.gap),
          error: (_, _) => UserInlineMessage(
            message: 'تعذر تحميل وسيلة اتصال السائق الآن.',
            actionLabel: 'إعادة المحاولة',
            onAction: () =>
                ref.invalidate(customerOrderContactProvider(widget.order.id)),
          ),
          data: (value) => value != null
              ? FilledButton.icon(
                  key: const Key('call-driver'),
                  onPressed: _calling ? null : _call,
                  icon: _calling
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.call_rounded),
                  label: Text(
                    _calling ? 'جارٍ فتح الاتصال...' : 'اتصل بالسائق',
                  ),
                )
              : const UserInlineMessage(
                  message: 'وسيلة اتصال السائق غير متاحة الآن.',
                ),
        ),
        const SizedBox(height: BikoSpace.gap),
        const CustomerSupportActions(),
      ],
    );
  }

  Future<void> _call() async {
    if (_calling) return;
    final orderId = widget.order.id;
    final driverId = widget.order.driverId;
    final userId = ref
        .read(customerOrderContactServiceProvider)
        ._client
        .auth
        .currentUser
        ?.id;
    setState(() => _calling = true);
    try {
      final fresh = await ref
          .read(customerOrderContactServiceProvider)
          .load(orderId);
      final phone = fresh == null ? null : normalizeCallPhone(fresh.phone);
      if (!mounted ||
          widget.order.id != orderId ||
          widget.order.driverId != driverId ||
          !_canContactDriver ||
          ref
                  .read(customerOrderContactServiceProvider)
                  ._client
                  .auth
                  .currentUser
                  ?.id !=
              userId)
        return;
      if (phone == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('وسيلة الاتصال لم تعد متاحة الآن.')),
        );
        return;
      }
      if (!await launchDriverCall(phone, launcher: widget.launcher) &&
          mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح تطبيق الاتصال.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر بدء الاتصال. حاول مرة أخرى.')),
        );
      }
    } finally {
      if (mounted) setState(() => _calling = false);
    }
  }
}

class CustomerSupportContact {
  const CustomerSupportContact({this.phone, this.email, this.website});

  final String? phone;
  final String? email;
  final String? website;

  static const configured = CustomerSupportContact(
    phone: String.fromEnvironment('BIKO_SUPPORT_PHONE'),
    email: String.fromEnvironment('BIKO_SUPPORT_EMAIL'),
    website: String.fromEnvironment('BIKO_SUPPORT_URL'),
  );

  String? get callPhone => phone == null ? null : normalizeCallPhone(phone!);
  String? get mail =>
      email != null && RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email!)
      ? email
      : null;
  Uri? get web {
    final uri = website == null ? null : Uri.tryParse(website!);
    return uri != null &&
            uri.hasAuthority &&
            uri.host.isNotEmpty &&
            uri.userInfo.isEmpty &&
            uri.scheme == 'https'
        ? uri
        : null;
  }
}

class CustomerSupportActions extends StatelessWidget {
  const CustomerSupportActions({super.key});

  @override
  Widget build(BuildContext context) {
    final support = CustomerSupportContact.configured;
    final phone = support.callPhone;
    final email = support.mail;
    final web = support.web;
    if (phone == null && email == null && web == null) {
      return const UserInlineMessage(
        message: 'الدعم غير مُعدّ للتواصل المباشر حالياً.',
        icon: Icons.support_agent_outlined,
      );
    }
    return Wrap(
      spacing: BikoSpace.sm,
      runSpacing: BikoSpace.sm,
      children: [
        if (phone != null)
          OutlinedButton.icon(
            onPressed: () => _open(context, () => launchDriverCall(phone)),
            icon: const Icon(Icons.call_outlined),
            label: const Text('اتصل بالدعم'),
          ),
        if (email != null)
          OutlinedButton.icon(
            onPressed: () => _open(
              context,
              () => launchUrl(Uri(scheme: 'mailto', path: email)),
            ),
            icon: const Icon(Icons.email_outlined),
            label: const Text('راسل الدعم'),
          ),
        if (web != null)
          OutlinedButton.icon(
            onPressed: () => _open(
              context,
              () => launchUrl(web, mode: LaunchMode.externalApplication),
            ),
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('موقع الدعم'),
          ),
      ],
    );
  }

  Future<void> _open(BuildContext context, Future<bool> Function() open) async {
    try {
      if (!await open() && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح وسيلة التواصل.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح وسيلة التواصل.')),
        );
      }
    }
  }
}
