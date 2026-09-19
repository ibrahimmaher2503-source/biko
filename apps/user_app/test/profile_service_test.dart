import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:app_core/app_core.dart';
import 'package:flutter_test/flutter_test.dart';
// Test-only use of Supabase's already-installed HTTP dependency.
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' show Response;
// ignore: depend_on_referenced_packages
import 'package:http/testing.dart' show MockClient;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/features/profile/profile_model.dart';
import 'package:user_app/features/profile/profile_service.dart';

class _MemoryPkceStorage extends GotrueAsyncStorage {
  final _values = <String, String>{};

  @override
  Future<String?> getItem({required String key}) async => _values[key];

  @override
  Future<void> setItem({required String key, required String value}) async {
    _values[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async => _values.remove(key);
}

Future<SupabaseClient> _signedInClient(
  Future<Response> Function(Uri, String) reply,
) async {
  const userId = 'aabbccdd-0000-4000-8000-000000000001';
  String tokenPart(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final client = SupabaseClient(
    'http://fixture.invalid',
    'fixture-only',
    authOptions: AuthClientOptions(
      autoRefreshToken: false,
      pkceAsyncStorage: _MemoryPkceStorage(),
    ),
    httpClient: MockClient((request) async {
      if (request.url.path.endsWith('/token')) {
        return Response(
          jsonEncode({
            'access_token':
                '${tokenPart({'alg': 'HS256'})}.${tokenPart({'sub': userId, 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600})}.fixture',
            'refresh_token': 'fixture-only',
            'token_type': 'bearer',
            'expires_in': 3600,
            'user': {
              'id': userId,
              'aud': 'authenticated',
              'email': 'profile@example.invalid',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return reply(request.url, request.method);
    }),
  );
  await client.auth.signInWithPassword(
    email: 'profile@example.invalid',
    password: 'fixture-password',
  );
  return client;
}

const _profile = CustomerProfile(
  email: 'profile@example.invalid',
  fullName: 'عميل بيكو',
);

XFile _jpeg() => XFile.fromData(
  Uint8List.fromList([0xff, 0xd8, 0xff]),
  name: 'avatar.jpg',
  mimeType: 'image/jpeg',
);

void main() {
  test('save times out instead of leaving profile editing pending', () async {
    final client = await _signedInClient((url, _) async {
      if (url.path.contains('update_own_profile')) {
        return Completer<Response>().future;
      }
      return Response('{}', 200, headers: {'content-type': 'application/json'});
    });
    addTearDown(client.dispose);

    await expectLater(
      ProfileService(client, mutationTimeout: Duration.zero).save(
        current: _profile,
        fullName: 'اسم جديد',
        phone: null,
        removePhoto: false,
      ),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('failed upload does not call the profile RPC', () async {
    var rpcCalls = 0;
    final client = await _signedInClient((url, _) async {
      if (url.path.contains('update_own_profile')) rpcCalls++;
      return Response('{}', 500, headers: {'content-type': 'application/json'});
    });
    addTearDown(client.dispose);

    await expectLater(
      ProfileService(client).save(
        current: _profile,
        fullName: 'اسم جديد',
        phone: null,
        newPhoto: _jpeg(),
        removePhoto: false,
      ),
      throwsA(isA<Object>()),
    );
    expect(rpcCalls, 0);
  });

  test('session switch after upload prevents the profile RPC', () async {
    late SupabaseClient client;
    var rpcCalls = 0;
    client = await _signedInClient((url, _) async {
      if (url.path.contains('update_own_profile')) rpcCalls++;
      if (url.path.contains('/storage/v1/object/profile-photos/')) {
        await client.auth.signOut();
        return Response(
          '{"Key":"uploaded"}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return Response('{}', 200, headers: {'content-type': 'application/json'});
    });
    addTearDown(client.dispose);

    await expectLater(
      ProfileService(client).save(
        current: _profile,
        fullName: 'اسم جديد',
        phone: null,
        newPhoto: _jpeg(),
        removePhoto: false,
      ),
      throwsA(isA<ReadFailure>()),
    );
    expect(rpcCalls, 0);
  });

  test(
    'RPC timeout after upload preserves the photo for a possible late commit',
    () async {
      var deleteCalls = 0;
      var uploadCalls = 0;
      var rpcCalls = 0;
      final client = await _signedInClient((url, method) async {
        if (url.path.contains('update_own_profile')) {
          rpcCalls++;
          return Completer<Response>().future;
        }
        if (url.path.contains('/storage/v1/object/profile-photos/')) {
          if (method == 'DELETE') deleteCalls++;
          if (method != 'DELETE') uploadCalls++;
          return Response(
            '{"Key":"uploaded"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return Response(
          '{}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      addTearDown(client.dispose);

      await expectLater(
        ProfileService(client, mutationTimeout: Duration.zero).save(
          current: _profile,
          fullName: 'اسم جديد',
          phone: null,
          newPhoto: _jpeg(),
          removePhoto: false,
        ),
        throwsA(isA<TimeoutException>()),
      );
      expect(uploadCalls, 1);
      expect(rpcCalls, 1);
      expect(deleteCalls, 0);
    },
  );
}
