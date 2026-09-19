import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';

import 'driver_models.dart';
import 'driver_service.dart';

enum DriverLocationMode { idle, activeTrip }

enum DriverLocationRecovery { locationSettings, appSettings }

bool driverLocationAllowsForegroundUpdates(AppLifecycleState state) =>
    state == AppLifecycleState.resumed;

bool driverLocationAllowsBackgroundUpdates(
  AppLifecycleState state,
  DriverLocationMode mode,
) =>
    defaultTargetPlatform == TargetPlatform.android &&
    mode == DriverLocationMode.activeTrip &&
    switch (state) {
      AppLifecycleState.inactive ||
      AppLifecycleState.hidden ||
      AppLifecycleState.paused => true,
      AppLifecycleState.resumed || AppLifecycleState.detached => false,
    };

class DriverLocationPlan {
  const DriverLocationPlan({
    required this.minimumUploadInterval,
    required this.heartbeatInterval,
    required this.distanceFilterMeters,
    required this.streamInterval,
  });

  final Duration minimumUploadInterval;
  final Duration heartbeatInterval;
  final int distanceFilterMeters;
  final Duration? streamInterval;
}

abstract final class DriverLocationPolicy {
  static const idle = DriverLocationPlan(
    minimumUploadInterval: Duration(seconds: 15),
    heartbeatInterval: Duration(seconds: 90),
    distanceFilterMeters: 50,
    streamInterval: Duration(seconds: 15),
  );

  static const activeTrip = DriverLocationPlan(
    minimumUploadInterval: Duration(seconds: 5),
    heartbeatInterval: Duration(seconds: 90),
    distanceFilterMeters: 10,
    streamInterval: Duration(seconds: 5),
  );

  static DriverLocationPlan forMode(DriverLocationMode mode) => switch (mode) {
    DriverLocationMode.idle => idle,
    DriverLocationMode.activeTrip => activeTrip,
  };

  static LocationSettings settings(
    DriverLocationMode mode, {
    bool bounded = false,
  }) {
    final plan = forMode(mode);
    final timeLimit = bounded ? const Duration(seconds: 10) : null;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: plan.distanceFilterMeters,
        intervalDuration: plan.streamInterval,
        timeLimit: timeLimit,
        foregroundNotificationConfig: mode == DriverLocationMode.activeTrip
            ? const ForegroundNotificationConfig(
                notificationTitle: 'بيكو - الرحلة النشطة',
                notificationText: 'يتم تحديث موقعك أثناء الرحلة النشطة.',
                notificationChannelName: 'موقع الرحلة النشطة',
                setOngoing: true,
              )
            : null,
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: plan.distanceFilterMeters,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: false,
        timeLimit: timeLimit,
      );
    }
    return LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: plan.distanceFilterMeters,
      timeLimit: timeLimit,
    );
  }
}

class DriverLocationFailure extends DriverAppException {
  const DriverLocationFailure(super.message, this.recovery);

  final DriverLocationRecovery recovery;
}

String driverLocationErrorMessage(Object error) => switch (error) {
  DriverLocationFailure(:final message) => message,
  LocationServiceDisabledException() =>
    'فعّل خدمة الموقع من إعدادات الجهاز ثم حاول مرة أخرى.',
  PermissionDeniedException() =>
    'اسمح بالوصول إلى الموقع من إعدادات الجهاز ثم حاول مرة أخرى.',
  TimeoutException() => 'تعذر الحصول على موقعك الآن. حاول مرة أخرى.',
  _ => 'تعذر تحديث موقعك الحالي. حاول مرة أخرى.',
};

class DriverForegroundLocation {
  DriverForegroundLocation(DriverService service, {this.onError})
    : _service = service,
      _session = _sessionFor(service);

  // ponytail: process-local sharing prevents duplicate screen streams; move
  // to an app-scoped coordinator when OS lifecycle/background tracking lands.
  static final Map<DriverService, _LocationSession> _sessions =
      Map<DriverService, _LocationSession>.identity();

  final DriverService _service;
  final _LocationSession _session;
  final void Function(String message)? onError;
  bool _attached = false;
  bool _activeTrip = false;

  static _LocationSession _sessionFor(DriverService service) =>
      _sessions.putIfAbsent(service, () => _LocationSession(service));

  DriverLocationRecovery? get recoveryAction => _session.recoveryAction;

  Future<void> uploadNow() =>
      _session.captureAndUpload(force: true, allowWithoutClient: !_attached);

  Future<void> pauseForOffline() => _session.pauseForOffline();

  Future<void> prepareForOnline() => _session.prepareForOnline();

  Future<void> resumeAfterFailedOffline() =>
      _session.resumeAfterFailedOffline();

  Future<void> start({bool uploadFirst = true, bool activeTrip = false}) async {
    if (!_attached) {
      _activeTrip = activeTrip;
      _attached = true;
      await _session.attach(this);
    } else if (_activeTrip != activeTrip) {
      await _session.updateMode(this, activeTrip);
    }
    await _session.ensureRunning(uploadFirst: uploadFirst);
  }

  Future<void> stop() async {
    if (!_attached) return;
    _attached = false;
    await _session.detach(this);
    if (!_session.hasClients) _sessions.remove(_service);
  }

  Future<bool> openRecoverySettings() async {
    final recovery = _session.recoveryAction;
    if (recovery == null) return false;
    try {
      return switch (recovery) {
        DriverLocationRecovery.locationSettings =>
          await Geolocator.openLocationSettings(),
        DriverLocationRecovery.appSettings =>
          await Geolocator.openAppSettings(),
      };
    } catch (_) {
      return false;
    }
  }
}

class _LocationSession extends WidgetsBindingObserver {
  _LocationSession(this.service);

  final DriverService service;
  final Set<DriverForegroundLocation> _clients = <DriverForegroundLocation>{};
  StreamSubscription<Position>? _subscription;
  Timer? _heartbeat;
  Future<void> _lifecycle = Future<void>.value();
  DateTime? _lastUpload;
  Position? _lastUploadedPosition;
  Future<void>? _uploading;
  DriverLocationMode? _streamMode;
  DriverLocationRecovery? recoveryAction;
  Future<void>? _permissionCheck;
  var _foreground = true;
  var _backgroundAllowed = false;
  AppLifecycleState? _lifecycleState;
  var _offlinePaused = false;
  var _generation = 0;

  DriverLocationMode get mode => _clients.any((client) => client._activeTrip)
      ? DriverLocationMode.activeTrip
      : DriverLocationMode.idle;
  bool get hasClients => _clients.isNotEmpty;

  Future<void> attach(DriverForegroundLocation client) {
    final previousMode = mode;
    if (!_clients.add(client)) return Future<void>.value();
    _generation++;
    if (_clients.length == 1) {
      _lifecycleState =
          WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
      _foreground = driverLocationAllowsForegroundUpdates(
        _lifecycleState!,
      );
      _backgroundAllowed = driverLocationAllowsBackgroundUpdates(
        _lifecycleState!,
        mode,
      );
      WidgetsBinding.instance.addObserver(this);
    }
    if (mode != previousMode) {
      _recomputeLifecyclePolicy();
    }
    return Future<void>.value();
  }

  Future<void> updateMode(
    DriverForegroundLocation client,
    bool activeTrip,
  ) {
    final previousMode = mode;
    client._activeTrip = activeTrip;
    if (mode != previousMode) {
      _recomputeLifecyclePolicy();
    }
    _generation++;
    // Foreground start() checks permission before syncing. In background we
    // only need to stop/reconfigure an existing stream; _syncStream will not
    // create a new foreground service there.
    return _foreground ? Future<void>.value() : _enqueue(_syncStream);
  }

  Future<void> ensureRunning({required bool uploadFirst}) => _enqueue(() async {
    if (!_foreground || _offlinePaused || _clients.isEmpty) return;
    await _ensurePermission();
    if (!_foreground || _offlinePaused || _clients.isEmpty) return;
    if (uploadFirst) await captureAndUpload(force: true);
    await _syncStream();
  });

  Future<void> pauseForOffline() {
    if (!_offlinePaused) {
      _offlinePaused = true;
      _generation++;
    }
    return _enqueue(() async {
      await _stopStream();
      final upload = _uploading;
      if (upload != null) {
        try {
          await upload;
        } catch (_) {
          // The pending write settled, so the availability change can continue.
        }
      }
    });
  }

  Future<void> prepareForOnline() => _enqueue(() async {
    if (!_offlinePaused) return;
    _offlinePaused = false;
    _generation++;
  });

  Future<void> resumeAfterFailedOffline() => _enqueue(() async {
    if (!_offlinePaused) return;
    _offlinePaused = false;
    _generation++;
    if (!_foreground || _offlinePaused || _clients.isEmpty) return;
    await _ensurePermission();
    await captureAndUpload(force: true);
    await _syncStream();
  });

  Future<void> detach(DriverForegroundLocation client) {
    final previousMode = mode;
    if (_clients.remove(client)) _generation++;
    if (mode != previousMode) _recomputeLifecyclePolicy();
    return _enqueue(() async {
      if (_clients.isEmpty) {
        WidgetsBinding.instance.removeObserver(this);
        await _stopStream();
        final upload = _uploading;
        if (upload != null) await upload;
        return;
      }
      await _syncStream();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    final foreground = driverLocationAllowsForegroundUpdates(state);
    if (!foreground) {
      _foreground = false;
      _backgroundAllowed = driverLocationAllowsBackgroundUpdates(state, mode);
      _generation++;
      if (!_backgroundAllowed) {
        unawaited(_enqueue(_stopStream));
      }
      return;
    }
    _foreground = true;
    _backgroundAllowed = false;
    if (_clients.isEmpty) return;
    _generation++;
    unawaited(
      _enqueue(() async {
        if (!_foreground || _clients.isEmpty) return;
        await _ensurePermission();
        if (!_foreground || _clients.isEmpty) return;
        await captureAndUpload(force: true);
        if (!_foreground || _clients.isEmpty) return;
        await _syncStream();
      }).catchError((Object error) {
        _report(error);
      }),
    );
  }

  Future<void> captureAndUpload({
    required bool force,
    bool allowWithoutClient = false,
  }) async {
    final generation = _generation;
    if (!_canOperate(generation, allowWithoutClient: allowWithoutClient)) {
      return;
    }
    await _ensurePermission();
    if (!_canOperate(generation, allowWithoutClient: allowWithoutClient)) {
      return;
    }
    final pendingUpload = _uploading;
    if (pendingUpload != null) {
      if (!force) return;
      await pendingUpload;
      if (!_canOperate(generation, allowWithoutClient: allowWithoutClient)) {
        return;
      }
    }
    late final Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: DriverLocationPolicy.settings(mode, bounded: true),
      );
    } catch (error) {
      final normalized = _normalizeLocationError(error);
      _rememberRecovery(normalized);
      if (!identical(normalized, error)) throw normalized;
      rethrow;
    }
    if (!_canOperate(generation, allowWithoutClient: allowWithoutClient)) {
      return;
    }
    await _uploadPosition(
      position,
      force: force,
      generation: generation,
      allowWithoutClient: allowWithoutClient,
    );
  }

  Future<void> _syncStream() async {
    if ((!_foreground &&
            (!_backgroundAllowed || mode != DriverLocationMode.activeTrip)) ||
        _offlinePaused ||
        _clients.isEmpty) {
      await _stopStream();
      return;
    }
    // geolocator_android starts its FGS when the stream is created. A
    // while-in-use permission cannot create that service from background.
    if (!_foreground && _subscription == null) {
      await _stopStream();
      return;
    }
    final wantedMode = mode;
    if (_subscription == null) {
      _startStream(wantedMode);
    } else if (_streamMode != wantedMode) {
      await _stopStream();
      _startStream(wantedMode);
    }
  }

  void _startStream(DriverLocationMode streamMode) {
    final plan = DriverLocationPolicy.forMode(streamMode);
    _streamMode = streamMode;
    _subscription =
        Geolocator.getPositionStream(
          locationSettings: DriverLocationPolicy.settings(streamMode),
        ).listen((position) {
          final generation = _generation;
          unawaited(
            _uploadPosition(
              position,
              force: false,
              generation: generation,
            ).catchError((Object error) {
              _report(error);
            }),
          );
        }, onError: (Object error, StackTrace _) => _report(error));
    _heartbeat = Timer.periodic(plan.heartbeatInterval, (_) {
      unawaited(
        captureAndUpload(force: true).catchError((Object error) {
          _report(error);
        }),
      );
    });
  }

  Future<void> _stopStream() async {
    _heartbeat?.cancel();
    _heartbeat = null;
    await _subscription?.cancel();
    _subscription = null;
    _streamMode = null;
  }

  Future<void> _uploadPosition(
    Position position, {
    required bool force,
    required int generation,
    bool allowWithoutClient = false,
  }) async {
    while (true) {
      final pending = _uploading;
      if (pending == null) break;
      if (!force) return;
      await pending;
      if (!_canOperate(generation, allowWithoutClient: allowWithoutClient)) {
        return;
      }
    }
    if (!_canOperate(generation, allowWithoutClient: allowWithoutClient) ||
        (!force && !_shouldUpload(position))) {
      return;
    }
    if (!_canOperate(generation, allowWithoutClient: allowWithoutClient)) {
      return;
    }
    final upload = service.updateLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
      headingDegrees: position.heading.isFinite && position.heading >= 0
          ? position.heading
          : null,
      speedMps: position.speed.isFinite && position.speed >= 0
          ? position.speed
          : null,
    );
    _uploading = upload;
    try {
      await upload;
      if (!_canOperate(generation, allowWithoutClient: allowWithoutClient)) {
        return;
      }
      _lastUpload = DateTime.now();
      _lastUploadedPosition = position;
      recoveryAction = null;
    } finally {
      if (identical(_uploading, upload)) _uploading = null;
    }
  }

  bool _canOperate(int generation, {bool allowWithoutClient = false}) =>
      generation == _generation &&
      (_foreground ||
          (_backgroundAllowed && mode == DriverLocationMode.activeTrip)) &&
      !_offlinePaused &&
      (allowWithoutClient || _clients.isNotEmpty);

  void _recomputeLifecyclePolicy() {
    final state = _lifecycleState ?? AppLifecycleState.resumed;
    _foreground = driverLocationAllowsForegroundUpdates(state);
    _backgroundAllowed = driverLocationAllowsBackgroundUpdates(state, mode);
  }

  bool _shouldUpload(Position position) {
    final plan = DriverLocationPolicy.forMode(mode);
    final lastUpload = _lastUpload;
    if (lastUpload != null &&
        DateTime.now().difference(lastUpload) < plan.minimumUploadInterval) {
      return false;
    }
    final previous = _lastUploadedPosition;
    if (previous == null) return true;
    return Geolocator.distanceBetween(
          previous.latitude,
          previous.longitude,
          position.latitude,
          position.longitude,
        ) >=
        plan.distanceFilterMeters;
  }

  Future<void> _ensurePermission() {
    final pending = _permissionCheck;
    if (pending != null) return pending;
    final check = _checkPermission();
    _permissionCheck = check.whenComplete(() => _permissionCheck = null);
    return _permissionCheck!;
  }

  Future<void> _checkPermission() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const DriverLocationFailure(
          'فعّل خدمة الموقع من إعدادات الجهاز ثم حاول مرة أخرى.',
          DriverLocationRecovery.locationSettings,
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      switch (permission) {
        case LocationPermission.deniedForever:
          throw const DriverLocationFailure(
            'اسمح بالوصول إلى الموقع من إعدادات التطبيق ثم حاول مرة أخرى.',
            DriverLocationRecovery.appSettings,
          );
        case LocationPermission.denied:
        case LocationPermission.unableToDetermine:
          throw const DriverLocationFailure(
            'إذن الموقع مطلوب للاتصال واستقبال الطلبات.',
            DriverLocationRecovery.appSettings,
          );
        case LocationPermission.whileInUse:
        case LocationPermission.always:
          recoveryAction = null;
      }
    } catch (error) {
      final normalized = _normalizeLocationError(error);
      _rememberRecovery(normalized);
      if (!identical(normalized, error)) throw normalized;
      rethrow;
    }
  }

  Object _normalizeLocationError(Object error) => switch (error) {
    LocationServiceDisabledException() => const DriverLocationFailure(
      'فعّل خدمة الموقع من إعدادات الجهاز ثم حاول مرة أخرى.',
      DriverLocationRecovery.locationSettings,
    ),
    PermissionDeniedException() => const DriverLocationFailure(
      'اسمح بالوصول إلى الموقع من إعدادات التطبيق ثم حاول مرة أخرى.',
      DriverLocationRecovery.appSettings,
    ),
    _ => error,
  };

  void _rememberRecovery(Object error) {
    recoveryAction = switch (error) {
      DriverLocationFailure(:final recovery) => recovery,
      LocationServiceDisabledException() =>
        DriverLocationRecovery.locationSettings,
      PermissionDeniedException() => DriverLocationRecovery.appSettings,
      _ => recoveryAction,
    };
  }

  void _report(Object error) {
    if (!_foreground || _offlinePaused || _clients.isEmpty) return;
    _rememberRecovery(error);
    DriverForegroundLocation? target;
    for (final client in _clients) {
      if (client._activeTrip) target = client;
      target ??= client;
    }
    target?.onError?.call(driverLocationErrorMessage(error));
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final next = _lifecycle.then((_) => action());
    _lifecycle = next.catchError((Object _) {});
    return next;
  }
}
