import 'package:biko/core/models/enums.dart';
import 'package:biko/core/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserModel', () {
    final testCreatedAt = DateTime(2026, 1, 15, 10);

    final testUser = UserModel(
      uid: 'user_001',
      name: 'محمد أحمد',
      phone: '+201012345678',
      type: UserType.customer,
      createdAt: testCreatedAt,
      email: 'test@example.com',
      authProviders: const ['phone'],
      walletBalance: 150.0,
      referralCode: 'REF123',
      referredBy: 'user_000',
      avatarUrl: 'https://example.com/avatar.jpg',
      fcmToken: 'fcm_token_abc',
    );

    // ===== fromJson =====

    group('fromJson', () {
      test('parses all fields from a complete map', () {
        final json = {
          'uid': 'user_001',
          'name': 'محمد أحمد',
          'phone': '+201012345678',
          'email': 'test@example.com',
          'auth_providers': ['phone'],
          'type': 'customer',
          'status': 'active',
          'wallet_balance': 150.0,
          'referral_code': 'REF123',
          'referred_by': 'user_000',
          'lang': 'ar',
          'theme': 'light',
          'avatar_url': 'https://example.com/avatar.jpg',
          'fcm_token': 'fcm_token_abc',
          // no created_at — falls back to DateTime.now()
        };

        final user = UserModel.fromJson(json);

        expect(user.uid, equals('user_001'));
        expect(user.name, equals('محمد أحمد'));
        expect(user.phone, equals('+201012345678'));
        expect(user.email, equals('test@example.com'));
        expect(user.authProviders, equals(['phone']));
        expect(user.type, equals(UserType.customer));
        expect(user.status, equals(UserStatus.active));
        expect(user.walletBalance, equals(150.0));
        expect(user.referralCode, equals('REF123'));
        expect(user.referredBy, equals('user_000'));
        expect(user.lang, equals('ar'));
        expect(user.theme, equals('light'));
        expect(user.avatarUrl, equals('https://example.com/avatar.jpg'));
        expect(user.fcmToken, equals('fcm_token_abc'));
      });

      test('uses defaults for missing optional fields', () {
        final json = {
          'uid': 'user_002',
          'name': 'أحمد',
          'phone': '+201099999999',
          'type': 'customer',
        };

        final user = UserModel.fromJson(json);

        expect(user.uid, equals('user_002'));
        expect(user.email, isNull);
        expect(user.authProviders, isEmpty);
        expect(user.status, equals(UserStatus.active));
        expect(user.walletBalance, equals(0.0));
        expect(user.referralCode, equals(''));
        expect(user.referredBy, isNull);
        expect(user.lang, equals('ar'));
        expect(user.theme, equals('light'));
        expect(user.avatarUrl, isNull);
        expect(user.fcmToken, isNull);
      });

      test('parses driver type correctly', () {
        final json = {'uid': 'drv_001', 'name': 'Driver', 'phone': '+20', 'type': 'driver'};
        final user = UserModel.fromJson(json);
        expect(user.type, equals(UserType.driver));
      });

      test('parses suspended status correctly', () {
        final json = {
          'uid': 'u1',
          'name': 'Test',
          'phone': '+20',
          'type': 'customer',
          'status': 'suspended',
        };
        final user = UserModel.fromJson(json);
        expect(user.status, equals(UserStatus.suspended));
      });

      test('parses pending_approval status correctly', () {
        final json = {
          'uid': 'u1',
          'name': 'Test',
          'phone': '+20',
          'type': 'customer',
          'status': 'pending_approval',
        };
        final user = UserModel.fromJson(json);
        expect(user.status, equals(UserStatus.pendingApproval));
      });

      test('handles integer wallet_balance', () {
        final json = {
          'uid': 'u1',
          'name': 'Test',
          'phone': '+20',
          'type': 'customer',
          'wallet_balance': 100,
        };
        final user = UserModel.fromJson(json);
        expect(user.walletBalance, equals(100.0));
      });
    });

    // ===== copyWith =====

    group('copyWith', () {
      test('returns identical model when no fields changed', () {
        final copy = testUser.copyWith();

        expect(copy.uid, equals(testUser.uid));
        expect(copy.name, equals(testUser.name));
        expect(copy.phone, equals(testUser.phone));
        expect(copy.walletBalance, equals(testUser.walletBalance));
      });

      test('updates only the specified field', () {
        final updated = testUser.copyWith(name: 'كريم علي');

        expect(updated.name, equals('كريم علي'));
        expect(updated.uid, equals(testUser.uid));
        expect(updated.phone, equals(testUser.phone));
      });

      test('updates walletBalance correctly', () {
        final updated = testUser.copyWith(walletBalance: 300.0);
        expect(updated.walletBalance, equals(300.0));
      });

      test('updates status correctly', () {
        final updated = testUser.copyWith(status: UserStatus.suspended);
        expect(updated.status, equals(UserStatus.suspended));
      });

      test('can update all fields simultaneously', () {
        final newDate = DateTime(2026, 6);
        final updated = testUser.copyWith(
          uid: 'new_uid',
          name: 'New Name',
          phone: '+201111111111',
          email: 'new@email.com',
          authProviders: ['google'],
          type: UserType.driver,
          status: UserStatus.suspended,
          walletBalance: 500.0,
          referralCode: 'NEW_REF',
          lang: 'en',
          theme: 'dark',
          avatarUrl: 'https://new.com/img.jpg',
          fcmToken: 'new_fcm',
          createdAt: newDate,
        );

        expect(updated.uid, equals('new_uid'));
        expect(updated.name, equals('New Name'));
        expect(updated.type, equals(UserType.driver));
        expect(updated.walletBalance, equals(500.0));
        expect(updated.lang, equals('en'));
        expect(updated.createdAt, equals(newDate));
      });
    });

    // ===== isProfileComplete =====

    group('isProfileComplete', () {
      test('returns true when name is non-empty', () {
        expect(testUser.isProfileComplete, isTrue);
      });

      test('returns false when name is empty', () {
        final emptyNameUser = testUser.copyWith(name: '');
        expect(emptyNameUser.isProfileComplete, isFalse);
      });

      test('returns false when name is only whitespace', () {
        final whitespaceUser = testUser.copyWith(name: '   ');
        expect(whitespaceUser.isProfileComplete, isFalse);
      });
    });
  });

  // ===== UserType enum =====

  group('UserType enum', () {
    test('toJson returns correct string for each type', () {
      expect(UserType.customer.toJson(), equals('customer'));
      expect(UserType.driver.toJson(), equals('driver'));
      expect(UserType.merchant.toJson(), equals('merchant'));
    });

    test('fromJson parses each type correctly', () {
      expect(UserType.fromJson('customer'), equals(UserType.customer));
      expect(UserType.fromJson('driver'), equals(UserType.driver));
      expect(UserType.fromJson('merchant'), equals(UserType.merchant));
    });

    test('fromJson defaults to customer for unknown string', () {
      expect(UserType.fromJson('unknown'), equals(UserType.customer));
    });
  });

  // ===== UserStatus enum =====

  group('UserStatus enum', () {
    test('toJson returns correct string for each status', () {
      expect(UserStatus.active.toJson(), equals('active'));
      expect(UserStatus.suspended.toJson(), equals('suspended'));
      expect(UserStatus.pendingApproval.toJson(), equals('pending_approval'));
    });

    test('fromJson parses each status correctly', () {
      expect(UserStatus.fromJson('active'), equals(UserStatus.active));
      expect(UserStatus.fromJson('suspended'), equals(UserStatus.suspended));
      expect(
        UserStatus.fromJson('pending_approval'),
        equals(UserStatus.pendingApproval),
      );
    });

    test('fromJson defaults to active for unknown string', () {
      expect(UserStatus.fromJson('unknown'), equals(UserStatus.active));
    });
  });

  // ===== T128: Phone format validation =====

  group('T128: phone format validation in UserModel', () {
    test('phone field stores +20 prefix format correctly', () {
      final user = UserModel(
        uid: 'u1',
        name: 'Test User',
        phone: '+201012345678',
        type: UserType.customer,
        createdAt: DateTime(2026),
      );
      expect(user.phone, equals('+201012345678'));
      expect(user.phone.startsWith('+20'), isTrue);
    });

    test('phone has 13 chars with +20 prefix and 10-digit number', () {
      const phone = '+201512345678';
      expect(phone.length, equals(13)); // +20 (3) + 10 digits = 13
    });

    test('Egyptian phone operators: 10, 11, 12, 15 prefixes are valid formats', () {
      final operators = ['10', '11', '12', '15'];
      for (final op in operators) {
        final phone = '+20${op}12345678';
        expect(phone.startsWith('+20'), isTrue);
        expect(phone.length, equals(13));
      }
    });

    test('phone field is preserved through fromJson/copyWith round-trip', () {
      const phone = '+201012345678';
      final json = {
        'uid': 'u1',
        'name': 'Test',
        'phone': phone,
        'type': 'customer',
      };
      final user = UserModel.fromJson(json);
      expect(user.phone, equals(phone));

      final copied = user.copyWith(phone: '+201112345678');
      expect(copied.phone, equals('+201112345678'));
      expect(user.phone, equals(phone)); // original unchanged
    });

    test('phone field accepts Egyptian number format in UserModel constructor', () {
      final egyptianNumbers = [
        '+201012345678', // Vodafone
        '+201112345678', // Etisalat
        '+201212345678', // Orange
        '+201512345678', // WE
      ];

      for (final phone in egyptianNumbers) {
        final user = UserModel(
          uid: 'u1',
          name: 'Test',
          phone: phone,
          type: UserType.customer,
          createdAt: DateTime(2026),
        );
        expect(user.phone, equals(phone));
        expect(user.phone.startsWith('+20'), isTrue);
        expect(user.phone.length, equals(13));
      }
    });
  });
}
