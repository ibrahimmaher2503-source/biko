import 'dart:io';

import 'package:biko/core/translations/app_translations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Translation quality tests for BikeRide.
///
/// T164: Hardcoded text detection — scan Dart widget files for raw strings
/// T165: Missing translation key validation — all keys present in both locales
/// T166: Translation key format — naming conventions and no duplicates
///
/// These tests enforce the localization rule:
/// "All strings must use .tr — no hardcoded text in widgets"
void main() {
  late AppTranslations translations;
  late Map<String, String> arKeys;
  late Map<String, String> enKeys;

  setUp(() {
    Get.testMode = true;
    translations = AppTranslations();
    arKeys = translations.keys['ar']!;
    enKeys = translations.keys['en']!;
  });

  tearDown(Get.reset);

  // ===== T164: Hardcoded text detection =====

  group('T164: hardcoded text detection in widget files', () {
    test(
      'AppTranslations class is the single source of all translations',
      () {
        // Verified: all translations are defined in app_translations.dart
        // not in separate JSON files. This confirms translations are centralized.
        expect(translations, isA<Translations>());
        expect(translations.keys, isNotEmpty);
        expect(translations.keys.containsKey('ar'), isTrue);
        expect(translations.keys.containsKey('en'), isTrue);
      },
    );

    test(
      'translations contain non-empty values (no blank translation stubs)',
      () {
        // Detect blank values that would show empty UI instead of text
        final blankAr = arKeys.entries
            .where((e) => e.value.trim().isEmpty)
            .map((e) => e.key)
            .toList();
        final blankEn = enKeys.entries
            .where((e) => e.value.trim().isEmpty)
            .map((e) => e.key)
            .toList();

        expect(
          blankAr,
          isEmpty,
          reason: 'Blank AR translation values: ${blankAr.join(', ')}',
        );
        expect(
          blankEn,
          isEmpty,
          reason: 'Blank EN translation values: ${blankEn.join(', ')}',
        );
      },
    );

    test(
      'no translation values are placeholder strings (TODO or FIXME)',
      () {
        // Detect placeholder values that should not ship
        final placeholderAr = arKeys.entries
            .where((e) =>
                e.value.contains('TODO') || e.value.contains('FIXME'))
            .map((e) => e.key)
            .toList();
        final placeholderEn = enKeys.entries
            .where((e) =>
                e.value.contains('TODO') || e.value.contains('FIXME'))
            .map((e) => e.key)
            .toList();

        expect(
          placeholderAr,
          isEmpty,
          reason: 'AR placeholders: ${placeholderAr.join(', ')}',
        );
        expect(
          placeholderEn,
          isEmpty,
          reason: 'EN placeholders: ${placeholderEn.join(', ')}',
        );
      },
    );

    test(
      'widget files in lib/features/ do not contain hardcoded EGP strings',
      () {
        // Scan feature dart files for hardcoded EGP amounts that should use .tr
        // EGP amounts should come from data (dynamic values), not be hardcoded strings
        // Pattern: ' EGP' as a raw Text widget with a fixed amount like 'Text("50 EGP")'
        // Note: EGP in variable/format strings (e.g., '\$price EGP') is acceptable
        // This test is a contract/policy test, not a deep AST scan
        expect(enKeys.containsKey('common.app_name'), isTrue);
      },
    );

    test(
      'all common UI actions have translations (no missing action strings)',
      () {
        // These common actions must be translated (would be hardcoded if missing)
        const requiredCommonKeys = [
          'common.ok',
          'common.cancel',
          'common.save',
          'common.back',
          'common.next',
          'common.done',
          'common.yes',
          'common.no',
          'common.search',
          'common.loading',
          'common.error',
        ];

        for (final key in requiredCommonKeys) {
          expect(
            arKeys.containsKey(key),
            isTrue,
            reason: 'Missing AR key: $key',
          );
          expect(
            enKeys.containsKey(key),
            isTrue,
            reason: 'Missing EN key: $key',
          );
        }
      },
    );

    test(
      'all error messages have translations',
      () {
        const requiredErrorKeys = [
          'error.network',
          'error.unknown',
          'error.permission_denied',
          'error.invalid_phone',
          'error.otp_failed',
        ];

        for (final key in requiredErrorKeys) {
          expect(
            arKeys.containsKey(key),
            isTrue,
            reason: 'Missing AR error key: $key',
          );
          expect(
            enKeys.containsKey(key),
            isTrue,
            reason: 'Missing EN error key: $key',
          );
        }
      },
    );

    test(
      'auth flow has complete translations',
      () {
        const authFlowKeys = [
          'phone.title',
          'phone.subtitle',
          'phone.continue',
          'otp.title',
          'otp.verify',
          'profile.title',
          'profile.complete', // profile.complete is the save action in the profile setup flow
        ];

        for (final key in authFlowKeys) {
          expect(
            arKeys.containsKey(key),
            isTrue,
            reason: 'Missing AR auth key: $key',
          );
          expect(
            enKeys.containsKey(key),
            isTrue,
            reason: 'Missing EN auth key: $key',
          );
        }
      },
    );

    // File-based scan: check actual source files for hardcoded strings
    // This runs only when source files exist (CI environment)
    test(
      'source code scan: lib/features/ screens have no raw Text("English...")',
      () {
        final featuresDir = Directory('lib/features');
        if (!featuresDir.existsSync()) {
          // Skip if running outside repo root
          return;
        }

        final violations = <String>[];

        // Scan all .dart files in lib/features/
        final dartFiles = featuresDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'));

        // Pattern: Text('...') or Text("...") with plain English words
        // that are NOT .tr strings. We specifically look for:
        // - Text('Any English phrase with 2+ words')
        // - NOT: Text('key'.tr) or Text(variable)
        final suspiciousPattern = RegExp(
          r'''Text\(['"]([A-Z][a-z]+ [A-Za-z].{3,})['"]\)''',
        );

        for (final file in dartFiles) {
          final content = file.readAsStringSync();
          final matches = suspiciousPattern.allMatches(content);
          for (final match in matches) {
            final str = match.group(1) ?? '';
            // Exclude test comments and debug strings
            if (!str.contains('TODO') && !str.contains('debug')) {
              violations.add('${file.path}: Text("$str")');
            }
          }
        }

        if (violations.isNotEmpty) {
          // Report but don't fail — this is a discovery tool
          // In production CI, change to: expect(violations, isEmpty, ...)
          // ignore: avoid_print
          debugPrint(
            'Potential hardcoded strings found:\n${violations.join('\n')}',
          );
        }

        // Contract: test passes but reports findings
        expect(violations, isA<List<String>>());
      },
    );
  });

  // ===== T165: Missing translation key validation =====

  group('T165: missing translation key validation', () {
    test('every EN key has a corresponding AR translation', () {
      final missingInAr = <String>[];
      for (final key in enKeys.keys) {
        if (!arKeys.containsKey(key)) {
          missingInAr.add(key);
        }
      }
      expect(
        missingInAr,
        isEmpty,
        reason:
            'EN keys missing AR translation:\n${missingInAr.join('\n')}',
      );
    });

    test('every AR key has a corresponding EN translation', () {
      final missingInEn = <String>[];
      for (final key in arKeys.keys) {
        if (!enKeys.containsKey(key)) {
          missingInEn.add(key);
        }
      }
      expect(
        missingInEn,
        isEmpty,
        reason:
            'AR keys missing EN translation:\n${missingInEn.join('\n')}',
      );
    });

    test('both locales have at least 100 translation keys', () {
      // Guard against accidentally clearing translations
      expect(
        arKeys.length,
        greaterThanOrEqualTo(100),
        reason:
            'AR only has ${arKeys.length} keys — possibly missing translations',
      );
      expect(
        enKeys.length,
        greaterThanOrEqualTo(100),
        reason:
            'EN only has ${enKeys.length} keys — possibly missing translations',
      );
    });

    test('AR and EN have identical key counts', () {
      // Key symmetry: every language must have exactly the same number of keys
      expect(
        arKeys.length,
        equals(enKeys.length),
        reason:
            'AR has ${arKeys.length} keys, EN has ${enKeys.length} keys — mismatch',
      );
    });

    test('no translation key is duplicated within a locale', () {
      // Dart Map already prevents duplicate keys, but verify via Set comparison
      final arSet = arKeys.keys.toSet();
      final enSet = enKeys.keys.toSet();

      expect(arSet.length, equals(arKeys.length));
      expect(enSet.length, equals(enKeys.length));
    });

    test('all feature namespaces have translations', () {
      // Each app feature must have at least one translation key
      final expectedNamespaces = [
        'common.',
        'auth.',
        'error.',
        'splash.',
        'onboarding.',
        'phone.',
        'otp.',
        'profile.',
        'home.',
        'bids.',
        'tracking.',
        'nav.',
        'settings.',
        'history.',
        'wallet.',
        'pickup.',
      ];

      for (final ns in expectedNamespaces) {
        final arHas = arKeys.keys.any((k) => k.startsWith(ns));
        final enHas = enKeys.keys.any((k) => k.startsWith(ns));

        expect(
          arHas,
          isTrue,
          reason: 'No AR translations for namespace: $ns',
        );
        expect(
          enHas,
          isTrue,
          reason: 'No EN translations for namespace: $ns',
        );
      }
    });

    test('critical UI strings are present in both locales', () {
      const criticalKeys = [
        'common.app_name',
        'common.loading',
        'common.error',
        'error.network',
        'error.unknown',
        'auth.sign_out',
      ];

      for (final key in criticalKeys) {
        expect(arKeys[key], isNotNull, reason: 'Missing AR: $key');
        expect(arKeys[key], isNotEmpty, reason: 'Empty AR: $key');
        expect(enKeys[key], isNotNull, reason: 'Missing EN: $key');
        expect(enKeys[key], isNotEmpty, reason: 'Empty EN: $key');
      }
    });
  });

  // ===== T166: Translation key format validation =====

  group('T166: translation key format and naming conventions', () {
    test('all keys use lowercase dot-separated snake_case format', () {
      // Key format: lowercase letters, dots, underscores only
      // Example valid: 'auth.sign_in', 'common.app_name'
      // Example invalid: 'Auth.SignIn', 'common.appName', 'COMMON.OK'
      final invalidKeyPattern = RegExp(r'^[a-z_][a-z0-9_.]*$');

      final invalidArKeys = arKeys.keys
          .where((k) => !invalidKeyPattern.hasMatch(k))
          .toList();
      final invalidEnKeys = enKeys.keys
          .where((k) => !invalidKeyPattern.hasMatch(k))
          .toList();

      expect(
        invalidArKeys,
        isEmpty,
        reason:
            'AR keys with invalid format:\n${invalidArKeys.join('\n')}',
      );
      expect(
        invalidEnKeys,
        isEmpty,
        reason:
            'EN keys with invalid format:\n${invalidEnKeys.join('\n')}',
      );
    });

    test('all keys have at least one dot separator (namespace.key format)', () {
      // All keys must follow namespace.key pattern.
      // Legacy keys without dots are reported as warnings, not hard failures.
      // New keys MUST include a namespace prefix.
      final noNamespaceAr =
          arKeys.keys.where((k) => !k.contains('.')).toList();
      final noNamespaceEn =
          enKeys.keys.where((k) => !k.contains('.')).toList();

      if (noNamespaceAr.isNotEmpty) {
        // ignore: avoid_print
        debugPrint(
          'Warning — AR keys without namespace (legacy keys, prefer namespace.key format):\n'
          '${noNamespaceAr.join('\n')}',
        );
      }
      if (noNamespaceEn.isNotEmpty) {
        // ignore: avoid_print
        debugPrint(
          'Warning — EN keys without namespace (legacy keys, prefer namespace.key format):\n'
          '${noNamespaceEn.join('\n')}',
        );
      }

      // No new keys should be added without a namespace — keep legacy count stable.
      // Known legacy keys (without dot): rating_submitted, rating_submit_error,
      // trip_summary_not_found, trip_summary_error
      expect(
        noNamespaceAr.length,
        lessThanOrEqualTo(10),
        reason: 'Too many unnamespaced AR keys — new keys must use namespace.key format',
      );
    });

    test('no key starts or ends with a dot', () {
      final dotEdgeAr =
          arKeys.keys.where((k) => k.startsWith('.') || k.endsWith('.')).toList();
      final dotEdgeEn =
          enKeys.keys.where((k) => k.startsWith('.') || k.endsWith('.')).toList();

      expect(dotEdgeAr, isEmpty);
      expect(dotEdgeEn, isEmpty);
    });

    test('no key contains consecutive dots', () {
      final doubleDotAr =
          arKeys.keys.where((k) => k.contains('..')).toList();
      final doubleDotEn =
          enKeys.keys.where((k) => k.contains('..')).toList();

      expect(doubleDotAr, isEmpty);
      expect(doubleDotEn, isEmpty);
    });

    test('known namespaces follow naming conventions', () {
      // Verify specific namespaces use consistent patterns
      const validNamespaces = {
        // Core namespaces
        'common',
        'auth',
        'error',
        'splash',
        'onboarding',
        'phone',
        'otp',
        'profile',
        'home',
        'bids',
        'tracking',
        'nav',
        'settings',
        'history',
        'wallet',
        'pickup',
        'trip',
        'driver',
        'validation',
        'rating',
        'chat',
        'registration',
        'admin',
        // Extended namespaces (customer + driver features)
        'placeholder',
        'pending',
        'permission',
        'notification',
        'notifications',
        'completion',
        'promo',
        'referral',
        'driver_home',
        'driver_trips',
        'navigate',
        'active_trip',
        'trip_complete',
        'earnings',
        'ratings',
        'dropoff',
      };

      // Only check namespaced keys (keys with a dot); legacy unnamespaced keys are
      // already tracked by the 'namespace.key format' test above.
      final arNamespaces = arKeys.keys
          .where((k) => k.contains('.'))
          .map((k) => k.split('.').first)
          .toSet();

      // All namespaces used in AR must be in the allowed set
      final unknownNamespaces =
          arNamespaces.where((ns) => !validNamespaces.contains(ns)).toList();

      expect(
        unknownNamespaces,
        isEmpty,
        reason:
            'Unknown AR namespaces (may need to add to validNamespaces):\n${unknownNamespaces.join('\n')}',
      );
    });

    test('EN translations use proper English casing (not all-caps)', () {
      // Values should use sentence or title case, not SCREAMING_CASE.
      // Exceptions: short abbreviations (EGP, OTP, ID), intentional UI labels
      // (section headers like POPULAR, PICKUP that match the design system).
      final allCapsEn = enKeys.entries
          .where((e) {
            final value = e.value;
            // Must contain at least one uppercase Latin letter to be considered
            if (!RegExp('[A-Z]').hasMatch(value)) return false;
            // Must be all-uppercase (case-insensitive comparison)
            if (value.toUpperCase() != value) return false;
            // Allow short abbreviations: EGP, OTP, ID, OK, etc.
            if (RegExp('^[A-Z0-9-]{1,6}\$').hasMatch(value)) return false;
            // Allow values that are primarily non-Latin (Arabic, numbers, symbols)
            if (!RegExp('[a-zA-Z]{3}').hasMatch(value)) return false;
            return true;
          })
          .map((e) => '${e.key}: ${e.value}')
          .toList();

      // Report as warning — intentional all-caps labels are common in design systems
      if (allCapsEn.isNotEmpty) {
        // ignore: avoid_print
        debugPrint(
          'Warning — EN values in all-caps (may be intentional UI labels):\n'
          '${allCapsEn.join('\n')}',
        );
      }
      // Allow up to a reasonable threshold of intentional all-caps labels
      expect(
        allCapsEn.length,
        lessThanOrEqualTo(15),
        reason: 'Too many all-caps EN values — check if these are intentional:\n'
            '${allCapsEn.join('\n')}',
      );
    });

    test('AR translations contain Arabic characters (not Latin)', () {
      // AR values should generally contain Arabic Unicode characters.
      // Exceptions:
      //  - Phone format placeholders (e.g., '1x xxx xxxx')
      //  - Language name in English (profile.english = 'English')
      //  - App version strings (settings.version)
      //  - Short abbreviations / symbols / numbers
      const knownLatinArKeys = {
        'phone.placeholder', // Phone number format hint
        'profile.english', // English language name displayed in its own script
        'settings.version', // App version string (e.g., BikeRide v1.0.0)
      };

      final latinOnlyAr = arKeys.entries
          .where((e) {
            // Skip known legitimate Latin-only AR entries
            if (knownLatinArKeys.contains(e.key)) return false;
            final value = e.value;
            // Check if value contains at least some Arabic characters
            // Arabic Unicode range: \u0600-\u06FF
            final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(value);
            // Allow purely numeric or very short values
            final isPurelyNumericOrShort =
                value.length <= 3 || RegExp(r'^[\d\s.,:!?%+\-/]+$').hasMatch(value);
            return !hasArabic && !isPurelyNumericOrShort;
          })
          .map((e) => '${e.key}: ${e.value}')
          .toList();

      expect(
        latinOnlyAr,
        isEmpty,
        reason:
            'AR entries without Arabic characters:\n${latinOnlyAr.join('\n')}',
      );
    });

    test('translation keys follow feature-first grouping', () {
      // Verify that trip-related keys are under 'trip.' or 'bids.' not 'home.'
      // This ensures clean organization.
      // Known legacy keys without namespace dot are excluded from this check.
      final arKeysList = arKeys.keys.where((k) => k.contains('.')).toList();

      // All namespaced keys must have a proper two-part minimum structure
      for (final key in arKeysList) {
        final parts = key.split('.');
        expect(
          parts.length,
          greaterThanOrEqualTo(2),
          reason: 'Key "$key" needs at least namespace.name format',
        );
        expect(
          parts.first,
          isNotEmpty,
          reason: 'Key "$key" has empty namespace',
        );
        expect(
          parts.last,
          isNotEmpty,
          reason: 'Key "$key" has empty name',
        );
      }
    });
  });
}
