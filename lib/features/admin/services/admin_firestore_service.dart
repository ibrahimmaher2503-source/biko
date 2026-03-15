import 'package:biko/core/models/document_model.dart';
import 'package:biko/core/models/enums.dart';
import 'package:biko/core/models/trip_model.dart';
import 'package:biko/core/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
}
