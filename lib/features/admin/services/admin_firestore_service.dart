import 'package:biko/core/models/document_model.dart';
import 'package:biko/core/models/driver_profile_model.dart';
import 'package:biko/core/models/enums.dart';
import 'package:biko/core/models/trip_model.dart';
import 'package:biko/core/models/user_model.dart';
import 'package:biko/features/admin/models/approval_stats_model.dart';
import 'package:biko/features/admin/models/driver_review_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_database/firebase_database.dart' hide Query;
import 'package:flutter/material.dart' show DateTimeRange;

/// Paginated query result with cursor support.
class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    this.lastDocument,
    this.hasMore = false,
  });

  final List<T> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
}

/// Admin-specific Firestore queries with cursor-based pagination,
/// search, and aggregation support.
class AdminFirestoreService {
  AdminFirestoreService._();

  static final _firestore = FirebaseFirestore.instance;
  static const _pageSize = 25;

  // ==================== Users ====================

  static Future<PaginatedResult<UserModel>> getPaginatedUsers({
    required UserType type,
    UserStatus? statusFilter,
    DocumentSnapshot? startAfter,
    int pageSize = _pageSize,
  }) async {
    Query query = _firestore
        .collection('users')
        .where('type', isEqualTo: type.toJson())
        .orderBy('created_at', descending: true);

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter.toJson());
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.limit(pageSize + 1).get();
    final hasMore = snapshot.docs.length > pageSize;
    final docs = hasMore
        ? snapshot.docs.take(pageSize).toList()
        : snapshot.docs;

    return PaginatedResult(
      items: docs
          .map((d) => UserModel.fromJson(d.data() as Map<String, dynamic>))
          .toList(),
      lastDocument: docs.isNotEmpty ? docs.last : null,
      hasMore: hasMore,
    );
  }

  // ==================== Trips ====================

  static Future<PaginatedResult<TripModel>> getPaginatedTrips({
    TripType? typeFilter,
    TripStatus? statusFilter,
    DateTimeRange? dateRange,
    DocumentSnapshot? startAfter,
    int pageSize = _pageSize,
  }) async {
    Query query = _firestore
        .collection('trips')
        .orderBy('created_at', descending: true);

    if (typeFilter != null) {
      query = query.where('type', isEqualTo: typeFilter.toJson());
    }

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter.toJson());
    }

    if (dateRange != null) {
      query = query
          .where(
            'created_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.start),
          )
          .where(
            'created_at',
            isLessThanOrEqualTo: Timestamp.fromDate(dateRange.end),
          );
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.limit(pageSize + 1).get();
    final hasMore = snapshot.docs.length > pageSize;
    final docs = hasMore
        ? snapshot.docs.take(pageSize).toList()
        : snapshot.docs;

    return PaginatedResult(
      items: docs
          .map((d) => TripModel.fromMap(d.data() as Map<String, dynamic>))
          .toList(),
      lastDocument: docs.isNotEmpty ? docs.last : null,
      hasMore: hasMore,
    );
  }

  // ==================== Transactions ====================

  static Future<PaginatedResult<Map<String, dynamic>>>
  getPaginatedTransactions({
    String? methodFilter,
    String? typeFilter,
    DateTimeRange? dateRange,
    DocumentSnapshot? startAfter,
    int pageSize = _pageSize,
  }) async {
    Query query = _firestore
        .collection('transactions')
        .orderBy('created_at', descending: true);

    if (methodFilter != null) {
      query = query.where('method', isEqualTo: methodFilter);
    }

    if (typeFilter != null) {
      query = query.where('type', isEqualTo: typeFilter);
    }

    if (dateRange != null) {
      query = query
          .where(
            'created_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.start),
          )
          .where(
            'created_at',
            isLessThanOrEqualTo: Timestamp.fromDate(dateRange.end),
          );
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.limit(pageSize + 1).get();
    final hasMore = snapshot.docs.length > pageSize;
    final docs = hasMore
        ? snapshot.docs.take(pageSize).toList()
        : snapshot.docs;

    return PaginatedResult(
      items: docs.map((d) => d.data() as Map<String, dynamic>).toList(),
      lastDocument: docs.isNotEmpty ? docs.last : null,
      hasMore: hasMore,
    );
  }

  // ==================== Documents ====================

  static Future<List<DocumentModel>> getPendingDocuments() async {
    final snapshot = await _firestore
        .collection('documents')
        .where('status', isEqualTo: 'pending')
        .orderBy('created_at', descending: false)
        .get();

    return snapshot.docs.map((d) => DocumentModel.fromJson(d.data())).toList();
  }

  static Stream<int> pendingDocumentCountStream() {
    return _firestore
        .collection('documents')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // ==================== Search ====================

  static Future<List<UserModel>> searchUsersByPhone(String phone) async {
    final snapshot = await _firestore
        .collection('users')
        .where('phone', isGreaterThanOrEqualTo: phone)
        .where('phone', isLessThanOrEqualTo: '$phone\uf8ff')
        .limit(10)
        .get();

    return snapshot.docs.map((d) => UserModel.fromJson(d.data())).toList();
  }

  static Future<List<UserModel>> searchUsersByName(String name) async {
    final lower = name.toLowerCase();
    final snapshot = await _firestore
        .collection('users')
        .orderBy('name')
        .startAt([lower])
        .endAt(['$lower\uf8ff'])
        .limit(10)
        .get();

    return snapshot.docs.map((d) => UserModel.fromJson(d.data())).toList();
  }

  // ==================== App Config ====================

  static Future<Map<String, dynamic>?> getAppConfig() async {
    final doc = await _firestore.collection('app_config').doc('config').get();
    if (!doc.exists || doc.data() == null) return null;
    return doc.data();
  }

  // ==================== Daily Stats ====================

  static Future<int> getCountByQuery(
    String collection,
    List<MapEntry<String, dynamic>> whereConditions,
  ) async {
    Query query = _firestore.collection(collection);
    for (final condition in whereConditions) {
      query = query.where(condition.key, isEqualTo: condition.value);
    }
    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }

  static Future<int> getTripsTodayCount() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final snapshot = await _firestore
        .collection('trips')
        .where(
          'created_at',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  static Future<double> getRevenueTodaySum() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final snapshot = await _firestore
        .collection('trips')
        .where('status', isEqualTo: 'completed')
        .where(
          'created_at',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .get();

    double total = 0;
    for (final doc in snapshot.docs) {
      total += (doc.data()['commission_amount'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  // ==================== Dashboard Stats ====================

  static Future<int> getPendingDocumentsCount() async {
    final snapshot = await _firestore
        .collection('documents')
        .where('status', isEqualTo: 'pending')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  static Future<int> getUserCountByType(String type) async {
    final snapshot = await _firestore
        .collection('users')
        .where('type', isEqualTo: type)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  static Future<List<Map<String, dynamic>>> getTripsSince(
    DateTime since,
  ) async {
    final snapshot = await _firestore
        .collection('trips')
        .where(
          'created_at',
          isGreaterThanOrEqualTo: Timestamp.fromDate(since),
        )
        .get();
    return snapshot.docs.map((d) => d.data()).toList();
  }

  static Future<double> getCancellationRate({int sampleSize = 100}) async {
    final snapshot = await _firestore
        .collection('trips')
        .orderBy('created_at', descending: true)
        .limit(sampleSize)
        .get();

    int cancelledCount = 0;
    final totalCount = snapshot.docs.length;
    for (final doc in snapshot.docs) {
      if (doc.data()['status'] == 'cancelled') {
        cancelledCount++;
      }
    }
    return totalCount > 0 ? (cancelledCount / totalCount) * 100 : 0.0;
  }

  static Stream<int> onlineDriversStream() {
    final ref = FirebaseDatabase.instance.ref('driver_locations');
    return ref.onValue.map((event) {
      if (event.snapshot.value == null) return 0;
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      int onlineCount = 0;
      data.forEach((key, value) {
        if (value is Map && value['is_online'] == true) {
          final updatedAt = value['updated_at'] as int?;
          if (updatedAt != null) {
            final lastUpdate = DateTime.fromMillisecondsSinceEpoch(updatedAt);
            final diff = DateTime.now().difference(lastUpdate);
            if (diff.inMinutes < 5) {
              onlineCount++;
            }
          }
        }
      });
      return onlineCount;
    });
  }

  static Future<List<Map<String, dynamic>>> getCompletedTripsInRange(
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _firestore
        .collection('trips')
        .where('status', isEqualTo: 'completed')
        .where(
          'completed_at',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start),
        )
        .where(
          'completed_at',
          isLessThanOrEqualTo: Timestamp.fromDate(end),
        )
        .orderBy('completed_at')
        .get();
    return snapshot.docs.map((d) => d.data()).toList();
  }

  static Future<List<TripModel>> getRecentTrips({int limit = 10}) async {
    final snapshot = await _firestore
        .collection('trips')
        .orderBy('created_at', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => TripModel.fromMap(doc.data()))
        .toList();
  }

  // ==================== Driver Management ====================

  static Future<PaginatedResult<UserModel>> getDriverUsersForAdmin({
    String? search,
    DocumentSnapshot? startAfter,
    int pageSize = _pageSize,
  }) async {
    Query query = _firestore
        .collection('users')
        .where('type', isEqualTo: 'driver');

    if (search != null && search.isNotEmpty) {
      query = query
          .where('name', isGreaterThanOrEqualTo: search)
          .where('name', isLessThanOrEqualTo: '$search\uf8ff');
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.limit(pageSize).get();

    return PaginatedResult(
      items: snapshot.docs
          .map((d) => UserModel.fromJson(d.data() as Map<String, dynamic>))
          .toList(),
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      hasMore: snapshot.docs.length >= pageSize,
    );
  }

  static Future<UserModel?> getUserById(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromJson(doc.data()!);
  }

  static Future<DriverProfileModel?> getDriverProfile(String uid) async {
    final doc =
        await _firestore.collection('driver_profiles').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return DriverProfileModel.fromJson(doc.data()!);
  }

  static Future<List<DocumentModel>> getDriverDocuments(String uid) async {
    final snapshot = await _firestore
        .collection('documents')
        .where('driver_uid', isEqualTo: uid)
        .get();
    return snapshot.docs
        .map((d) => DocumentModel.fromJson(d.data()))
        .toList();
  }

  static Future<void> callCloudFunction(
    String name,
    Map<String, dynamic> params,
  ) async {
    final callable = FirebaseFunctions.instance.httpsCallable(name);
    await callable.call(params);
  }

  static Future<void> batchRejectDocuments(
    String driverUid,
    String reason,
  ) async {
    final snapshot = await _firestore
        .collection('documents')
        .where('driver_uid', isEqualTo: driverUid)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'status': 'rejected',
        'admin_note': reason,
        'updated_at': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  static Future<void> updateUserStatus(String uid, String status) async {
    await _firestore.collection('users').doc(uid).update({
      'status': status,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // ==================== Approval Management ====================

  static Future<List<DriverReviewData>> getPendingDriversWithProfiles() async {
    final usersSnapshot = await _firestore
        .collection('users')
        .where('type', isEqualTo: 'driver')
        .where('status', isEqualTo: 'pending_approval')
        .orderBy('created_at', descending: false)
        .get();

    final List<DriverReviewData> results = [];

    for (final userDoc in usersSnapshot.docs) {
      final user = UserModel.fromJson(userDoc.data());

      final profileDoc = await _firestore
          .collection('driver_profiles')
          .doc(user.uid)
          .get();
      final profile = profileDoc.exists
          ? DriverProfileModel.fromJson(profileDoc.data()!)
          : DriverProfileModel(uid: user.uid);

      final docsSnapshot = await _firestore
          .collection('documents')
          .where('driver_uid', isEqualTo: user.uid)
          .get();
      final documents = docsSnapshot.docs
          .map((d) => DocumentModel.fromJson(d.data()))
          .toList();

      results.add(DriverReviewData(
        user: user,
        driverProfile: profile,
        documents: documents,
      ));
    }

    return results;
  }

  static Future<DriverReviewData?> getDriverReviewData(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists || userDoc.data() == null) return null;

    final user = UserModel.fromJson(userDoc.data()!);

    final profileDoc = await _firestore
        .collection('driver_profiles')
        .doc(uid)
        .get();
    final profile = profileDoc.exists
        ? DriverProfileModel.fromJson(profileDoc.data()!)
        : DriverProfileModel(uid: uid);

    final docsSnapshot = await _firestore
        .collection('documents')
        .where('driver_uid', isEqualTo: uid)
        .get();
    final documents = docsSnapshot.docs
        .map((d) => DocumentModel.fromJson(d.data()))
        .toList();

    return DriverReviewData(
      user: user,
      driverProfile: profile,
      documents: documents,
    );
  }

  static Future<void> batchRejectDocumentsByIds(
    List<String> docIds,
    String reason,
  ) async {
    final batch = _firestore.batch();
    for (final docId in docIds) {
      batch.update(
        _firestore.collection('documents').doc(docId),
        {
          'status': 'rejected',
          'admin_note': reason,
          'updated_at': FieldValue.serverTimestamp(),
        },
      );
    }
    await batch.commit();
  }

  static Future<void> rejectDriverCompletely(
    String uid,
    String reason,
  ) async {
    final batch = _firestore.batch();

    batch.update(
      _firestore.collection('users').doc(uid),
      {
        'status': 'suspended',
        'rejection_reason': reason,
        'updated_at': FieldValue.serverTimestamp(),
      },
    );

    final docsSnapshot = await _firestore
        .collection('documents')
        .where('driver_uid', isEqualTo: uid)
        .get();

    for (final doc in docsSnapshot.docs) {
      batch.update(doc.reference, {
        'status': 'rejected',
        'admin_note': reason,
        'updated_at': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  static Future<ApprovalStatsModel> getApprovalStats() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final pendingCount = await _firestore
        .collection('users')
        .where('type', isEqualTo: 'driver')
        .where('status', isEqualTo: 'pending_approval')
        .count()
        .get();

    final approvedToday = await _firestore
        .collection('driver_profiles')
        .where('is_approved', isEqualTo: true)
        .where(
          'approved_at',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .count()
        .get();

    return ApprovalStatsModel(
      pendingCount: pendingCount.count ?? 0,
      approvedTodayCount: approvedToday.count ?? 0,
    );
  }

  // ==================== Financial ====================

  static Future<List<Map<String, dynamic>>> getCompletedTripsForSummary(
    DateTimeRange range,
  ) async {
    final snapshot = await _firestore
        .collection('trips')
        .where('status', isEqualTo: 'completed')
        .where('completed_at', isGreaterThanOrEqualTo: range.start)
        .where('completed_at', isLessThanOrEqualTo: range.end)
        .get();
    return snapshot.docs.map((d) => d.data()).toList();
  }

  static Future<List<Map<String, dynamic>>> getTransactionsInRange(
    DateTimeRange range,
  ) async {
    final snapshot = await _firestore
        .collection('transactions')
        .where('created_at', isGreaterThanOrEqualTo: range.start)
        .where('created_at', isLessThanOrEqualTo: range.end)
        .get();
    return snapshot.docs.map((d) => d.data()).toList();
  }

  /// Converts a Firestore [Timestamp] (or null) to [DateTime].
  ///
  /// Controllers use this to avoid importing `cloud_firestore` directly.
  static DateTime? timestampToDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }

  // ==================== Analytics ====================

  /// Get trips since a date for analytics.
  static Future<List<Map<String, dynamic>>> getTripsWithDateFilter(
    DateTime since,
  ) async {
    final snapshot = await _firestore
        .collection('trips')
        .where(
          'created_at',
          isGreaterThanOrEqualTo: Timestamp.fromDate(since),
        )
        .get();
    return snapshot.docs.map((d) => d.data()).toList();
  }

  /// Get completed trips since a date.
  static Future<List<Map<String, dynamic>>> getCompletedTripsSince(
    DateTime since,
  ) async {
    final snapshot = await _firestore
        .collection('trips')
        .where(
          'created_at',
          isGreaterThanOrEqualTo: Timestamp.fromDate(since),
        )
        .where('status', isEqualTo: 'completed')
        .get();
    return snapshot.docs.map((d) => d.data()).toList();
  }

  /// Get user and driver profile for analytics.
  static Future<Map<String, dynamic>?> getUserAndDriverProfile(
    String uid,
  ) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final driverDoc =
        await _firestore.collection('driver_profiles').doc(uid).get();
    if (!userDoc.exists || !driverDoc.exists) return null;
    return {
      'name': userDoc.data()?['name'] ?? 'Unknown',
      'rating_avg':
          (driverDoc.data()?['rating_avg'] as num?)?.toDouble() ?? 0.0,
    };
  }

  // ==================== Trip Details ====================

  /// Get a single trip by ID.
  static Future<TripModel?> getTripById(String tripId) async {
    final doc = await _firestore.collection('trips').doc(tripId).get();
    if (!doc.exists || doc.data() == null) return null;
    return TripModel.fromMap(doc.data()!);
  }

  /// Get bids subcollection for a trip.
  static Future<List<Map<String, dynamic>>> getTripBids(
    String tripId,
  ) async {
    final snapshot = await _firestore
        .collection('trips')
        .doc(tripId)
        .collection('bids')
        .orderBy('created_at', descending: false)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Get recent transactions (for financial dashboard).
  static Future<List<Map<String, dynamic>>> getRecentTransactions({
    int limit = 20,
  }) async {
    final snapshot = await _firestore
        .collection('transactions')
        .orderBy('created_at', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((d) => d.data()).toList();
  }

  // ==================== Notifications ====================

  /// Record an admin notification.
  static Future<void> recordNotification(
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection('admin_notifications').add(data);
  }

  /// Get sent notification history.
  static Future<List<Map<String, dynamic>>> getNotificationHistory({
    int limit = 100,
  }) async {
    final snapshot = await _firestore
        .collection('admin_notifications')
        .orderBy('sent_at', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
  }

  // ==================== Referrals ====================

  /// Get all referrals.
  static Future<List<Map<String, dynamic>>> getAllReferrals() async {
    final snapshot = await _firestore.collection('referrals').get();
    return snapshot.docs
        .map((d) => {'id': d.id, ...d.data()})
        .toList();
  }

  /// Get rewarded referrals.
  static Future<List<Map<String, dynamic>>> getRewardedReferrals() async {
    final snapshot = await _firestore
        .collection('referrals')
        .where('status', isEqualTo: 'rewarded')
        .get();
    return snapshot.docs
        .map((d) => {'id': d.id, ...d.data()})
        .toList();
  }

  /// Get paginated referral history.
  static Future<PaginatedResult<Map<String, dynamic>>> getPaginatedReferrals({
    DocumentSnapshot? startAfter,
    int pageSize = 20,
  }) async {
    Query query = _firestore
        .collection('referrals')
        .orderBy('created_at', descending: true)
        .limit(pageSize);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    return PaginatedResult(
      items: snapshot.docs
          .map(
            (d) => {'id': d.id, ...(d.data() as Map<String, dynamic>)},
          )
          .toList(),
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      hasMore: snapshot.docs.length >= pageSize,
    );
  }

  // ==================== Promo Codes ====================

  /// Get promo codes ordered by expiry.
  static Future<List<Map<String, dynamic>>> getPromoCodes() async {
    final snapshot = await _firestore
        .collection('promo_codes')
        .orderBy('expiry_date', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['code'] = doc.id;
      return data;
    }).toList();
  }

  /// Create a promo code.
  ///
  /// Converts any [DateTime] value for `expiry_date` to a Firestore
  /// [Timestamp] and adds a server-generated `created_at` field.
  static Future<void> createPromoCode(
    String code,
    Map<String, dynamic> data,
  ) async {
    final payload = Map<String, dynamic>.from(data);
    if (payload['expiry_date'] is DateTime) {
      payload['expiry_date'] =
          Timestamp.fromDate(payload['expiry_date'] as DateTime);
    }
    payload['created_at'] = FieldValue.serverTimestamp();
    await _firestore.collection('promo_codes').doc(code).set(payload);
  }

  /// Update a promo code.
  ///
  /// Converts any [DateTime] value for `expiry_date` to a Firestore
  /// [Timestamp] before writing.
  static Future<void> updatePromoCode(
    String code,
    Map<String, dynamic> data,
  ) async {
    final payload = Map<String, dynamic>.from(data);
    if (payload['expiry_date'] is DateTime) {
      payload['expiry_date'] =
          Timestamp.fromDate(payload['expiry_date'] as DateTime);
    }
    await _firestore.collection('promo_codes').doc(code).update(payload);
  }

  // ==================== Document Streaming ====================

  /// Stream pending documents.
  static Stream<List<Map<String, dynamic>>> streamPendingDocuments() {
    return _firestore
        .collection('documents')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((d) => {'id': d.id, ...d.data()})
              .toList(),
        );
  }
}
