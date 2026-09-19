import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/core/widgets/feedback_widgets.dart';
import 'package:user_app/features/orders/order_providers.dart';
import 'package:user_app/features/orders/order_models.dart';

class OrderHistoryView extends ConsumerStatefulWidget {
  const OrderHistoryView({super.key});

  @override
  ConsumerState<OrderHistoryView> createState() => _OrderHistoryViewState();
}

class _OrderHistoryViewState extends ConsumerState<OrderHistoryView> {
  OrderHistoryPage? _basePage;
  final List<OrderHistoryPage> _morePages = [];
  var _loadingMore = false;
  var _generation = 0;

  Future<void> _refresh() async {
    setState(() {
      _generation++;
      _basePage = null;
      _morePages.clear();
    });
    ref.invalidate(orderHistoryPageProvider);
  }

  Future<void> _loadMore(OrderHistoryPage page) async {
    final cursor = _morePages.isEmpty
        ? page.nextCursor
        : _morePages.last.nextCursor;
    if (cursor == null || _loadingMore) return;
    final generation = _generation;
    setState(() => _loadingMore = true);
    try {
      final next = await ref
          .read(orderServiceProvider)
          .loadHistoryPage(after: cursor);
      if (mounted && generation == _generation && identical(_basePage, page)) {
        setState(() => _morePages.add(next));
      }
    } catch (_) {
      if (mounted && generation == _generation && identical(_basePage, page)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تحميل طلبات إضافية.')),
        );
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loadingMore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(orderHistoryPageProvider);
    return history.when(
      loading: () => const LoadingSkeleton(),
      error: (error, _) => UserErrorState(
        message: classifyReadError(error).message,
        onRetry: () => ref.invalidate(orderHistoryPageProvider),
      ),
      data: (page) {
        if (!identical(_basePage, page)) {
          _generation++;
          _basePage = page;
          _morePages.clear();
          _loadingMore = false;
        }
        final orders = [
          ...page.orders,
          for (final more in _morePages) ...more.orders,
        ];
        final hasMore = _morePages.isEmpty
            ? page.hasMore
            : _morePages.last.hasMore;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: orders.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: BikoSpace.xl),
                  children: const [
                    EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'لا توجد طلبات بعد',
                      description:
                          'ستظهر هنا رحلاتك وطلبات التوصيل بعد انتهائها.',
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    BikoSpace.md,
                    BikoSpace.sm,
                    BikoSpace.md,
                    BikoSpace.xl,
                  ),
                  itemCount: orders.length + (hasMore ? 1 : 0),
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: BikoSpace.gap),
                  itemBuilder: (context, index) {
                    if (index == orders.length) {
                      return Center(
                        child: TextButton(
                          onPressed: _loadingMore
                              ? null
                              : () => _loadMore(page),
                          child: _loadingMore
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('تحميل المزيد'),
                        ),
                      );
                    }
                    final order = orders[index];
                    return OrderHistoryCard(
                      order: order,
                      onOpenDetails: () => context.push('/orders/${order.id}'),
                      onBookAgain: () => context.push(
                        '/book/${order.service == ServiceType.ride ? 'ride' : 'delivery'}',
                        extra: order.bookAgainDraft(),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

class OrderHistoryCard extends StatelessWidget {
  const OrderHistoryCard({
    required this.order,
    required this.onOpenDetails,
    required this.onBookAgain,
    super.key,
  });

  final CustomerOrder order;
  final VoidCallback onOpenDetails;
  final VoidCallback onBookAgain;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(BikoRadius.medium),
      onTap: onOpenDetails,
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ServiceTypeBadge(code: order.service.databaseValue),
                    const SizedBox(width: BikoSpace.sm),
                    StatusBadge(
                      label: orderStatusLabel(order.status),
                      color: orderStatusColor(context, order.status),
                    ),
                  ],
                ),
                Text(
                  formatOrderDate(order.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: BikoSpace.md),
            RouteSummary(
              pickupAddress: order.pickup.displayAddress,
              destinationAddress: order.destination.displayAddress,
            ),
            const Divider(height: BikoSpace.lg),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: BikoSpace.sm,
              runSpacing: BikoSpace.xs,
              children: [
                PriceDisplay(
                  order.agreedPrice ?? order.proposedPrice,
                  compact: true,
                ),
                TextButton.icon(
                  onPressed: onBookAgain,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('احجز مرة أخرى'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
