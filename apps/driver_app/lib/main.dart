import 'dart:async';

import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/driver/driver_screens.dart';
import 'features/driver/driver_operational_events.dart';
import 'features/driver/driver_providers.dart';
import 'features/driver/driver_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final configured = AppEnvironment.hasSupabase;

  PushNotifications? push;
  if (configured) {
    await Supabase.initialize(
      url: AppEnvironment.supabaseUrl,
      publishableKey: AppEnvironment.supabasePublishableKey,
      postgrestOptions: boundedPostgrestOptions,
      debug: false,
    );
    try {
      if (await initializeBikoFirebase()) {
        push = PushNotifications(Supabase.instance.client, appKind: 'DRIVER');
      }
    } catch (_) {
      // External Firebase configuration is optional for core app startup.
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        authRecoveryRedirectProvider.overrideWithValue(driverRecoveryRedirect),
        if (push != null)
          pushTokenCleanupProvider.overrideWithValue(push.revokeCurrentToken),
      ],
      child: DriverApp(configured: configured, push: push),
    ),
  );
}

class DriverApp extends ConsumerStatefulWidget {
  const DriverApp({required this.configured, this.push, super.key});

  final bool configured;
  final PushNotifications? push;

  @override
  ConsumerState<DriverApp> createState() => _DriverAppState();
}

class _DriverAppState extends ConsumerState<DriverApp>
    with WidgetsBindingObserver {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  final _stateEvents = OperationalEventDedupe();
  final _routeEvents = OperationalEventDedupe();
  AuthService? _auth;
  GoRouter? _router;
  VoidCallback? _sessionListener;
  DriverOperationalEvents? _operations;
  String? _promptedUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.configured) {
      final auth = ref.read(authServiceProvider);
      _auth = auth;
      _operations = DriverOperationalEvents(
        Supabase.instance.client,
        onEvent: _refreshForEvent,
        onRecovery: _recoverOperationalState,
      );
      var userId = auth.isSignedIn ? auth.currentSession?.user.id : null;
      _sessionListener = () {
        final nextId = auth.isSignedIn ? auth.currentSession?.user.id : null;
        if (nextId != userId) {
          userId = nextId;
          ref.invalidate(driverAccountProvider);
          ref.invalidate(driverActiveOrderProvider);
          ref.invalidate(driverRequestsProvider);
          ref.invalidate(driverWaitingOffersProvider);
          ref.invalidate(driverDashboardProvider);
          ref.invalidate(driverHistoryProvider);
          ref.invalidate(driverEarningsProvider);
          ref.invalidate(driverOrderProvider);
          ref.invalidate(driverOfferProvider);
          ref.invalidate(driverVerificationProvider);
          ref.read(driverMutationProvider).resetForSessionChange();
          _stateEvents.clear();
          _routeEvents.clear();
          if (nextId == null) {
            unawaited(_operations!.stop());
          } else {
            unawaited(_startSession(nextId));
          }
        }
      };
      auth.addListener(_sessionListener!);
      if (userId != null) unawaited(_startSession(userId!));
      _router = createAuthRouter(
        authService: auth,
        refreshListenable: auth,
        authBuilder: (context) => const EmailPasswordAuthPage(
          appName: 'بيكو للسائق',
          description: 'سجل دخولك للوصول إلى تطبيق السائق.',
          accentColor: DriverColors.primary,
        ),
        homeBuilder: (context) => const DriverHomeScreen(),
        authenticatedInitialLocation: '/restore',
        authenticatedRoutes: [
          GoRoute(
            path: '/restore',
            builder: (context, state) => const DriverBootstrapScreen(),
          ),
          GoRoute(
            path: '/history',
            builder: (context, state) => const DriverHistoryScreen(),
          ),
          GoRoute(
            path: '/earnings',
            builder: (context, state) => const DriverEarningsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const DriverProfileScreen(),
          ),
          GoRoute(
            path: '/verification',
            builder: (context, state) => const DriverVerificationScreen(),
          ),
          GoRoute(
            path: '/onboarding',
            builder: (context, state) => DriverOnboardingScreen(
              onSubmit: (application) async {
                await ref
                    .read(driverServiceProvider)
                    .submitIndependentDriverApplication(
                      fullName: application.fullName,
                      phone: application.phone,
                      dateOfBirth: application.dateOfBirth,
                      plateNumber: application.plateNumber,
                      brand: application.brand,
                      model: application.model,
                      color: application.color,
                      modelYear: application.modelYear,
                    );
                ref
                  ..invalidate(driverAccountProvider)
                  ..invalidate(driverActiveOrderProvider)
                  ..invalidate(driverDashboardProvider)
                  ..invalidate(driverVerificationProvider);
              },
              onSubmitted: () => context.go('/restore'),
            ),
          ),
          GoRoute(
            path: '/request/:orderId',
            builder: (context, state) =>
                RequestDetailsScreen(orderId: state.pathParameters['orderId']!),
          ),
          GoRoute(
            path: '/waiting/:orderId',
            builder: (context, state) =>
                OfferWaitingScreen(orderId: state.pathParameters['orderId']!),
          ),
          GoRoute(
            path: '/active-order/:orderId',
            builder: (context, state) =>
                ActiveOrderScreen(orderId: state.pathParameters['orderId']!),
          ),
        ],
      );
      if (widget.push != null) {
        unawaited(
          widget.push!
              .initialize(
                onForeground: (event) async {
                  final changed = await _refreshForEvent(event);
                  final path =
                      _router?.routeInformationProvider.value.uri.path ?? '';
                  return changed &&
                      path != '/home' &&
                      !path.contains(event.orderId ?? '#');
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
          content: const Text('فعّل الإشعارات لتصلك الطلبات وتحديثات رحلتك.'),
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
    final resources = driverResourcesFor(event);
    if (resources.contains(DriverOperationalResource.verification)) {
      ref.invalidate(driverVerificationProvider);
      try {
        await ref.read(driverVerificationProvider.future);
      } catch (_) {
        // The verification screen renders the authoritative reason.
      }
      return true;
    }
    if (resources.length == 1 &&
        resources.contains(DriverOperationalResource.requests)) {
      ref.invalidate(driverRequestsProvider);
      try {
        await ref.read(driverRequestsProvider.future);
      } catch (_) {
        // Geographic discovery remains authoritative and renders its own error.
      }
      return true;
    }
    if (resources.contains(DriverOperationalResource.activeOrder)) {
      ref.invalidate(driverActiveOrderProvider);
    }
    final orderId = event.orderId;
    if (orderId != null &&
        resources.contains(DriverOperationalResource.order)) {
      ref.invalidate(driverOrderProvider(orderId));
    }
    if (orderId != null &&
        resources.contains(DriverOperationalResource.offer)) {
      ref.invalidate(driverOfferProvider(orderId));
    }
    if (resources.contains(DriverOperationalResource.waitingOffers)) {
      ref.invalidate(driverWaitingOffersProvider);
    }
    if (resources.contains(DriverOperationalResource.history)) {
      ref.invalidate(driverHistoryProvider);
    }
    try {
      await ref.read(driverActiveOrderProvider.future);
    } catch (_) {
      // The provider owns its typed recovery UI.
    }
    return true;
  }

  Future<void> _recoverOperationalState() async {
    ref
      ..invalidate(driverActiveOrderProvider)
      ..invalidate(driverRequestsProvider)
      ..invalidate(driverWaitingOffersProvider);
    try {
      await Future.wait([
        ref.read(driverActiveOrderProvider.future),
        ref.read(driverRequestsProvider.future),
        ref.read(driverWaitingOffersProvider.future),
      ]);
    } catch (_) {
      // Reconnect never invalidates the authenticated session.
    }
  }

  Future<void> _openNotification(OperationalNotification event) async {
    if (!_routeEvents.take(event.id) || _auth?.isSignedIn != true) return;
    final service = ref.read(driverServiceProvider);
    final orderId = event.orderId;
    var accountLoaded = false;
    var hasDriver = false;
    try {
      if (event.targetType == 'PROFILE') {
        _router?.go('/verification');
        return;
      }
      if (event.targetType == 'REQUESTS' && orderId != null) {
        await service.loadOrder(orderId);
        _router?.go('/request/$orderId');
        return;
      }
      if (event.targetType == 'WAITING_OFFER' && orderId != null) {
        final offer = await service.loadOffer(orderId);
        if (offer?.status == OfferStatus.active) {
          _router?.go('/waiting/$orderId');
          return;
        }
      }
      final account = await service.loadAccount();
      accountLoaded = true;
      hasDriver = account != null;
      final active = account == null
          ? null
          : await service.loadActiveOrder(account.id);
      if (active != null && (orderId == null || active.id == orderId)) {
        _router?.go('/active-order/${active.id}');
        return;
      }
    } catch (_) {
      // Stale, geographically ineligible, or inaccessible targets fall home.
    }
    _router?.go(accountLoaded && !hasDriver ? '/onboarding' : '/home');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router?.dispose();
    if (_sessionListener != null) _auth?.removeListener(_sessionListener!);
    unawaited(_operations?.stop());
    unawaited(widget.push?.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.configured) {
      ref
        ..invalidate(driverActiveOrderProvider)
        ..invalidate(driverRequestsProvider)
        ..invalidate(driverWaitingOffersProvider)
        ..invalidate(driverOrderProvider)
        ..invalidate(driverOfferProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = buildDriverTheme();

    if (!widget.configured) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'بيكو للسائق',
        theme: theme,
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: const _SetupRequiredPage(),
      );
    }

    return MaterialApp.router(
      scaffoldMessengerKey: _messengerKey,
      debugShowCheckedModeBanner: false,
      title: 'بيكو للسائق',
      theme: theme,
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: AuthSessionBoundary(
          child: DriverRecoveryBoundary(
            onProfile: () => _router!.go('/profile'),
            child: child!,
          ),
        ),
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
