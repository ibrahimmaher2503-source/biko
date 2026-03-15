/// Generic paginated result that hides Firestore [DocumentSnapshot] from controllers.
///
/// Controllers use this class for cursor-based pagination without importing
/// `cloud_firestore` directly (RULE-06 compliance).
class PaginatedResult<T> {
  const PaginatedResult({required this.items, this.cursor});

  /// The items for the current page.
  final List<T> items;

  /// Opaque pagination cursor for the next page.
  ///
  /// Pass this back to the service method to fetch the next page.
  /// Controllers must NOT inspect or cast this value.
  final Object? cursor;

  /// Whether there are likely more items to fetch.
  ///
  /// Based on whether the current page is full (reached [pageSize]).
  bool hasMore(int pageSize) => items.length >= pageSize;
}
