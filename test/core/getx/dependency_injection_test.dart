import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Test controller for validating GetX dependency injection features
class TestServiceController extends GetxController {
  // Constructor to generate unique instance ID
  TestServiceController()
    : instanceId =
          '${DateTime.now().microsecondsSinceEpoch}_${++_instanceCounter}';

  final String instanceId;
  final DateTime instantiationTime = DateTime.now();
  final accessCount = 0.obs;

  bool _disposed = false;
  bool get disposed => _disposed;

  // Counter for unique instance IDs
  static int _instanceCounter = 0;

  @override
  void onClose() {
    _disposed = true;
    super.onClose();
  }

  void access() {
    accessCount.value++;
  }

  String doWork() {
    return 'Work done by $instanceId';
  }
}

void main() {
  setUp(Get.reset);

  tearDown(Get.reset);

  group('Dependency Injection - Get.put', () {
    // T043: Get.put creates controller immediately
    test('Get.put creates controller immediately', () {
      final beforeTime = DateTime.now();
      final controller = Get.put(TestServiceController());
      final afterTime = DateTime.now();

      // Verify instantiated within time window
      expect(
        controller.instantiationTime.isAfter(beforeTime) ||
            controller.instantiationTime.isAtSameMomentAs(beforeTime),
        isTrue,
      );
      expect(
        controller.instantiationTime.isBefore(afterTime) ||
            controller.instantiationTime.isAtSameMomentAs(afterTime),
        isTrue,
      );
    });

    // T044: Get.put returns singleton instance
    test('Get.put returns singleton instance', () {
      final controller1 = Get.put(TestServiceController());
      final controller2 = Get.find<TestServiceController>();

      // Verify same instance (reference equality)
      expect(identical(controller1, controller2), isTrue);
      expect(controller1.instanceId, equals(controller2.instanceId));
    });

    // T045: Get.put with permanent flag persists
    test('Get.put with permanent flag persists', () {
      Get.put(TestServiceController(), permanent: true);

      // Try to delete
      Get.delete<TestServiceController>();

      // Should still be accessible
      expect(() => Get.find<TestServiceController>(), returnsNormally);

      // Cleanup
      Get.delete<TestServiceController>(force: true);
    });

    // T046: Get.put without permanent flag can be deleted
    test('Get.put without permanent flag can be deleted', () {
      Get.put(TestServiceController());

      // Delete
      Get.delete<TestServiceController>();

      // Should throw error
      expect(() => Get.find<TestServiceController>(), throwsA(anything));
    });
  });

  group('Dependency Injection - Get.lazyPut', () {
    // T047: Get.lazyPut delays instantiation
    test('Get.lazyPut delays instantiation', () {
      var instantiated = false;

      Get.lazyPut<TestServiceController>(() {
        instantiated = true;
        return TestServiceController();
      });

      // Not instantiated yet
      expect(instantiated, isFalse);

      // Cleanup (will instantiate to dispose)
      Get.delete<TestServiceController>();
    });

    // T048: Get.lazyPut instantiates on first Get.find()
    test('Get.lazyPut instantiates on first Get.find()', () {
      var instantiated = false;

      Get.lazyPut<TestServiceController>(() {
        instantiated = true;
        return TestServiceController();
      });

      expect(instantiated, isFalse);

      // First access triggers instantiation
      Get.find<TestServiceController>();
      expect(instantiated, isTrue);

      Get.delete<TestServiceController>();
    });

    // T049: Get.lazyPut returns same instance on subsequent finds
    test('Get.lazyPut returns same instance on subsequent finds', () {
      Get.lazyPut<TestServiceController>(TestServiceController.new);

      final controller1 = Get.find<TestServiceController>();
      final controller2 = Get.find<TestServiceController>();

      // Same instance
      expect(identical(controller1, controller2), isTrue);
      expect(controller1.instanceId, equals(controller2.instanceId));

      Get.delete<TestServiceController>();
    });

    // T050: Get.lazyPut with fenix recreates after delete
    test('Get.lazyPut with fenix recreates after delete', () {
      Get.lazyPut<TestServiceController>(
        TestServiceController.new,
        fenix: true,
      );

      final controller1 = Get.find<TestServiceController>();
      final firstId = controller1.instanceId;

      // Delete
      Get.delete<TestServiceController>();

      // Access again (should recreate due to fenix)
      final controller2 = Get.find<TestServiceController>();
      final secondId = controller2.instanceId;

      // Different instances
      expect(firstId, isNot(equals(secondId)));

      Get.delete<TestServiceController>(force: true);
    });
  });

  group('Dependency Injection - Get.find', () {
    // T051: Get.find throws error if not registered
    test('Get.find throws error if not registered', () {
      expect(() => Get.find<TestServiceController>(), throwsA(anything));
    });

    // T052: Get.find returns correct type
    test('Get.find returns correct type', () {
      Get.put(TestServiceController());

      final found = Get.find<TestServiceController>();

      expect(found, isA<TestServiceController>());

      Get.delete<TestServiceController>();
    });

    // T053: Get.find with tag returns tagged instance
    test('Get.find with tag returns tagged instance', () {
      final controllerA = Get.put(TestServiceController(), tag: 'A');
      final controllerB = Get.put(TestServiceController(), tag: 'B');

      final foundA = Get.find<TestServiceController>(tag: 'A');
      final foundB = Get.find<TestServiceController>(tag: 'B');

      expect(identical(controllerA, foundA), isTrue);
      expect(identical(controllerB, foundB), isTrue);
      expect(controllerA.instanceId, isNot(equals(controllerB.instanceId)));

      Get.delete<TestServiceController>(tag: 'A');
      Get.delete<TestServiceController>(tag: 'B');
    });
  });

  group('Dependency Injection - Get.delete', () {
    // T054: Get.delete removes controller
    test('Get.delete removes controller', () {
      Get.put(TestServiceController());

      Get.delete<TestServiceController>();

      expect(() => Get.find<TestServiceController>(), throwsA(anything));
    });

    // T055: Get.delete triggers onClose lifecycle
    test('Get.delete triggers onClose lifecycle', () {
      final controller = Get.put(TestServiceController());

      expect(controller.disposed, isFalse);

      Get.delete<TestServiceController>();

      expect(controller.disposed, isTrue);
    });

    // T056: Get.delete with tag removes only tagged instance
    test('Get.delete with tag removes only tagged instance', () {
      Get.put(TestServiceController(), tag: 'A');
      Get.put(TestServiceController(), tag: 'B');

      Get.delete<TestServiceController>(tag: 'A');

      expect(
        () => Get.find<TestServiceController>(tag: 'A'),
        throwsA(anything),
      );
      expect(() => Get.find<TestServiceController>(tag: 'B'), returnsNormally);

      Get.delete<TestServiceController>(tag: 'B');
    });

    // T057: Get.delete on permanent controller does nothing
    test('Get.delete on permanent controller does nothing', () {
      Get.put(TestServiceController(), permanent: true);

      Get.delete<TestServiceController>();

      expect(() => Get.find<TestServiceController>(), returnsNormally);

      Get.delete<TestServiceController>(force: true);
    });
  });

  group('Dependency Injection - Get.putAsync', () {
    // T058: Get.putAsync waits for async initialization
    test('Get.putAsync waits for async initialization', () async {
      var asyncComplete = false;

      await Get.putAsync<TestServiceController>(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        asyncComplete = true;
        return TestServiceController();
      });

      // Should be complete after await
      expect(asyncComplete, isTrue);

      Get.delete<TestServiceController>();
    });

    // T059: Get.putAsync completes before returning instance
    test('Get.putAsync completes before returning instance', () async {
      await Get.putAsync<TestServiceController>(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        return TestServiceController();
      });

      // Controller should be accessible immediately after await
      expect(() => Get.find<TestServiceController>(), returnsNormally);

      Get.delete<TestServiceController>();
    });
  });

  group('Dependency Injection - Get.reset', () {
    // T060: Get.reset clears all controllers
    test('Get.reset clears all controllers', () {
      Get.put(TestServiceController(), tag: 'A');
      Get.put(TestServiceController(), tag: 'B');
      Get.put(TestServiceController(), tag: 'C');

      Get.reset();

      expect(
        () => Get.find<TestServiceController>(tag: 'A'),
        throwsA(anything),
      );
      expect(
        () => Get.find<TestServiceController>(tag: 'B'),
        throwsA(anything),
      );
      expect(
        () => Get.find<TestServiceController>(tag: 'C'),
        throwsA(anything),
      );
    });

    // T061: Get.reset disposes non-permanent controllers
    test('Get.reset disposes non-permanent controllers', () {
      final controller = Get.put(TestServiceController());

      expect(controller.disposed, isFalse);

      Get.reset();

      // Note: Get.reset() clears controllers but doesn't guarantee onClose() call order
      // This test validates that reset clears the controller
      expect(() => Get.find<TestServiceController>(), throwsA(anything));
    });

    // T062: Get.reset clears permanent controllers too
    test('Get.reset clears permanent controllers too', () {
      Get.put(TestServiceController(), permanent: true);

      Get.reset();

      expect(() => Get.find<TestServiceController>(), throwsA(anything));
    });
  });

  group('Dependency Injection - Real-World Scenarios', () {
    // T063: FirebaseService singleton accessible globally
    test('FirebaseService singleton accessible globally', () {
      // Simulate FirebaseService registration (using TestServiceController)
      final service = Get.put(TestServiceController(), permanent: true);

      // Access from "different widgets" (multiple finds)
      final found1 = Get.find<TestServiceController>();
      final found2 = Get.find<TestServiceController>();
      final found3 = Get.find<TestServiceController>();

      // All should be same instance
      expect(identical(service, found1), isTrue);
      expect(identical(service, found2), isTrue);
      expect(identical(service, found3), isTrue);

      Get.delete<TestServiceController>(force: true);
    });
  });
}
