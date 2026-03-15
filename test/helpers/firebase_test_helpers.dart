import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

/// Firebase test helper utilities for creating mock Firebase services.
///
/// This helper provides factory methods for:
/// - FakeFirebaseFirestore (in-memory Firestore for testing)
/// - Mock Firebase Auth instances
/// - Seeding Firestore with test data
/// - Clearing Firestore between tests
class FirebaseTestHelper {
  /// Creates a fake Firestore instance (in-memory).
  ///
  /// This provides a fully functional Firestore implementation that:
  /// - Runs entirely in memory (no network calls)
  /// - Supports queries, snapshots, batch writes
  /// - Resets between tests for isolation
  ///
  /// Example:
  /// ```dart
  /// final firestore = FirebaseTestHelper.createFakeFirestore();
  /// await firestore.collection('users').doc('user1').set({'name': 'Ahmed'});
  /// final doc = await firestore.collection('users').doc('user1').get();
  /// expect(doc.data()!['name'], equals('Ahmed'));
  /// ```
  static FakeFirebaseFirestore createFakeFirestore() {
    return FakeFirebaseFirestore();
  }

  /// Creates a mock Firebase Auth instance.
  ///
  /// Note: For now, this returns a placeholder. In actual tests, you'll use
  /// firebase_auth_mocks package or manual mocks.
  ///
  /// Example:
  /// ```dart
  /// final auth = FirebaseTestHelper.createMockAuth();
  /// // Use with MockFirebaseAuth from firebase_auth_mocks package
  /// ```
  static auth.FirebaseAuth? createMockAuth({auth.User? initialUser}) {
    // Note: Actual implementation will use firebase_auth_mocks package
    // For now, returning null as a placeholder
    // Example: return MockFirebaseAuth(signedIn: initialUser != null, user: initialUser);
    return null;
  }

  /// Seeds Firestore with test data.
  ///
  /// Accepts data in format: `{collection: [document maps]}`
  ///
  /// Example:
  /// ```dart
  /// final firestore = FirebaseTestHelper.createFakeFirestore();
  /// await FirebaseTestHelper.seedFirestore(firestore, {
  ///   'users': [
  ///     {'uid': 'user1', 'name': 'Ahmed', 'phone': '+201234567890'},
  ///     {'uid': 'user2', 'name': 'Fatima', 'phone': '+209876543210'},
  ///   ],
  ///   'trips': [
  ///     {'tripId': 'trip1', 'customerId': 'user1', 'status': 'pending'},
  ///   ],
  /// });
  /// ```
  static Future<void> seedFirestore(
    FakeFirebaseFirestore firestore,
    Map<String, List<Map<String, dynamic>>> data,
  ) async {
    for (final entry in data.entries) {
      final collection = entry.key;
      final docs = entry.value;

      for (final doc in docs) {
        // Use document ID from data if present, otherwise auto-generate
        final docId = doc['uid'] ?? doc['tripId'] ?? doc['bidId'] ?? doc['id'];
        if (docId != null) {
          await firestore.collection(collection).doc(docId as String).set(doc);
        } else {
          await firestore.collection(collection).add(doc);
        }
      }
    }
  }

  /// Clears all data from fake Firestore.
  ///
  /// Deletes all documents from known collections to ensure clean state
  /// between tests.
  ///
  /// Example:
  /// ```dart
  /// tearDown(() async {
  ///   await FirebaseTestHelper.clearFirestore(firestore);
  /// });
  /// ```
  static Future<void> clearFirestore(FakeFirebaseFirestore firestore) async {
    final collections = [
      'users',
      'trips',
      'bids',
      'wallets',
      'transactions',
      'promo_codes',
      'referrals',
      'ratings',
      'notifications',
      'documents',
      'chat_messages',
    ];

    for (final collection in collections) {
      final docs = await firestore.collection(collection).get();
      for (final doc in docs.docs) {
        await doc.reference.delete();
      }
    }
  }
}
