import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/app/user_theme.dart';
import 'package:user_app/core/widgets/feedback_widgets.dart';
import 'package:user_app/features/orders/order_providers.dart';
import 'package:user_app/features/orders/order_models.dart';
import 'package:user_app/features/orders/order_history_view.dart';
import 'package:user_app/features/maps/location_picker_page.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({
    required this.onRide,
    required this.onDelivery,
    required this.onHistory,
    required this.onBookAgain,
    this.onCreateDraft,
    super.key,
  });

  final VoidCallback onRide;
  final VoidCallback onDelivery;
  final VoidCallback onHistory;
  final ValueChanged<OrderDraft> onBookAgain;
  final ValueChanged<OrderDraft>? onCreateDraft;

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  LocationSelection? _pickup;
  LocationSelection? _destination;

  Future<void> _selectLocation(bool pickup) async {
    final selection = await pickMapLocation(
      context,
      title: pickup ? 'اختر نقطة الاستلام' : 'اختر الوجهة',
      initial: pickup ? _pickup : _destination,
    );
    if (!mounted || selection == null) return;
    setState(() {
      if (pickup) {
        _pickup = selection;
      } else {
        _destination = selection;
      }
    });
  }

  Future<void> _start(ServiceType service, VoidCallback fallback) async {
    final onCreateDraft = widget.onCreateDraft;
    if (onCreateDraft == null) {
      fallback();
      return;
    }
    var pickup = _pickup;
    var destination = _destination;
    if (pickup == null) {
      pickup = await pickMapLocation(context, title: 'اختر نقطة الاستلام');
      if (!mounted || pickup == null) return;
      setState(() => _pickup = pickup);
    }
    if (destination == null) {
      destination = await pickMapLocation(context, title: 'اختر الوجهة');
      if (!mounted || destination == null) return;
      setState(() => _destination = destination);
    }
    onCreateDraft(
      OrderDraft(
        service: service,
        pickup: pickup,
        destination: destination,
        // Client-only draft: CreateOrderPage obtains the trusted quote and fare.
        proposedPrice: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(orderHistoryProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(activeOrderProvider);
        ref.invalidate(orderHistoryProvider);
        ref.invalidate(orderHistoryPageProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          BikoSpace.md,
          BikoSpace.sm,
          BikoSpace.md,
          BikoSpace.xl,
        ),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إلى أين؟',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: BikoSpace.xs),
                    Text(
                      'حدّد المسار ثم اختر الخدمة.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: UserColors.primarySoft,
                  borderRadius: BorderRadius.circular(BikoRadius.medium),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(BikoSpace.sm),
                  child: Icon(Icons.my_location_rounded),
                ),
              ),
            ],
          ),
          const SizedBox(height: BikoSpace.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(BikoSpace.sm),
              child: Column(
                children: [
                  LocationField(
                    fieldKey: const Key('home-pickup-location'),
                    label: 'نقطة الاستلام',
                    address: _pickup?.displayAddress,
                    onTap: () => _selectLocation(true),
                  ),
                  const SizedBox(height: BikoSpace.gap),
                  LocationField(
                    fieldKey: const Key('home-destination-location'),
                    label: 'الوجهة',
                    address: _destination?.displayAddress,
                    onTap: () => _selectLocation(false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: BikoSpace.md),
          Text('احجز الآن', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: BikoSpace.sm),
          Row(
            children: [
              Expanded(
                child: _ServiceOption(
                  key: const Key('ride-service'),
                  icon: Icons.two_wheeler_rounded,
                  title: 'رحلة',
                  description: 'راكب واحد',
                  color: UserColors.primary,
                  onTap: () => _start(ServiceType.ride, widget.onRide),
                ),
              ),
              const SizedBox(width: BikoSpace.gap),
              Expanded(
                child: _ServiceOption(
                  key: const Key('delivery-service'),
                  icon: Icons.inventory_2_outlined,
                  title: 'توصيل',
                  description: 'طرد حتى 8 كجم',
                  color: UserColors.warning,
                  onTap: () => _start(ServiceType.delivery, widget.onDelivery),
                ),
              ),
            ],
          ),
          const SizedBox(height: BikoSpace.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  'آخر طلب',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton(
                onPressed: widget.onHistory,
                child: const Text('كل الطلبات'),
              ),
            ],
          ),
          const SizedBox(height: BikoSpace.sm),
          history.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => UserInlineMessage(
              message: 'تعذر تحميل آخر طلب. يمكنك إنشاء طلب جديد الآن.',
              actionLabel: 'إعادة المحاولة',
              onAction: () {
                ref
                  ..invalidate(orderHistoryProvider)
                  ..invalidate(orderHistoryPageProvider);
              },
            ),
            data: (orders) => orders.isEmpty
                ? const UserInlineMessage(
                    message: 'لا توجد طلبات سابقة. أول طلب لك يبدأ من هنا.',
                    icon: Icons.history_toggle_off_rounded,
                  )
                : OrderHistoryCard(
                    order: orders.first,
                    onOpenDetails: () =>
                        context.push('/orders/${orders.first.id}'),
                    onBookAgain: () =>
                        widget.onBookAgain(orders.first.bookAgainDraft()),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ServiceOption extends StatelessWidget {
  const _ServiceOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(BikoRadius.medium),
      child: Padding(
        padding: const EdgeInsets.all(BikoSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(BikoRadius.small),
              ),
              child: Padding(
                padding: const EdgeInsets.all(BikoSpace.xs),
                child: Icon(icon, color: color, size: 24),
              ),
            ),
            const SizedBox(height: BikoSpace.sm),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: BikoSpace.xs),
            Text(description, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ),
  );
}
