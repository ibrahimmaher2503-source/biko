/// A recent/saved location for quick re-use on the home screen.
///
/// Not persisted to Firestore in this feature — populated from
/// trip history or placeholder data.
class RecentLocation {
  const RecentLocation({
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.iconType = 'history',
  });

  /// Display name (e.g., "Benha University")
  final String name;

  /// Full address (e.g., "Kafr Saad, Banha, Al Qalyubia")
  final String address;

  /// Latitude coordinate
  final double lat;

  /// Longitude coordinate
  final double lng;

  /// Icon type: "history", "work", "home", "favorite"
  final String iconType;
}
