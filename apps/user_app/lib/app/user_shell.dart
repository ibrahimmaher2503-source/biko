import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/core/widgets/feedback_widgets.dart';
import 'package:user_app/features/orders/order_status_page.dart';
import 'package:user_app/features/orders/order_providers.dart';
import 'package:user_app/features/orders/order_history_view.dart';
import 'package:user_app/features/home/home_view.dart';
import 'package:user_app/features/profile/profile_view.dart';

class UserRootPage extends ConsumerWidget {
  const UserRootPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeOrder = ref.watch(activeOrderProvider);
    return activeOrder.when(
      loading: () => const Scaffold(body: SafeArea(child: LoadingSkeleton())),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('بيكو')),
        body: UserErrorState(
          message: classifyReadError(error).message,
          onRetry: () => ref.invalidate(activeOrderProvider),
          footer: const SafeSignOutButton(),
        ),
      ),
      data: (order) => order == null
          ? const UserShell()
          : OrderStatusPage(key: ValueKey(order.id), initialOrder: order),
    );
  }
}

class UserShell extends ConsumerStatefulWidget {
  const UserShell({super.key});

  @override
  ConsumerState<UserShell> createState() => _UserShellState();
}

class _UserShellState extends ConsumerState<UserShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeView(
        onRide: () => context.push('/book/ride'),
        onDelivery: () => context.push('/book/delivery'),
        onCreateDraft: (draft) => context.push(
          '/book/${draft.service == ServiceType.ride ? 'ride' : 'delivery'}',
          extra: draft,
        ),
        onHistory: () => setState(() => _index = 1),
        onBookAgain: (draft) => context.push(
          '/book/${draft.service == ServiceType.ride ? 'ride' : 'delivery'}',
          extra: draft,
        ),
      ),
      const OrderHistoryView(),
      const ProfileView(),
    ];
    return Scaffold(
      appBar: AppTopBar(
        title: switch (_index) {
          0 => 'بيكو',
          1 => 'طلباتي',
          _ => 'الحساب',
        },
      ),
      body: SafeArea(
        child: IndexedStack(index: _index, children: pages),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'طلباتي',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'الحساب',
          ),
        ],
      ),
    );
  }
}
