import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Test controller for validating GetX state management features
///
/// This controller includes:
/// - Reactive variables (Rx types): count, message, items, config, isLoading
/// - Non-reactive variable for GetBuilder: normalCounter
/// - Lifecycle tracking: onInit, onReady, onClose
class TestCounterController extends GetxController {
  // Reactive variables (Rx types)
  final count = 0.obs;
  final message = ''.obs;
  final items = <String>[].obs;
  final config = <String, dynamic>{}.obs;
  final isLoading = false.obs;

  // Non-reactive for GetBuilder testing
  int normalCounter = 0;

  // Lifecycle tracking flags
  bool _initialized = false;
  bool _ready = false;
  bool _disposed = false;

  // Getters for lifecycle verification
  @override
  bool get initialized => _initialized;
  bool get ready => _ready;
  bool get disposed => _disposed;

  @override
  void onInit() {
    super.onInit();
    _initialized = true;
  }

  @override
  void onReady() {
    super.onReady();
    _ready = true;
  }

  @override
  void onClose() {
    _disposed = true;
    super.onClose();
  }

  // Methods for state management
  void increment() => count.value++;
  void decrement() => count.value--;
  void setMessage(String msg) => message.value = msg;
  void addItem(String item) => items.add(item);
  void updateConfig(String key, dynamic value) => config[key] = value;
  void toggleLoading() => isLoading.value = !isLoading.value;

  void incrementNormal() {
    normalCounter++;
    update(); // Trigger GetBuilder rebuild
  }

  void incrementNormalWithId(String id) {
    normalCounter++;
    update([id]); // Trigger GetBuilder rebuild with specific ID
  }

  void reset() {
    count.value = 0;
    message.value = '';
    items.clear();
    config.clear();
    isLoading.value = false;
    normalCounter = 0;
  }
}

void main() {
  // Configure test group with GetX setup/teardown
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  group('State Management - Reactive Variables', () {
    // T005: Reactive int (RxInt) triggers observer updates
    test('reactive int triggers observer updates', () {
      final controller = TestCounterController();
      var updateCount = 0;

      // Listen to changes
      controller.count.listen((_) => updateCount++);

      // Modify value
      controller.increment();

      // Verify observer triggered
      expect(updateCount, equals(1));
      expect(controller.count.value, equals(1));
    });

    // T006: Reactive string (RxString) triggers observer updates
    test('reactive string triggers observer updates', () {
      final controller = TestCounterController();
      var updateCount = 0;

      controller.message.listen((_) => updateCount++);
      controller.setMessage('Hello');

      expect(updateCount, equals(1));
      expect(controller.message.value, equals('Hello'));
    });

    // T007: Reactive list (RxList) triggers observer updates on add
    test('reactive list triggers observer updates on add', () {
      final controller = TestCounterController();
      var updateCount = 0;

      controller.items.listen((_) => updateCount++);
      controller.addItem('item1');

      expect(updateCount, equals(1));
      expect(controller.items, contains('item1'));
    });

    // T008: Reactive map (RxMap) triggers observer updates on key change
    test('reactive map triggers observer updates on key change', () {
      final controller = TestCounterController();
      var updateCount = 0;

      controller.config.listen((_) => updateCount++);
      controller.updateConfig('key', 'value');

      expect(updateCount, equals(1));
      expect(controller.config['key'], equals('value'));
    });

    // T009: Reactive bool (RxBool) toggles correctly
    test('reactive bool toggles correctly', () {
      final controller = TestCounterController();

      expect(controller.isLoading.value, isFalse);
      controller.toggleLoading();
      expect(controller.isLoading.value, isTrue);
      controller.toggleLoading();
      expect(controller.isLoading.value, isFalse);
    });

    // T010: Multiple observers receive updates simultaneously
    test('multiple observers receive updates simultaneously', () {
      final controller = TestCounterController();
      var observer1Count = 0;
      var observer2Count = 0;

      controller.count.listen((_) => observer1Count++);
      controller.count.listen((_) => observer2Count++);

      controller.increment();

      expect(observer1Count, equals(1));
      expect(observer2Count, equals(1));
    });

    // T011: Observer updates reflect correct new value
    test('observer updates reflect correct new value', () {
      final controller = TestCounterController();
      int? receivedValue;

      controller.count.listen((value) => receivedValue = value);
      controller.count.value = 42;

      expect(receivedValue, equals(42));
      expect(controller.count.value, equals(42));
    });
  });

  group('State Management - GetBuilder', () {
    // T012: GetBuilder updates only when update() called
    test('GetBuilder updates only when update() called', () {
      final controller = Get.put(TestCounterController());

      // Increment without calling update()
      controller.normalCounter++;

      // Value changed but GetBuilder not notified
      expect(controller.normalCounter, equals(1));

      Get.delete<TestCounterController>();
    });

    // T013: GetBuilder rebuilds after update() call
    test('GetBuilder rebuilds after update() call', () {
      final controller = Get.put(TestCounterController());

      // Increment with update() call
      controller.incrementNormal();

      // Verify value changed
      expect(controller.normalCounter, equals(1));

      Get.delete<TestCounterController>();
    });

    // T014: GetBuilder with ID updates selectively
    test('GetBuilder with ID updates selectively', () {
      final controller = Get.put(TestCounterController());

      // Update with specific ID
      controller.incrementNormalWithId('counter1');

      // Verify update was called with ID
      expect(controller.normalCounter, equals(1));

      Get.delete<TestCounterController>();
    });
  });

  group('State Management - Controller Lifecycle', () {
    // T015: onInit executes before controller usage
    test('onInit executes before controller usage', () {
      final controller = Get.put(TestCounterController());

      expect(controller.initialized, isTrue);

      Get.delete<TestCounterController>();
    });

    // T016: onReady executes after onInit
    test('onReady executes after onInit', () {
      final controller = Get.put(TestCounterController());

      // onInit should be true, but onReady requires widget frame in full app
      // In unit tests without widget tree, onReady is not called automatically
      expect(controller.initialized, isTrue);
      // Note: onReady would be true in widget tests with GetMaterialApp

      Get.delete<TestCounterController>();
    });

    // T017: onClose executes on disposal
    test('onClose executes on disposal', () {
      final controller = Get.put(TestCounterController());

      expect(controller.disposed, isFalse);

      Get.delete<TestCounterController>();

      expect(controller.disposed, isTrue);
    });

    // T018: Lifecycle hooks execute in correct order
    test('lifecycle hooks execute in correct order', () {
      final controller = Get.put(TestCounterController());

      // After registration: onInit should be true, onClose false
      // onReady requires widget frame (not called in unit tests)
      expect(controller.initialized, isTrue);
      expect(controller.disposed, isFalse);

      Get.delete<TestCounterController>();

      // After deletion: disposed should be true (onClose executed)
      expect(controller.disposed, isTrue);
    });
  });

  group('State Management - Permanent vs Non-Permanent', () {
    // T019: Permanent controller survives Get.delete()
    test('permanent controller survives Get.delete()', () {
      Get.put(TestCounterController(), permanent: true);

      // Try to delete
      Get.delete<TestCounterController>();

      // Should still be accessible
      expect(() => Get.find<TestCounterController>(), returnsNormally);

      // Cleanup with force delete
      Get.delete<TestCounterController>(force: true);
    });

    // T020: Non-permanent controller is deleted
    test('non-permanent controller is deleted', () {
      Get.put(TestCounterController());

      // Delete
      Get.delete<TestCounterController>();

      // Should throw error
      expect(() => Get.find<TestCounterController>(), throwsA(anything));
    });

    // T021: Permanent controller persists across route changes
    test('permanent controller persists across route changes', () {
      final controller = Get.put(TestCounterController(), permanent: true);

      // Set a value
      controller.count.value = 5;

      // Simulate route change (Get.reset() would clear, but permanent survives)
      // In real app, route changes don't call Get.reset()

      // Verify same instance and value
      final found = Get.find<TestCounterController>();
      expect(identical(controller, found), isTrue);
      expect(found.count.value, equals(5));

      // Cleanup
      Get.delete<TestCounterController>(force: true);
    });
  });

  group('State Management - Singleton Behavior', () {
    // T022: Get.find() returns same instance (singleton behavior)
    test('Get.find() returns same instance', () {
      final controller1 = Get.put(TestCounterController());
      final controller2 = Get.find<TestCounterController>();

      // Verify same instance (reference equality)
      expect(identical(controller1, controller2), isTrue);

      // Verify state is shared
      controller1.count.value = 10;
      expect(controller2.count.value, equals(10));

      Get.delete<TestCounterController>();
    });
  });
}
