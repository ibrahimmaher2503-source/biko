import 'dart:convert';

import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
// Test-only use of Supabase's already-installed HTTP dependency.
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' show Response;
// ignore: depend_on_referenced_packages
import 'package:http/testing.dart' show MockClient;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/app/user_router.dart';
import 'package:user_app/app/user_theme.dart';
import 'package:user_app/features/orders/order_providers.dart';
import 'package:user_app/features/profile/profile_model.dart';
import 'package:user_app/features/profile/profile_provider.dart';

class _MemoryPkceStorage extends GotrueAsyncStorage {
  final _values = <String, String>{};

  @override
  Future<String?> getItem({required String key}) async => _values[key];

  @override
  Future<void> setItem({required String key, required String value}) async {
    _values[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    _values.remove(key);
  }
}

class _AuthEndpoint {
  late final SupabaseClient client;
  late final AuthService auth;

  final _user = <String, dynamic>{
    'id': 'aabbccdd-0000-4000-8000-000000000001',
    'aud': 'authenticated',
    'email': 'router@example.invalid',
    'created_at': '2026-09-08T00:00:00Z',
  };

  Future<void> start() async {
    client = SupabaseClient(
      'http://fixture.invalid',
      'fixture-only',
      authOptions: AuthClientOptions(
        autoRefreshToken: false,
        pkceAsyncStorage: _MemoryPkceStorage(),
      ),
      postgrestOptions: boundedPostgrestOptions,
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/token')) {
          String encode(Object value) => base64Url
              .encode(utf8.encode(jsonEncode(value)))
              .replaceAll('=', '');
          return Response(
            jsonEncode({
              'access_token':
                  '${encode({'alg': 'HS256'})}.${encode({'sub': _user['id'], 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600})}.fixture',
              'refresh_token': 'fixture-only',
              'token_type': 'bearer',
              'expires_in': 3600,
              'user': _user,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return Response(
          '{}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    auth = AuthService(client, recoveryRedirect: userRecoveryRedirect);
  }

  Future<void> signIn() => auth.signIn(
    email: 'router@example.invalid',
    password: 'fixture-password',
  );

  Future<void> recover() async {
    await auth.requestPasswordReset('router@example.invalid');
    await client.auth.getSessionFromUrl(
      Uri.parse('$userRecoveryRedirect?code=fixture-recovery-code'),
    );
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> close() async {
    auth.dispose();
    await client.dispose();
  }
}

Widget _routerApp(GoRouter router, AuthService auth) => ProviderScope(
  overrides: [
    authServiceProvider.overrideWithValue(auth),
    activeOrderProvider.overrideWith((_) async => null),
    orderHistoryProvider.overrideWith((_) async => const []),
    profileProvider.overrideWith(
      (_) async => const CustomerProfile(
        email: 'router@example.invalid',
        fullName: 'مستخدم الاختبار',
      ),
    ),
  ],
  child: MaterialApp.router(
    theme: buildUserTheme(),
    builder: (context, child) =>
        Directionality(textDirection: TextDirection.rtl, child: child!),
    routerConfig: router,
  ),
);

void main() {
  testWidgets('User router shows onboarding for a signed-out first launch', (
    tester,
  ) async {
    final endpoint = _AuthEndpoint();
    await tester.runAsync(endpoint.start);
    addTearDown(endpoint.close);
    final router = createUserRouter(
      authService: endpoint.auth,
      refreshListenable: endpoint.auth,
    );
    addTearDown(router.dispose);
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(_routerApp(router, endpoint.auth));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/auth');
    expect(find.text('مرحبًا بك في بيكو'), findsOneWidget);
  });

  testWidgets(
    'returning User router opens signup then an auth event replaces it with home',
    (tester) async {
      final endpoint = _AuthEndpoint();
      await tester.runAsync(endpoint.start);
      addTearDown(endpoint.close);
      final router = createUserRouter(
        authService: endpoint.auth,
        refreshListenable: endpoint.auth,
      );
      addTearDown(router.dispose);
      SharedPreferences.setMockInitialValues({'user_onboarding_seen_v1': true});

      await tester.pumpWidget(_routerApp(router, endpoint.auth));
      await tester.pumpAndSettle();
      expect(find.text('كيف تريد المتابعة؟'), findsOneWidget);
      await tester.tap(find.text('إنشاء حساب'));
      await tester.pumpAndSettle();
      expect(find.text('البريد الإلكتروني'), findsOneWidget);

      await tester.runAsync(endpoint.signIn);
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, '/home');
      expect(find.text('إلى أين؟'), findsOneWidget);
      expect(find.text('كيف تريد المتابعة؟'), findsNothing);
    },
  );

  testWidgets(
    'recovery event remains higher priority than onboarding and home',
    (tester) async {
      final endpoint = _AuthEndpoint();
      await tester.runAsync(endpoint.start);
      addTearDown(endpoint.close);
      final router = createUserRouter(
        authService: endpoint.auth,
        refreshListenable: endpoint.auth,
      );
      addTearDown(router.dispose);
      SharedPreferences.setMockInitialValues({'user_onboarding_seen_v1': true});

      await tester.pumpWidget(_routerApp(router, endpoint.auth));
      await tester.pumpAndSettle();
      await tester.runAsync(endpoint.recover);
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, '/auth/recovery');
      expect(find.text('تعيين كلمة مرور جديدة'), findsOneWidget);
    },
  );
}
