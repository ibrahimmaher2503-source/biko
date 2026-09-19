import 'dart:async';
import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:user_app/features/orders/order_models.dart';
import 'package:user_app/features/orders/order_rules.dart';
import 'package:user_app/features/maps/map_gateway.dart';

Future<LocationSelection?> pickMapLocation(
  BuildContext context, {
  required String title,
  LocationSelection? initial,
}) => Navigator.of(context).push<LocationSelection>(
  MaterialPageRoute(
    builder: (_) => LocationPickerPage(title: title, initial: initial),
  ),
);

class LocationPickerPage extends ConsumerStatefulWidget {
  const LocationPickerPage({required this.title, this.initial, super.key});
  final String title;
  final LocationSelection? initial;

  @override
  ConsumerState<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends ConsumerState<LocationPickerPage> {
  static const _cairo = LatLng(30.0444, 31.2357);
  final _search = TextEditingController();
  final _sessionToken = newCreationIntentId();
  Timer? _debounce;
  GoogleMapController? _map;
  late LocationSelection? _selected = widget.initial;
  List<PlaceSuggestion> _suggestions = const [];
  bool _loading = false;
  String? _error;
  String? _completedQuery;
  int _searchGeneration = 0;
  int _selectionGeneration = 0;
  _LocationRecovery? _recovery;

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _map?.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final query = _search.text.trim();
    final generation = ++_searchGeneration;
    setState(() {
      _suggestions = const [];
      _completedQuery = null;
      _error = null;
      _recovery = null;
    });
    if (query.length < 3) {
      setState(() {
        _loading = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _loading = true;
        _error = null;
        _recovery = null;
        _completedQuery = null;
      });
      try {
        final result = await ref
            .read(mapGatewayProvider)
            .search(query, _sessionToken);
        if (mounted && generation == _searchGeneration) {
          setState(() {
            _suggestions = result;
            _completedQuery = query;
          });
        }
      } catch (_) {
        if (mounted && generation == _searchGeneration) {
          setState(() => _error = 'تعذر البحث. حاول مرة أخرى.');
        }
      } finally {
        if (mounted && generation == _searchGeneration) {
          setState(() => _loading = false);
        }
      }
    });
  }

  Future<void> _chooseSuggestion(PlaceSuggestion suggestion) async {
    _debounce?.cancel();
    _searchGeneration++;
    final selectionGeneration = ++_selectionGeneration;
    setState(() {
      _loading = true;
      _error = null;
      _recovery = null;
      _suggestions = const [];
      _completedQuery = null;
    });
    try {
      final location = await ref
          .read(mapGatewayProvider)
          .resolve(suggestion, _sessionToken);
      if (!mounted || selectionGeneration != _selectionGeneration) return;
      setState(() => _selected = location);
      await _map?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(location.latitude, location.longitude),
          16,
        ),
      );
    } catch (_) {
      if (mounted && selectionGeneration == _selectionGeneration) {
        setState(() => _error = 'تعذر تحميل المكان المحدد.');
      }
    } finally {
      if (mounted && selectionGeneration == _selectionGeneration) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    _debounce?.cancel();
    _searchGeneration++;
    final selectionGeneration = ++_selectionGeneration;
    setState(() {
      _loading = true;
      _error = null;
      _recovery = null;
      _suggestions = const [];
      _completedQuery = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const _LocationFailure(
          'فعّل خدمة الموقع أولًا.',
          _LocationRecovery.settings,
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw const _LocationFailure(
          'اسمح بالموقع من إعدادات الجهاز.',
          _LocationRecovery.appSettings,
        );
      }
      if (permission == LocationPermission.denied) {
        throw const BusinessFailure('إذن الموقع مطلوب لاستخدام موقعك الحالي.');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      final location = LocationSelection(
        displayAddress: 'موقعي الحالي',
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (!mounted || selectionGeneration != _selectionGeneration) return;
      setState(() => _selected = location);
      await _map?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          16,
        ),
      );
    } on _LocationFailure catch (error) {
      if (mounted && selectionGeneration == _selectionGeneration) {
        setState(() {
          _error = error.message;
          _recovery = error.recovery;
        });
      }
    } on BusinessFailure catch (error) {
      if (mounted && selectionGeneration == _selectionGeneration) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted && selectionGeneration == _selectionGeneration) {
        setState(() => _error = 'تعذر تحديد موقعك الآن.');
      }
    } finally {
      if (mounted && selectionGeneration == _selectionGeneration) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final initial = selected == null
        ? _cairo
        : LatLng(selected.latitude, selected.longitude);
    return Scaffold(
      appBar: AppTopBar(title: widget.title),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: initial, zoom: 13),
            myLocationButtonEnabled: false,
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) => _map = controller,
            onTap: (point) {
              _debounce?.cancel();
              _searchGeneration++;
              _selectionGeneration++;
              setState(() {
                _selected = LocationSelection(
                  displayAddress:
                      '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
                  latitude: point.latitude,
                  longitude: point.longitude,
                );
                _loading = false;
                _suggestions = const [];
                _completedQuery = null;
                _error = null;
                _recovery = null;
              });
            },
            markers: selected == null
                ? const {}
                : {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: LatLng(selected.latitude, selected.longitude),
                    ),
                  },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(BikoSpace.md),
              child: Column(
                children: [
                  Material(
                    color: Theme.of(context).colorScheme.surface,
                    elevation: 1,
                    borderRadius: BorderRadius.circular(BikoRadius.medium),
                    child: TextField(
                      key: const Key('places-search'),
                      controller: _search,
                      decoration: InputDecoration(
                        hintText: 'ابحث عن منطقة أو عنوان',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _loading
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  if (_suggestions.isNotEmpty)
                    Flexible(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 260),
                        margin: const EdgeInsets.only(top: BikoSpace.sm),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(
                            BikoRadius.medium,
                          ),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        child: ListView(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          children: [
                            for (final suggestion in _suggestions)
                              ListTile(
                                dense: true,
                                leading: const Icon(Icons.place_outlined),
                                title: Text(
                                  suggestion.label,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () => _chooseSuggestion(suggestion),
                              ),
                          ],
                        ),
                      ),
                    ),
                  if (_completedQuery == _search.text.trim() &&
                      _suggestions.isEmpty &&
                      _error == null)
                    _SearchState(
                      icon: Icons.search_off_rounded,
                      message:
                          'لا توجد نتائج مطابقة. جرّب عنوانًا أو منطقة أخرى.',
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: BikoSpace.sm),
                      child: Material(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(BikoRadius.small),
                        child: Padding(
                          padding: const EdgeInsets.all(BikoSpace.sm),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.error_outline_rounded,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  const SizedBox(width: BikoSpace.sm),
                                  Expanded(child: Text(_error!)),
                                ],
                              ),
                              if (_recovery case final recovery?)
                                Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: TextButton(
                                    onPressed: _loading
                                        ? null
                                        : () => _recoverLocation(recovery),
                                    child: Text(
                                      recovery == _LocationRecovery.settings
                                          ? 'فتح إعدادات الموقع'
                                          : 'فتح إعدادات التطبيق',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (!keyboardOpen || _suggestions.isEmpty) const Spacer(),
                  if (!keyboardOpen)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FloatingActionButton.small(
                        heroTag: 'current-location',
                        tooltip: 'استخدم موقعي الحالي',
                        onPressed: _loading ? null : _useCurrentLocation,
                        child: const Icon(Icons.my_location_rounded),
                      ),
                    ),
                  const SizedBox(height: BikoSpace.sm),
                  Card(
                    color: Theme.of(context).colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(BikoSpace.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            selected?.displayAddress ??
                                'اختر نقطة من الخريطة أو ابحث عن مكان',
                            maxLines: keyboardOpen ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: BikoSpace.sm),
                          PrimaryButton(
                            key: const Key('confirm-map-location'),
                            onPressed: selected == null || _loading
                                ? null
                                : () => Navigator.of(context).pop(selected),
                            icon: Icons.check_rounded,
                            label: 'تأكيد الموقع',
                            isLoading: _loading,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _recoverLocation(_LocationRecovery recovery) async {
    if (recovery == _LocationRecovery.settings) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
    if (mounted) _useCurrentLocation();
  }
}

enum _LocationRecovery { settings, appSettings }

class _LocationFailure implements Exception {
  const _LocationFailure(this.message, this.recovery);
  final String message;
  final _LocationRecovery recovery;
}

class _SearchState extends StatelessWidget {
  const _SearchState({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: BikoSpace.sm),
    child: Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(BikoRadius.small),
      child: Padding(
        padding: const EdgeInsets.all(BikoSpace.sm),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: BikoSpace.sm),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    ),
  );
}
