import 'dart:async';

import 'package:driver_app/features/driver/driver_location.dart';
import 'package:driver_app/features/driver/driver_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeLocationPlatform extends GeolocatorPlatform {
  var streamStarts = 0;
  var streamCancels = 0;

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) =>
      Future.value(
        Position(
          latitude: 30,
          longitude: 31,
          timestamp: DateTime.now(),
          accuracy: 5,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        ),
      );

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    streamStarts++;
    final controller = StreamController<Position>();
    controller.onCancel = () {
      streamCancels++;
    };
    return controller.stream;
  }
}

class _FakeLocationService extends DriverService {
  _FakeLocationService()
    : super(
        SupabaseClient(
          'http://localhost',
          'test-only',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );

  @override
  Future<void> updateLocation({
    required double latitude,
    required double longitude,
    required double accuracyMeters,
    double? headingDegrees,
    double? speedMps,
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('idle location policy protects battery and backend write rate', () {
    final plan = DriverLocationPolicy.forMode(DriverLocationMode.idle);

    expect(plan.minimumUploadInterval, const Duration(seconds: 15));
    expect(plan.heartbeatInterval, const Duration(seconds: 90));
    expect(plan.distanceFilterMeters, 50);
    expect(plan.streamInterval, const Duration(seconds: 15));
  });

  test('active trip policy requests useful foreground updates', () {
    final plan = DriverLocationPolicy.forMode(DriverLocationMode.activeTrip);

    expect(plan.minimumUploadInterval, const Duration(seconds: 5));
    expect(plan.heartbeatInterval, const Duration(seconds: 90));
    expect(plan.distanceFilterMeters, 10);
    expect(plan.streamInterval, const Duration(seconds: 5));
  });

  test('Android background service is active-trip only and ongoing', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    expect(
      driverLocationAllowsBackgroundUpdates(
        AppLifecycleState.paused,
        DriverLocationMode.activeTrip,
      ),
      isTrue,
    );
    expect(
      driverLocationAllowsBackgroundUpdates(
        AppLifecycleState.paused,
        DriverLocationMode.idle,
      ),
      isFalse,
    );
    expect(
      driverLocationAllowsBackgroundUpdates(
        AppLifecycleState.detached,
        DriverLocationMode.activeTrip,
      ),
      isFalse,
    );

    final active =
        DriverLocationPolicy.settings(DriverLocationMode.activeTrip)
            as AndroidSettings;
    final notification = active.foregroundNotificationConfig;
    expect(notification, isNotNull);
    expect(notification!.notificationTitle, contains('بيكو'));
    expect(notification.notificationText, contains('الرحلة النشطة'));
    expect(notification.setOngoing, isTrue);
    expect(notification.enableWakeLock, isFalse);

    final idle =
        DriverLocationPolicy.settings(DriverLocationMode.idle)
            as AndroidSettings;
    expect(idle.foregroundNotificationConfig, isNull);
  });

  test('location failures keep a recovery action and safe Arabic copy', () {
    const serviceFailure = DriverLocationFailure(
      'فعّل خدمة الموقع من إعدادات الجهاز ثم حاول مرة أخرى.',
      DriverLocationRecovery.locationSettings,
    );
    const permissionFailure = DriverLocationFailure(
      'اسمح بالوصول إلى الموقع من إعدادات التطبيق ثم حاول مرة أخرى.',
      DriverLocationRecovery.appSettings,
    );

    expect(serviceFailure.recovery, DriverLocationRecovery.locationSettings);
    expect(permissionFailure.recovery, DriverLocationRecovery.appSettings);
    expect(driverLocationErrorMessage(permissionFailure), contains('الموقع'));
  });

  test('location writes are allowed only while the app is resumed', () {
    expect(
      driverLocationAllowsForegroundUpdates(AppLifecycleState.resumed),
      isTrue,
    );
    for (final state in AppLifecycleState.values.where(
      (state) => state != AppLifecycleState.resumed,
    )) {
      expect(driverLocationAllowsForegroundUpdates(state), isFalse);
    }
  });

  test('shared session stops stale background stream on mode change', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final previousPlatform = GeolocatorPlatform.instance;
    final platform = _FakeLocationPlatform();
    GeolocatorPlatform.instance = platform;
    addTearDown(() => GeolocatorPlatform.instance = previousPlatform);

    final location = DriverForegroundLocation(_FakeLocationService());
    await location.start(uploadFirst: false, activeTrip: true);
    expect(platform.streamStarts, 1);

    WidgetsBinding.instance.handleAppLifecycleStateChanged(
      AppLifecycleState.paused,
    );
    await location.start(uploadFirst: false, activeTrip: false);
    expect(platform.streamCancels, 1);

    await location.start(uploadFirst: false, activeTrip: true);
    expect(platform.streamStarts, 1);

    WidgetsBinding.instance.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
    await location.stop();
  });
}
