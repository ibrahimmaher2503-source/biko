import 'dart:async';
import 'package:biko/core/services/location_service.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// BikeRide map widget
///
/// Encapsulates the GoogleMap widget with integrated Real-time location
/// tracking, custom styling, polylines, and markers.
class AppMapWidget extends StatefulWidget {
  const AppMapWidget({
    super.key,
    this.height = 300.0,
    this.initialPosition,
    this.zoom = 15.0,
    this.markers,
    this.polylines,
  });

  /// Widget height (default 300dp)
  final double height;

  /// Initial map position (latitude, longitude)
  final LatLng? initialPosition;

  /// Initial zoom level (default 15)
  final double zoom;

  /// Optional set of markers to display (e.g., drivers)
  final Set<Marker>? markers;

  /// Optional set of polylines to display (e.g., routes)
  final Set<Polyline>? polylines;

  @override
  State<AppMapWidget> createState() => _AppMapWidgetState();
}

class _AppMapWidgetState extends State<AppMapWidget> {
  final Completer<GoogleMapController> _controller = Completer();
  late final LocationService _locationService;
  StreamSubscription<Position>? _locationSubscription;
  String? _lightMapStyle;
  String? _darkMapStyle;
  String? _currentMapStyle;

  @override
  void initState() {
    super.initState();
    _locationService = Get.find<LocationService>();
    _loadMapStyles();
    _initLocationTracking();
  }

  /// Loads JSON map styles from assets
  Future<void> _loadMapStyles() async {
    try {
      _lightMapStyle = await rootBundle.loadString(
        'assets/map_styles/map_style_light.json',
      );
      _darkMapStyle = await rootBundle.loadString(
        'assets/map_styles/map_style_dark.json',
      );
      _applyThemeStyle();
    } catch (e) {
      debugPrint('Failed to load map styles: $e');
    }
  }

  /// Applies the theme based on the current context brightness
  void _applyThemeStyle() {
    if (!mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final styleToApply = isDark ? _darkMapStyle : _lightMapStyle;

    if (_currentMapStyle != styleToApply && styleToApply != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _currentMapStyle = styleToApply;
          });
        }
      });
    }
  }

  /// Subscribes to the location stream and animates the camera
  Future<void> _initLocationTracking() async {
    final stream = _locationService.getLocationStream();
    if (stream != null) {
      _listenToStream(stream);
    } else {
      // If we don't have a stream yet, maybe permissions are pending.
      // Ask for permission and then try the stream again.
      await _locationService.getCurrentPosition();
      final retryStream = _locationService.getLocationStream();
      if (retryStream != null) {
        _listenToStream(retryStream);
      }
    }
  }

  void _listenToStream(Stream<Position> stream) {
    _locationSubscription = stream.listen((Position position) async {
      if (!_controller.isCompleted) return;
      final controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
      );
    });
  }

  @override
  void didUpdateWidget(AppMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If polylines changed significantly, we could auto-zoom to bounds here,
    // but the caller might want to control bounds explicitly using the controller
    // or through map callbacks. We will auto-bound later if specified by task.
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Whenever build is called (e.g., theme changes), re-apply the correct style
    _applyThemeStyle();

    return Container(
      height: widget.height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target:
              widget.initialPosition ??
              const LatLng(30.0444, 31.2357), // Default Cairo
          zoom: widget.zoom,
        ),
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
          _applyThemeStyle();
        },
        style: _currentMapStyle,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        markers: widget.markers ?? {},
        polylines: widget.polylines ?? {},
        zoomControlsEnabled: false,
      ),
    );
  }
}
