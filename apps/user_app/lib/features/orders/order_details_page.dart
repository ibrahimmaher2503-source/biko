import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/core/widgets/feedback_widgets.dart';
import 'package:user_app/features/orders/order_models.dart';
import 'package:user_app/features/orders/order_providers.dart';
import 'package:user_app/features/orders/order_rules.dart';

class OrderDetailsPage extends ConsumerWidget {
  const OrderDetailsPage({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderDetailsProvider(orderId));
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الطلب')),
      body: order.when(
        loading: () => const SafeArea(child: LoadingSkeleton()),
        error: (error, _) => UserErrorState(
          message: classifyReadError(error).message,
          onRetry: () => ref.invalidate(orderDetailsProvider(orderId)),
        ),
        data: (value) => _OrderDetails(order: value),
      ),
    );
  }
}

class _OrderDetails extends StatelessWidget {
  const _OrderDetails({required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final terminal = isTerminalOrder(order.status);
    final terminalLabel = switch (order.status) {
      OrderStatus.completed => 'اكتمل الطلب',
      OrderStatus.cancelled => 'أُلغي الطلب',
      OrderStatus.expired => 'انتهت مهلة الطلب',
      _ => 'آخر تحديث',
    };
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(BikoSpace.md),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(BikoSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: BikoSpace.sm,
                    runSpacing: BikoSpace.xs,
                    children: [
                      ServiceTypeBadge(code: order.service.databaseValue),
                      StatusBadge(
                        label: orderStatusLabel(order.status),
                        color: orderStatusColor(context, order.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: BikoSpace.md),
                  RouteSummary(
                    pickupAddress: order.pickup.displayAddress,
                    destinationAddress: order.destination.displayAddress,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: BikoSpace.gap),
          _DetailsCard(
            title: terminal && order.status == OrderStatus.completed
                ? 'الإيصال'
                : 'ملخص الطلب',
            children: [
              _DetailRow('تاريخ الإنشاء', formatOrderDate(order.createdAt)),
              if (order.terminalAt != null)
                _DetailRow(terminalLabel, formatOrderDate(order.terminalAt!)),
              _DetailRow('طريقة الدفع', 'نقدي'),
              if (order.agreedPrice != null)
                PriceDisplay(order.agreedPrice!, label: 'الأجرة المتفق عليها')
              else
                PriceDisplay(order.proposedPrice, label: 'السعر المقترح'),
              if (order.status == OrderStatus.cancelled ||
                  order.status == OrderStatus.expired)
                const Padding(
                  padding: EdgeInsets.only(top: BikoSpace.sm),
                  child: Text('لم يكتمل الطلب. لا تُفرض رسوم إلغاء.'),
                ),
              if ((order.cancellationReason ?? '').trim().isNotEmpty)
                _DetailRow('سبب الإلغاء', order.cancellationReason!.trim()),
            ],
          ),
          if (order.delivery != null) ...[
            const SizedBox(height: BikoSpace.gap),
            _DetailsCard(
              title: 'تفاصيل التوصيل',
              children: [
                _DetailRow('المستلم', order.delivery!.recipientName),
                _DetailRow(
                  'هاتف المستلم',
                  order.delivery!.recipientPhone,
                  ltr: true,
                ),
                _DetailRow(
                  'الوزن',
                  '${formatAmount(order.delivery!.parcelWeightKg)} كجم',
                ),
                _DetailRow(
                  'القيمة المعلنة',
                  '${formatAmount(order.delivery!.declaredValue)} ج.م',
                ),
              ],
            ),
          ],
          if (terminal) ...[
            const SizedBox(height: BikoSpace.lg),
            FilledButton.icon(
              onPressed: () => context.push(
                '/book/${order.service == ServiceType.ride ? 'ride' : 'delivery'}',
                extra: order.bookAgainDraft(),
              ),
              icon: const Icon(Icons.replay_rounded),
              label: const Text('احجز مرة أخرى'),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(BikoSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: BikoSpace.md),
          ...children,
        ],
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value, {this.ltr = false});

  final String label;
  final String value;
  final bool ltr;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: BikoSpace.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: BikoSpace.md),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            textDirection: ltr ? TextDirection.ltr : null,
          ),
        ),
      ],
    ),
  );
}
