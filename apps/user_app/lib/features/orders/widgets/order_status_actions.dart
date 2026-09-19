import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:user_app/app/user_theme.dart';
import 'package:user_app/features/orders/order_models.dart';

class CancellationPanel extends StatelessWidget {
  const CancellationPanel({
    required this.reasonController,
    required this.reasonRequired,
    required this.isLate,
    required this.busy,
    required this.onConfirm,
    required this.onBack,
    super.key,
  });

  final TextEditingController reasonController;
  final bool reasonRequired;
  final bool isLate;
  final bool busy;
  final VoidCallback onConfirm;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: UserColors.error.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(BikoRadius.medium),
    ),
    child: Padding(
      padding: const EdgeInsets.all(BikoSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('تأكيد الإلغاء', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: BikoSpace.xs),
          Text(
            isLate
                ? 'سيُسجل هذا الإلغاء كإلغاء متأخر.'
                : reasonRequired
                ? 'اكتب سببًا مختصرًا لإلغاء الطلب.'
                : 'يمكنك ذكر السبب اختياريًا.',
          ),
          const SizedBox(height: BikoSpace.md),
          TextField(
            key: const Key('cancellation-reason'),
            controller: reasonController,
            enabled: !busy,
            maxLength: 500,
            minLines: 2,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: reasonRequired
                  ? 'سبب الإلغاء (مطلوب)'
                  : 'سبب الإلغاء (اختياري)',
            ),
          ),
          Row(
            children: [
              Expanded(
                child: DestructiveButton(
                  key: const Key('confirm-cancellation'),
                  onPressed: busy ? null : onConfirm,
                  isLoading: busy,
                  label: 'إلغاء الطلب',
                ),
              ),
              const SizedBox(width: BikoSpace.sm),
              TextButton(
                onPressed: busy ? null : onBack,
                child: const Text('رجوع'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class TerminalActions extends StatelessWidget {
  const TerminalActions({
    required this.order,
    required this.onBookAgain,
    required this.onHome,
    super.key,
  });

  final CustomerOrder order;
  final VoidCallback onBookAgain;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Card(
        color: switch (order.status) {
          OrderStatus.completed => UserColors.success.withValues(alpha: .08),
          OrderStatus.cancelled => UserColors.error.withValues(alpha: .08),
          _ => UserColors.warning.withValues(alpha: .1),
        },
        child: Padding(
          padding: const EdgeInsets.all(BikoSpace.md),
          child: Row(
            children: [
              Icon(switch (order.status) {
                OrderStatus.completed => Icons.check_circle_outline_rounded,
                OrderStatus.cancelled => Icons.cancel_outlined,
                _ => Icons.timer_off_outlined,
              }, color: orderStatusColor(context, order.status)),
              const SizedBox(width: BikoSpace.sm),
              Expanded(
                child: Text(switch (order.status) {
                  OrderStatus.completed => 'اكتمل الطلب. الدفع نقدًا للسائق.',
                  OrderStatus.cancelled =>
                    'تم إلغاء الطلب ولن يعود إلى استقبال العروض.',
                  OrderStatus.expired =>
                    'انتهت مهلة العروض. يمكنك إنشاء طلب جديد.',
                  _ => '',
                }),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: BikoSpace.md),
      PrimaryButton(
        key: const Key('book-again'),
        onPressed: onBookAgain,
        icon: Icons.replay_rounded,
        label: 'احجز مرة أخرى',
      ),
      const SizedBox(height: BikoSpace.sm),
      TextButton(onPressed: onHome, child: const Text('العودة للرئيسية')),
    ],
  );
}
