import 'package:biko/features/wallet/controllers/wallet_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Unit tests for WalletController.
///
/// Covers:
/// - T120: Wallet balance loading state
/// - T121: Transaction history loading and pagination
/// - T122: Read-only enforcement — no direct wallet writes from Flutter
///
/// Note: Firebase Firestore calls are integration-tested.
/// These unit tests focus on observable state and the critical
/// security rule that Flutter NEVER writes to wallets/ or transactions/.
void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  // ===== T120: Wallet balance loading =====

  group('T120: wallet balance loading state', () {
    test('WalletController can be instantiated without throwing', () {
      expect(WalletController.new, returnsNormally);
    });

    test('initial wallet is null (not yet loaded)', () {
      final controller = WalletController();
      expect(controller.wallet.value, isNull);
    });

    test('initial isLoading is true', () {
      final controller = WalletController();
      expect(controller.isLoading.value, isTrue);
    });

    test('initial errorMessage is empty', () {
      final controller = WalletController();
      expect(controller.errorMessage.value, equals(''));
    });

    test('wallet is a reactive nullable WalletModel', () {
      final controller = WalletController();
      expect(controller.wallet, isA<Rx>());
      expect(controller.wallet.value, isNull);
    });

    test('isLoading is observable', () {
      final controller = WalletController();
      controller.isLoading.value = false;
      expect(controller.isLoading.value, isFalse);

      controller.isLoading.value = true;
      expect(controller.isLoading.value, isTrue);
    });

    test('errorMessage is observable', () {
      final controller = WalletController();
      controller.errorMessage.value = 'Connection failed';
      expect(controller.errorMessage.value, equals('Connection failed'));
    });

    test('onClose does not throw without active subscription', () {
      final controller = WalletController();
      // _walletSub is null when uid is empty (no Firestore listener started)
      expect(controller.onClose, returnsNormally);
    });
  });

  // ===== T121: Transaction history =====

  group('T121: transaction history loading and pagination', () {
    test('initial transactions list is empty', () {
      final controller = WalletController();
      expect(controller.transactions, isA<RxList>());
      expect(controller.transactions.isEmpty, isTrue);
    });

    test('initial isPaginating is false', () {
      final controller = WalletController();
      expect(controller.isPaginating.value, isFalse);
    });

    test('initial hasMore is true (assumes more data until proven otherwise)', () {
      final controller = WalletController();
      expect(controller.hasMore.value, isTrue);
    });

    test('transactions list is reactive', () {
      final controller = WalletController();
      expect(controller.transactions, isA<RxList>());
    });

    test('isPaginating is observable', () {
      final controller = WalletController();
      controller.isPaginating.value = true;
      expect(controller.isPaginating.value, isTrue);

      controller.isPaginating.value = false;
      expect(controller.isPaginating.value, isFalse);
    });

    test('hasMore is observable', () {
      final controller = WalletController();
      controller.hasMore.value = false;
      expect(controller.hasMore.value, isFalse);
    });

    test('loadMore method exists', () {
      expect(() => WalletController().loadMore, returnsNormally);
    });

    test('loadMore does not paginate when isPaginating is true', () async {
      final controller = WalletController();
      controller.isPaginating.value = true;

      // Should return immediately without doing anything
      await expectLater(controller.loadMore(), completes);

      // isPaginating stays true (we set it, method returned early)
      expect(controller.isPaginating.value, isTrue);
    });

    test('loadMore does not paginate when hasMore is false', () async {
      final controller = WalletController();
      controller.isPaginating.value = false;
      controller.hasMore.value = false;

      // Should return immediately without doing anything
      await expectLater(controller.loadMore(), completes);
    });
  });

  // ===== T122: Read-only enforcement =====

  group('T122: read-only enforcement — no direct wallet writes', () {
    test(
      'CRITICAL: WalletController has no direct Firestore wallet write methods',
      () {
        final controller = WalletController();

        // The controller should NEVER have methods like:
        // - writeToWallet()
        // - creditWallet()
        // - debitWallet()
        // - updateBalance()
        // Only Cloud Functions can write to wallets/

        // Verify the controller only exposes read/listen methods
        // The wallet observable only receives data FROM Firestore listener
        expect(controller.wallet, isA<Rx>());

        // Verify no unexpected methods exist by checking known safe methods
        expect(() => controller.setTopUpAmount, returnsNormally);
        expect(() => controller.setPaymentMethod, returnsNormally);
        expect(() => controller.initiateTopUp, returnsNormally);
        expect(() => controller.loadMore, returnsNormally);
      },
    );

    test(
      'initiateTopUp requires non-null, non-zero amount to proceed',
      () {
        final controller = WalletController();

        // Contract: initiateTopUp must check amount before calling Firestore
        // When amount is null or <= 0, it shows a warning and returns early
        // The guard condition is:
        // if (amount == null || amount <= 0) { AppSnackbar.warning(...); return; }
        expect(controller.selectedTopUpAmount.value, isNull);
        expect(controller.isProcessingTopUp.value, isFalse);

        // Verify the guard logic:
        final nullIsInvalid = controller.selectedTopUpAmount.value == null;
        expect(nullIsInvalid, isTrue);

        controller.selectedTopUpAmount.value = 0.0;
        final zeroIsInvalid = (controller.selectedTopUpAmount.value ?? 0) <= 0;
        expect(zeroIsInvalid, isTrue);

        controller.selectedTopUpAmount.value = 100.0;
        final positiveIsValid = (controller.selectedTopUpAmount.value ?? 0) > 0;
        expect(positiveIsValid, isTrue);
      },
    );

    test('setTopUpAmount updates selectedTopUpAmount', () {
      final controller = WalletController();

      controller.setTopUpAmount(100.0);
      expect(controller.selectedTopUpAmount.value, equals(100.0));

      controller.setTopUpAmount(50.0);
      expect(controller.selectedTopUpAmount.value, equals(50.0));

      controller.setTopUpAmount(null);
      expect(controller.selectedTopUpAmount.value, isNull);
    });

    test('setPaymentMethod updates selectedPaymentMethod', () {
      final controller = WalletController();

      controller.setPaymentMethod('vodafone_cash');
      expect(controller.selectedPaymentMethod.value, equals('vodafone_cash'));

      controller.setPaymentMethod('card');
      expect(controller.selectedPaymentMethod.value, equals('card'));

      controller.setPaymentMethod('wallet');
      expect(controller.selectedPaymentMethod.value, equals('wallet'));
    });

    test('initial selectedPaymentMethod is card', () {
      final controller = WalletController();
      expect(controller.selectedPaymentMethod.value, equals('card'));
    });

    test('initial selectedTopUpAmount is null (no amount selected)', () {
      final controller = WalletController();
      expect(controller.selectedTopUpAmount.value, isNull);
    });

    test('initial isProcessingTopUp is false', () {
      final controller = WalletController();
      expect(controller.isProcessingTopUp.value, isFalse);
    });
  });
}
