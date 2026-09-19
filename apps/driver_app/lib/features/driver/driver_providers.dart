import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'driver_models.dart';
import 'driver_service.dart';

final driverServiceProvider = Provider<DriverService>(
  (ref) => DriverService(
    Supabase.instance.client,
    onAuthFailure: () => ref.read(authServiceProvider).revalidateSession(),
  ),
);

final driverAccountProvider = FutureProvider<DriverAccount?>(
  (ref) => ref.read(driverServiceProvider).loadAccount(),
  retry: (_, _) => null,
);

final driverVerificationProvider = FutureProvider<DriverVerificationOverview>(
  (ref) => ref.read(driverServiceProvider).loadVerificationOverview(),
  retry: (_, _) => null,
);

final driverActiveOrderProvider = FutureProvider<DriverOrder?>((ref) async {
  final account = await ref.watch(driverAccountProvider.future);
  if (account == null) return null;
  return ref.read(driverServiceProvider).loadActiveOrder(account.id);
}, retry: (_, _) => null);

final driverRequestsProvider = FutureProvider<List<DriverOrder>>(
  (ref) => ref.read(driverServiceProvider).loadAvailableRequests(),
  retry: (_, _) => null,
);

final driverWaitingOffersProvider = FutureProvider<List<DriverOffer>>(
  (ref) => ref.read(driverServiceProvider).loadWaitingOffers(),
  retry: (_, _) => null,
);

final driverDashboardProvider = FutureProvider<DriverDashboardData>(
  (ref) async => DriverDashboardData(
    account: await ref.watch(driverAccountProvider.future),
    activeOrder: await ref.watch(driverActiveOrderProvider.future),
    availableRequests: const [],
    waitingOffers: const [],
  ),
  retry: (_, _) => null,
);

final driverHistoryProvider = FutureProvider<List<DriverOrder>>((ref) async {
  final account = await ref.watch(driverAccountProvider.future);
  if (account == null) return const [];
  return ref.read(driverServiceProvider).loadHistory(account.id);
}, retry: (_, _) => null);

final driverEarningsProvider = FutureProvider<DriverEarningsData>((ref) async {
  final account = await ref.watch(driverAccountProvider.future);
  if (account == null) throw const ReadFailure(ReadFailureKind.unavailable);
  return DriverEarningsData(
    driverType: account.type,
    entries: await ref.read(driverServiceProvider).loadEarnings(),
  );
}, retry: (_, _) => null);

final driverOrderProvider = FutureProvider.autoDispose
    .family<DriverOrder, String>(
      (ref, orderId) => ref.read(driverServiceProvider).loadOrder(orderId),
      retry: (_, _) => null,
    );

final driverCustomerContactProvider = FutureProvider.autoDispose
    .family<DriverCustomerContact?, String>(
      (ref, orderId) =>
          ref.read(driverServiceProvider).loadCustomerContact(orderId),
      retry: (_, _) => null,
    );

final driverOfferProvider = FutureProvider.autoDispose
    .family<DriverOffer?, String>(
      (ref, orderId) => ref.read(driverServiceProvider).loadOffer(orderId),
      retry: (_, _) => null,
    );

final driverMutationProvider = ChangeNotifierProvider<MutationReconciler>(
  (ref) => MutationReconciler(),
);

enum DriverMutationRefresh { availability, offer, lifecycle, terminal }

// One reconciliation path for every sensitive Driver mutation.
Future<void> runDriverMutation(
  WidgetRef ref,
  Future<void> Function() mutate, {
  required DriverMutationRefresh refresh,
  String? orderId,
  required bool Function(DriverDashboardData, DriverOrder?, DriverOffer?)
  isApplied,
}) async {
  final container = ProviderScope.containerOf(ref.context, listen: false);
  final context = ref.context;
  final controller = container.read(driverMutationProvider);
  await controller.run(
    mutate: mutate,
    revalidateAuth: () =>
        container.read(authServiceProvider).revalidateSession(),
    refresh: () async {
      var account = container.read(driverAccountProvider).asData?.value;
      var activeOrder = container.read(driverActiveOrderProvider).asData?.value;
      DriverOffer? offer;
      DriverOrder? order;
      final reads = <Future<void>>[];

      if (refresh == DriverMutationRefresh.availability) {
        container
          ..invalidate(driverAccountProvider)
          ..invalidate(driverRequestsProvider);
        reads.add(
          container.read(driverAccountProvider.future).then((value) {
            account = value;
          }),
        );
      } else {
        container.invalidate(driverActiveOrderProvider);
        reads.add(
          container.read(driverActiveOrderProvider.future).then((value) {
            activeOrder = value;
          }),
        );
      }

      if (refresh == DriverMutationRefresh.offer && orderId != null) {
        container
          ..invalidate(driverOfferProvider(orderId))
          ..invalidate(driverWaitingOffersProvider)
          ..invalidate(driverRequestsProvider);
        reads.add(
          container.read(driverOfferProvider(orderId).future).then((value) {
            offer = value;
          }),
        );
      }

      if ((refresh == DriverMutationRefresh.lifecycle ||
              refresh == DriverMutationRefresh.terminal) &&
          orderId != null) {
        container.invalidate(driverOrderProvider(orderId));
        reads.add(() async {
          try {
            order = await container.read(driverOrderProvider(orderId).future);
          } on ReadFailure catch (error) {
            if (error.kind != ReadFailureKind.unavailable) rethrow;
            // Authoritative absence is a valid result after expiry/selection.
            // The provider renders the unavailable state, never a stale CTA.
          }
        }());
      }
      if (refresh == DriverMutationRefresh.terminal) {
        container
          ..invalidate(driverHistoryProvider)
          ..invalidate(driverRequestsProvider);
      }
      await Future.wait(reads);
      return isApplied(
        DriverDashboardData(
          account: account,
          activeOrder: activeOrder,
          availableRequests: const [],
          waitingOffers: const [],
        ),
        order,
        offer,
      );
    },
  );
  if (context.mounted &&
      !controller.blocksActions &&
      controller.error != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          controller.outcome == MutationOutcome.businessFailure
              ? driverErrorMessage(controller.error!)
              : 'تم التحقق من الحالة وتحديثها.',
        ),
      ),
    );
  }
}
