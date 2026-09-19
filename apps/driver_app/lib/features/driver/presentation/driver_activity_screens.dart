part of '../driver_screens.dart';

class DriverHistoryScreen extends ConsumerWidget {
  const DriverHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(driverHistoryProvider);
    return DriverShell(
      selectedIndex: 1,
      title: 'الرحلات',
      child: history.when(
        loading: () => const DriverLoadingState(),
        error: (error, _) => DriverErrorState(
          message: driverErrorMessage(error),
          onRetry: () => ref.invalidate(driverHistoryProvider),
        ),
        data: (orders) => orders.isEmpty
            ? const DriverEmptyState(
                icon: Icons.route_outlined,
                title: 'لا توجد رحلات سابقة',
                description: 'ستظهر الرحلات المكتملة والملغاة هنا.',
              )
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(driverHistoryProvider);
                  await ref.read(driverHistoryProvider.future);
                },
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(DriverSpace.md),
                  itemCount: orders.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: DriverSpace.md),
                  itemBuilder: (context, index) =>
                      _HistoryCard(order: orders[index]),
                ),
              ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.order});

  final DriverOrder order;

  @override
  Widget build(BuildContext context) => DriverCard(
    child: InkWell(
      key: Key('history-card-${order.id}'),
      onTap: () => showBikoBottomSheet<void>(
        context: context,
        builder: (_) => _HistoryDetailsSheet(order: order),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(DriverSpace.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.serviceName,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                StatusBadge(
                  label: orderStatusLabel(order.status),
                  color: orderStatusColor(context, order.status),
                ),
              ],
            ),
            const SizedBox(height: DriverSpace.md),
            Text(
              '${order.pickupAddress} ← ${order.destinationAddress}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: DriverColors.muted),
            ),
            const SizedBox(height: DriverSpace.md),
            Row(
              children: [
                Text(formatOrderDate(order.createdAt)),
                const Spacer(),
                PriceDisplay(order.displayPrice, compact: true),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _HistoryDetailsSheet extends StatelessWidget {
  const _HistoryDetailsSheet({required this.order});

  final DriverOrder order;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        DriverSpace.md,
        DriverSpace.sm,
        DriverSpace.md,
        DriverSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'تفاصيل الرحلة',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: DriverSpace.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  order.serviceName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              StatusBadge(
                label: orderStatusLabel(order.status),
                color: orderStatusColor(context, order.status),
              ),
            ],
          ),
          const Divider(height: DriverSpace.xl),
          _HistoryDetailRow(
            label: 'التاريخ',
            value: formatOrderDate(order.createdAt),
          ),
          const SizedBox(height: DriverSpace.md),
          _HistoryDetailRow(label: 'الاستلام', value: order.pickupAddress),
          const SizedBox(height: DriverSpace.md),
          _HistoryDetailRow(label: 'الوجهة', value: order.destinationAddress),
          const Divider(height: DriverSpace.xl),
          PriceDisplay(order.displayPrice, label: 'قيمة الرحلة'),
        ],
      ),
    ),
  );
}

class _HistoryDetailRow extends StatelessWidget {
  const _HistoryDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: DriverSpace.xs),
      Text(value, style: Theme.of(context).textTheme.titleSmall),
    ],
  );
}

class DriverEarningsScreen extends ConsumerWidget {
  const DriverEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earnings = ref.watch(driverEarningsProvider);
    return DriverShell(
      selectedIndex: 2,
      title: 'الأرباح',
      child: earnings.when(
        loading: () => const DriverLoadingState(),
        error: (error, _) => DriverErrorState(
          message: driverErrorMessage(error),
          onRetry: () => ref.invalidate(driverEarningsProvider),
        ),
        data: (data) {
          final total = data.entries.fold<double>(
            0,
            (sum, entry) => sum + entry.grossFare,
          );
          return ListView(
            padding: const EdgeInsets.all(DriverSpace.md),
            children: [
              DriverCard(
                color: DriverColors.primary.withValues(alpha: .06),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'إجمالي قيمة الرحلات المكتملة المعروضة',
                      style: TextStyle(color: DriverColors.muted),
                    ),
                    const SizedBox(height: DriverSpace.sm),
                    PriceDisplay(total),
                    const SizedBox(height: DriverSpace.md),
                    Text(
                      '${data.entries.length} رحلة مكتملة معروضة',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DriverSpace.md),
              if (data.driverType == DriverType.independent)
                DriverCard(
                  child: Column(
                    children: [
                      _ProfileRow(
                        label: 'عمولة المنصة',
                        value:
                            '${data.entries.fold<double>(0, (sum, entry) => sum + (entry.platformCommission ?? 0)).toStringAsFixed(2)} ج.م',
                      ),
                      const Divider(height: DriverSpace.lg),
                      _ProfileRow(
                        label: 'صافي الأرباح',
                        value:
                            '${data.entries.fold<double>(0, (sum, entry) => sum + (entry.driverNet ?? 0)).toStringAsFixed(2)} ج.م',
                      ),
                      if (data.entries.any(
                        (entry) => !entry.isFinanciallyKnown,
                      )) ...[
                        const Divider(height: DriverSpace.lg),
                        const Text(
                          'بعض الرحلات القديمة بلا احتساب عمولة بأثر رجعي.',
                          style: TextStyle(color: DriverColors.muted),
                        ),
                      ],
                    ],
                  ),
                )
              else
                const DriverCard(
                  child: Text(
                    'يعرض حساب سائق المكتب إجمالي قيمة الرحلات فقط. عمولة المكتب والرواتب لا تظهر هنا.',
                    style: TextStyle(color: DriverColors.muted, height: 1.5),
                  ),
                ),
              const SizedBox(height: DriverSpace.lg),
              const _SectionTitle('أحدث الرحلات المكتملة'),
              const SizedBox(height: DriverSpace.sm),
              if (data.entries.isEmpty)
                const DriverEmptyState(
                  icon: Icons.payments_outlined,
                  title: 'لا توجد أرباح مسجلة',
                  description: 'تظهر القيم بعد إكمال أول رحلة.',
                )
              else
                for (final entry in data.entries.take(5)) ...[
                  DriverCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(formatOrderDate(entry.completedAt)),
                        ),
                        PriceDisplay(entry.grossFare, compact: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: DriverSpace.md),
                ],
            ],
          );
        },
      ),
    );
  }
}
