import 'dart:async';

import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/app/user_router.dart';
import 'package:user_app/app/user_theme.dart';
import 'package:user_app/features/orders/order_providers.dart';
import 'package:user_app/features/orders/order_rules.dart';
import 'package:user_app/features/notifications/realtime_events.dart';
import 'package:user_app/features/notifications/notification_routing.dart';
import 'package:user_app/features/profile/profile_provider.dart';

class UserApp extends ConsumerStatefulWidget {
  const UserApp({required this.configured, this.push, super.key});

  final bool configured;
  final PushNotifications? push;

  @override
  ConsumerState<UserApp> createState() => _UserAppState();
}

class _UserAppState extends ConsumerState<UserApp> with WidgetsBindingObserver {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  final _stateEvents = OperationalEventDedupe();
  final _routeEvents = OperationalEventDedupe();
  AuthService? _auth;
  GoRouter? _router;
  UserRealtimeEvents? _operations;
  VoidCallback? _sessionListener;
  String? _promptedUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.configured) {
      final auth = ref.read(authServiceProvider);
      _auth = auth;
      _operations = UserRealtimeEvents(
        Supabase.instance.client,
        onEvent: _refreshForEvent,
        onRecovery: _recoverOperationalState,
      );
      _router = createUserRouter(authService: auth, refreshListenable: auth);
      var userId = auth.isSignedIn ? auth.currentSession?.user.id : null;
      _sessionListener = () {
        final nextId = auth.isSignedIn ? auth.currentSession?.user.id : null;
        if (nextId == userId) return;
        userId = nextId;
        _stateEvents.clear();
        _routeEvents.clear();
        ref
          ..invalidate(activeOrderProvider)
          ..invalidate(orderHistoryProvider)
          ..invalidate(orderHistoryPageProvider)
          ..invalidate(profileProvider);
        if (nextId == null) {
          unawaited(_operations!.stop());
        } else {
          unawaited(_startSession(nextId));
        }
      };
      auth.addListener(_sessionListener!);
      if (userId != null) unawaited(_startSession(userId!));
      if (widget.push != null) {
        unawaited(
          widget.push!
              .initialize(
                onForeground: (event) async {
                  final changed = await _refreshForEvent(event);
                  return changed &&
                      _router?.routeInformationProvider.value.uri.path !=
                          '/home';
                },
                onOpen: _openNotification,
              )
              .then((_) async {
                if (auth.isSignedIn) {
                  await widget.push!.processPendingLaunch();
                  await _offerNotificationPermission(
                    auth.currentSession!.user.id,
                  );
                }
              }),
        );
      }
    }
  }

  Future<void> _startSession(String userId) async {
    await _operations!.start(userId);
    await widget.push?.registerWhenAlreadyAllowed();
    await widget.push?.processPendingLaunch();
    await _offerNotificationPermission(userId);
  }

  Future<void> _offerNotificationPermission(String userId) async {
    if (widget.push == null || _promptedUserId == userId || !mounted) return;
    _promptedUserId = userId;
    try {
      if (await widget.push!.permission() !=
          BikoNotificationPermission.notDetermined) {
        return;
      }
    } catch (_) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: const Text('فعّل الإشعارات لتصلك العروض وتحديثات طلبك.'),
          duration: const Duration(seconds: 12),
          action: SnackBarAction(
            label: 'تفعيل',
            onPressed: () => unawaited(_requestNotificationPermission()),
          ),
        ),
      );
    });
  }

  Future<void> _requestNotificationPermission() async {
    BikoNotificationPermission result;
    try {
      result = await widget.push!.requestPermissionAndRegister();
    } catch (_) {
      return;
    }
    if (result == BikoNotificationPermission.denied) {
      _messengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('يمكنك تفعيل الإشعارات لاحقًا من إعدادات الهاتف.'),
        ),
      );
    }
  }

  Future<bool> _refreshForEvent(OperationalNotification event) async {
    if (!_stateEvents.take(event.id)) return false;
    final resources = userResourcesFor(event);
    if (resources.contains(UserOperationalResource.activeOrder)) {
      ref.invalidate(activeOrderProvider);
    }
    if (resources.contains(UserOperationalResource.history)) {
      ref
        ..invalidate(orderHistoryProvider)
        ..invalidate(orderHistoryPageProvider);
    }
    try {
      await ref.read(activeOrderProvider.future);
    } catch (_) {
      // The provider owns its typed recovery UI.
    }
    return true;
  }

  Future<void> _recoverOperationalState() async {
    ref
      ..invalidate(activeOrderProvider)
      ..invalidate(orderHistoryProvider)
      ..invalidate(orderHistoryPageProvider);
    try {
      await ref.read(activeOrderProvider.future);
    } catch (_) {
      // Reconnect never invalidates the authenticated session.
    }
  }

  Future<void> _openNotification(OperationalNotification event) async {
    if (!_routeEvents.take(event.id) || _auth?.isSignedIn != true) return;
    final orderId = event.orderId;
    if (orderId == null) {
      _router?.go('/home');
      return;
    }
    var terminal = false;
    try {
      final order = await ref.read(orderServiceProvider).loadOrder(orderId);
      ref.invalidate(activeOrderProvider);
      terminal = isTerminalOrder(order.status);
      if (terminal) {
        ref
          ..invalidate(orderHistoryProvider)
          ..invalidate(orderHistoryPageProvider);
      }
    } catch (_) {
      // A stale or inaccessible target always falls back to owned current state.
    }
    _router?.go(
      userRouteForOrderNotification(orderId: orderId, terminal: terminal),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_sessionListener != null) _auth?.removeListener(_sessionListener!);
    unawaited(_operations?.stop());
    unawaited(widget.push?.dispose());
    _router?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.configured) {
      ref
        ..invalidate(activeOrderProvider)
        ..invalidate(orderHistoryProvider)
        ..invalidate(orderHistoryPageProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = buildUserTheme();

    if (!widget.configured) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'بيكو',
        theme: theme,
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: const _SetupRequiredPage(),
      );
    }

    return MaterialApp.router(
      scaffoldMessengerKey: _messengerKey,
      debugShowCheckedModeBanner: false,
      title: 'بيكو',
      theme: theme,
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: AuthSessionBoundary(child: child!),
      ),
      routerConfig: _router!,
    );
  }
}

class _SetupRequiredPage extends StatelessWidget {
  const _SetupRequiredPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('أضف إعدادات Supabase لتفعيل تسجيل الدخول.'),
        ),
      ),
    );
  }
}
