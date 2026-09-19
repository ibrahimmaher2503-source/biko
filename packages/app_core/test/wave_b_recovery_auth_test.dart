import 'dart:async';
import 'dart:convert';

import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// Test-only use of Supabase's already-installed HTTP dependency.
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' show Response;
// ignore: depend_on_referenced_packages
import 'package:http/testing.dart' show MockClient;
import 'package:supabase_flutter/supabase_flutter.dart';

class MemoryPkceStorage extends GotrueAsyncStorage {
  final values = <String, String>{};
  @override
  Future<String?> getItem({required String key}) async => values[key];
  @override
  Future<void> setItem({required String key, required String value}) async {
    values[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    values.remove(key);
  }
}

// SDK boundary only: no hosted users, mail, tokens or credentials.
class AuthEndpoint {
  late SupabaseClient client;
  late AuthService auth;
  final updates = <Map<String, dynamic>>[];
  String? redirect;
  bool rejectUser = false;
  bool holdUpdate = false;
  Completer<void> updateGate = Completer<void>();
  final user = <String, dynamic>{
    'id': 'aabbccdd-0000-4000-8000-000000000001',
    'aud': 'authenticated',
    'email': 'wave-b@example.invalid',
    'created_at': '2026-08-30T00:00:00Z',
  };

  Future<void> start() async {
    final httpClient = MockClient((request) async {
      final data = request.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(request.body) as Map<String, dynamic>;
      Object response = <String, dynamic>{};
      var status = 200;
      if (request.url.path.endsWith('/recover')) {
        redirect = request.url.queryParameters['redirect_to'];
      } else if (request.url.path.endsWith('/token')) {
        expect(data['auth_code'], 'test-recovery-code');
        expect(data['code_verifier'], isNotEmpty);
        String encode(Object value) => base64Url
            .encode(utf8.encode(jsonEncode(value)))
            .replaceAll('=', '');
        response = {
          'access_token':
              '${encode({'alg': 'HS256'})}.${encode({'sub': user['id'], 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600})}.fixture',
          'refresh_token': 'fixture-only',
          'token_type': 'bearer',
          'expires_in': 3600,
          'user': user,
        };
      } else if (request.url.path.endsWith('/user')) {
        if (request.method == 'PUT') {
          updates.add(data);
          if (holdUpdate) await updateGate.future;
        }
        if (rejectUser) {
          status = 401;
          response = {
            'code': 'session_not_found',
            'msg': 'private internal detail',
          };
        } else {
          response = user;
        }
      }
      return Response(
        jsonEncode(response),
        status,
        headers: {'content-type': 'application/json'},
      );
    });
    client = SupabaseClient(
      'http://fixture.invalid',
      'fixture-only',
      authOptions: AuthClientOptions(
        autoRefreshToken: false,
        pkceAsyncStorage: MemoryPkceStorage(),
      ),
      postgrestOptions: boundedPostgrestOptions,
      httpClient: httpClient,
    );
    auth = AuthService(client, recoveryRedirect: driverRecoveryRedirect);
  }

  Future<void> recover() async {
    await auth.requestPasswordReset('wave-b@example.invalid');
    await client.auth.getSessionFromUrl(
      Uri.parse('$driverRecoveryRedirect?code=test-recovery-code'),
    );
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> close() async {
    if (!updateGate.isCompleted) updateGate.complete();
    auth.dispose();
    await client.dispose();
  }
}

void main() {
  test(
    'never-settling mutation is uncertain; unchanged read cannot unlock; late commit read recovers once',
    () async {
      final controller = MutationReconciler(
        mutationTimeout: const Duration(milliseconds: 5),
        readTimeout: const Duration(milliseconds: 5),
      );
      addTearDown(controller.dispose);
      final write = Completer<void>();
      var writes = 0;
      var committed = false;
      await controller.run(
        mutate: () {
          writes++;
          return write.future;
        },
        refresh: () async => committed,
        revalidateAuth: () async {},
      );
      expect(controller.outcome, MutationOutcome.uncertain);
      expect(controller.phase, RecoveryPhase.unavailable);
      expect(controller.isWaiting, isFalse);
      await controller.run(
        mutate: () async {
          writes++;
        },
        refresh: () async => true,
        revalidateAuth: () async {},
      );
      expect(writes, 1);
      committed = true;
      write.complete();
      await controller.retryRead();
      expect(controller.phase, RecoveryPhase.idle);
      expect(writes, 1);
    },
  );

  test(
    'never-settling reads exhaust exactly two attempts; retry remains read only',
    () async {
      final controller = MutationReconciler(
        readTimeout: const Duration(milliseconds: 5),
      );
      addTearDown(controller.dispose);
      var reads = 0;
      var writes = 0;
      var connected = false;
      await controller.run(
        mutate: () async {
          writes++;
          throw TimeoutException('lost response after commit');
        },
        refresh: () {
          reads++;
          return connected ? Future.value(true) : Completer<bool>().future;
        },
        revalidateAuth: () async {},
      );
      expect(reads, 2);
      expect(controller.phase, RecoveryPhase.unavailable);
      expect(controller.isWaiting, isFalse);
      connected = true;
      await controller.retryRead();
      expect(reads, 3);
      expect(writes, 1);
      expect(controller.blocksActions, isFalse);
    },
  );

  test(
    'commit-before-timeout reconciles without replay; disposed completion is ignored',
    () async {
      final controller = MutationReconciler(
        mutationTimeout: const Duration(milliseconds: 5),
      );
      var committed = false;
      var writes = 0;
      await controller.run(
        mutate: () {
          writes++;
          committed = true;
          return Completer<void>().future;
        },
        refresh: () async => committed,
        revalidateAuth: () async {},
      );
      expect(controller.outcome, MutationOutcome.uncertain);
      expect(controller.phase, RecoveryPhase.idle);
      expect(writes, 1);
      controller.dispose();
      final late = Completer<void>();
      final disposed = MutationReconciler();
      var reads = 0;
      final run = disposed.run(
        mutate: () => late.future,
        refresh: () async {
          reads++;
          return true;
        },
        revalidateAuth: () async {},
      );
      disposed.dispose();
      late.complete();
      await run;
      expect(reads, 0);
    },
  );

  test(
    'typed read errors never flatten permission/session/absence into connection',
    () {
      final cases = <Object, ReadFailureKind>{
        const PostgrestException(message: 'private', code: 'P0002'):
            ReadFailureKind.unavailable,
        const PostgrestException(message: 'private', code: '42501'):
            ReadFailureKind.forbidden,
        const PostgrestException(message: 'private', code: 'PGRST301'):
            ReadFailureKind.auth,
        TimeoutException('private'): ReadFailureKind.connection,
        const FormatException('private'): ReadFailureKind.unknown,
      };
      for (final entry in cases.entries) {
        final failure = classifyReadError(entry.key);
        expect(failure.kind, entry.value);
        expect(failure.message, isNot(contains('private')));
      }
    },
  );

  test('installed PostgREST transport is finite with no automatic replay', () {
    expect(boundedPostgrestOptions.requestTimeout, transportTimeout);
    expect(boundedPostgrestOptions.requestTimeout, isNotNull);
    expect(boundedPostgrestOptions.retryEnabled, isFalse);
    expect(boundedPostgrestOptions.retryCount, 3);
  });

  test(
    'real SDK PKCE recovery completes; invalid session and duplicate submits denied',
    () async {
      final endpoint = AuthEndpoint();
      await endpoint.start();
      addTearDown(endpoint.close);
      await expectLater(
        endpoint.auth.completePasswordRecovery('abcdef', 'abcdef'),
        throwsA(isA<AuthException>()),
      );
      await endpoint.recover();
      expect(endpoint.redirect, driverRecoveryRedirect);
      expect(endpoint.auth.canResetPassword, isTrue);
      await expectLater(
        endpoint.auth.completePasswordRecovery('abc', 'abc'),
        throwsA(isA<AuthException>()),
      );
      await expectLater(
        endpoint.auth.completePasswordRecovery('abcdef', 'different'),
        throwsA(isA<AuthException>()),
      );
      endpoint.holdUpdate = true;
      final first = endpoint.auth.completePasswordRecovery(
        'new-test-password',
        'new-test-password',
      );
      await endpoint.auth.completePasswordRecovery(
        'new-test-password',
        'new-test-password',
      );
      endpoint.updateGate.complete();
      await first;
      expect(endpoint.updates, hasLength(1));
      expect(endpoint.updates.single['password'], 'new-test-password');
      expect(endpoint.auth.recoveryCompleted, isTrue);
      endpoint.auth.finishRecovery();
      expect(endpoint.auth.hasRecoveryFlow, isFalse);
      await expectLater(
        endpoint.auth.completePasswordRecovery('abcdef', 'abcdef'),
        throwsA(isA<AuthException>()),
      );
    },
  );

  test(
    'SDK Auth error channel preserves retryable session, invalid session enters safe recovery',
    () async {
      final endpoint = AuthEndpoint();
      await endpoint.start();
      addTearDown(endpoint.close);
      await endpoint.recover();
      endpoint.auth.finishRecovery();
      // Inject through the SDK stream, not a fake application notifier.
      // ignore: invalid_use_of_internal_member
      endpoint.client.auth.notifyException(
        AuthRetryableFetchException(message: 'private', statusCode: '503'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(endpoint.auth.isSignedIn, isTrue);
      expect(endpoint.auth.sessionMessage, contains('الاتصال'));
      expect(endpoint.auth.sessionMessage, isNot(contains('private')));
      // ignore: invalid_use_of_internal_member
      endpoint.client.auth.notifyException(
        const AuthException(
          'private',
          statusCode: '401',
          code: 'session_not_found',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(endpoint.auth.isSignedIn, isFalse);
      expect(endpoint.auth.hasRecoveryFlow, isFalse);
      expect(endpoint.auth.sessionMessage, contains('انتهت الجلسة'));
    },
  );

  testWidgets(
    'recovery callback routes to validated password form then safe success and home',
    (tester) async {
      final endpoint = AuthEndpoint();
      await tester.runAsync(endpoint.start);
      addTearDown(endpoint.close);
      final router = createAuthRouter(
        authService: endpoint.auth,
        refreshListenable: endpoint.auth,
        authBuilder: (_) => const Scaffold(body: Text('SIGN IN')),
        homeBuilder: (_) => const Scaffold(body: Text('HOME')),
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authServiceProvider.overrideWithValue(endpoint.auth)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      router.go('/auth/recovery');
      await tester.pumpAndSettle();
      expect(find.text('SIGN IN'), findsOneWidget);
      await tester.runAsync(endpoint.recover);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/auth/recovery');
      expect(
        tester.widget<TextField>(find.byType(TextField).first).obscureText,
        isTrue,
      );
      await tester.tap(find.byTooltip('إظهار كلمة المرور'));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField).first).obscureText,
        isFalse,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).last).obscureText,
        isTrue,
      );
      await tester.tap(find.byTooltip('إظهار تأكيد كلمة المرور'));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField).last).obscureText,
        isFalse,
      );
      await tester.enterText(find.byType(TextFormField).first, 'short');
      await tester.tap(find.text('حفظ كلمة المرور'));
      await tester.pump();
      expect(find.text('كلمة المرور 6 أحرف على الأقل.'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).first,
        'new-test-password',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'new-test-password',
      );
      await tester.runAsync(() async {
        await tester.tap(find.text('حفظ كلمة المرور'));
        // Complete actual loopback transport outside the fake widget clock.
        for (var i = 0; i < 50 && !endpoint.auth.recoveryCompleted; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      await tester.pumpAndSettle();
      expect(find.text('تم تحديث كلمة المرور بنجاح.'), findsOneWidget);
      await tester.tap(find.text('متابعة'));
      await tester.pumpAndSettle();
      expect(find.text('HOME'), findsOneWidget);
      expect(endpoint.updates, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );
}
