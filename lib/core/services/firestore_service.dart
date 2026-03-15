import 'dart:math' show atan2, cos, pi, sin, sqrt;

import 'package:biko/core/models/bid_model.dart';
import 'package:biko/core/models/document_model.dart';
import 'package:biko/core/models/driver_brief_model.dart';
import 'package:biko/core/models/driver_location_model.dart';
import 'package:biko/core/models/driver_profile_model.dart';
import 'package:biko/core/models/enums.dart';
import 'package:biko/core/models/notification_model.dart';
import 'package:biko/core/models/promo_code_model.dart';
import 'package:biko/core/models/rating_model.dart';
import 'package:biko/core/models/referral_model.dart';
import 'package:biko/core/models/transaction_model.dart';
import 'package:biko/core/models/trip_model.dart';
import 'package:biko/core/models/trip_summary_model.dart';
import 'package:biko/core/models/user_model.dart';
import 'package:biko/core/models/wallet_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Firestore data operations service
///
/// Static class following the same pattern as [AuthService].
/// All Firestore and Realtime Database operations go through this service.
/// Controllers MUST use this service — never import Firebase directly.
class FirestoreService {
  FirestoreService._();

  static final _firestore = FirebaseFirestore.instance;
  static final _realtimeDb = FirebaseDatabase.instance.ref();

  // ==================== Users ====================

  /// Get a user document by UID
  static Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromJson({...doc.data()!, 'uid': doc.id});
    } catch (e) {
      debugPrint('❌ FirestoreService.getUser failed: $e');
      return null;
    }
  }

  /// Create a new user document
  static Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toJson());
    } catch (e) {
      debugPrint('❌ FirestoreService.createUser failed: $e');
      rethrow;
    }
  }

  /// Update specific fields on a user document
  static Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      debugPrint('❌ FirestoreService.updateUser failed: $e');
      rethrow;
    }
  }

  /// Listen to user document changes in real-time
  static Stream<UserModel?> listenToUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromJson({...doc.data()!, 'uid': doc.id});
    });
  }

  // ==================== App Config ====================

  /// Get the app_config document
  static Future<Map<String, dynamic>?> getAppConfig() async {
    try {
      final doc = await _firestore.collection('app_config').doc('config').get();
      if (!doc.exists || doc.data() == null) return null;
      return doc.data();
    } catch (e) {
      debugPrint('❌ FirestoreService.getAppConfig failed: $e');
      return null;
    }
  }

  // ==================== Driver Profiles ====================

  /// Create a driver profile document
  static Future<void> createDriverProfile(DriverProfileModel profile) async {
    try {
      await _firestore
          .collection('driver_profiles')
          .doc(profile.uid)
          .set(profile.toJson());
    } catch (e) {
      debugPrint('❌ FirestoreService.createDriverProfile failed: $e');
      rethrow;
    }
  }

  // ==================== Documents ====================

  /// Create a driver document record
  static Future<void> createDocument(DocumentModel document) async {
    try {
      final ref = _firestore.collection('documents').doc();
      await ref.set({...document.toJson(), 'id': ref.id});
    } catch (e) {
      debugPrint('❌ FirestoreService.createDocument failed: $e');
      rethrow;
    }
  }

  // ==================== Trips ====================

  /// Listen to active trip data in real-time
  static Stream<Map<String, dynamic>> listenToActiveTrip(String tripId) {
    return _firestore.collection('trips').doc(tripId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return <String, dynamic>{};
      return doc.data()!;
    });
  }

  /// Create a new trip and return its document ID.
  static Future<String> createTrip(TripModel trip) async {
    try {
      final ref = _firestore.collection('trips').doc();
      await ref.set({...trip.toMap(), 'id': ref.id});
      return ref.id;
    } catch (e) {
      debugPrint('❌ FirestoreService.createTrip failed: $e');
      rethrow;
    }
  }

  /// Cancel a trip
  static Future<void> cancelTrip(String tripId, String reason) async {
    try {
      await _firestore.collection('trips').doc(tripId).update({
        'status': 'cancelled',
        'cancel_reason': reason,
        'cancelled_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ FirestoreService.cancelTrip failed: $e');
      rethrow;
    }
  }

  /// Cancel trip search (customer-initiated before any bids accepted)
  static Future<void> cancelTripSearch(String tripId) async {
    try {
      await _firestore.collection('trips').doc(tripId).update({
        'status': 'cancelled',
        'cancelled_at': FieldValue.serverTimestamp(),
      });
      // Clean up live bids from Realtime DB
      await _realtimeDb.child('live_bids/$tripId').remove();
    } catch (e) {
      debugPrint('❌ FirestoreService.cancelTripSearch failed: $e');
      rethrow;
    }
  }

  // ==================== Bids ====================

  /// Listen to live bids for a trip from Realtime Database.
  ///
  /// Returns a stream of [BidModel] list sorted by amount ASC.
  static Stream<List<BidModel>> listenToLiveBids(String tripId) {
    return _realtimeDb.child('live_bids/$tripId').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return <BidModel>[];

      final map = Map<String, dynamic>.from(data as Map);
      final bidsList = map.entries.map((entry) {
        final bidData = Map<String, dynamic>.from(entry.value as Map);
        bidData['bid_id'] = entry.key;
        bidData['trip_id'] = tripId;
        return BidModel.fromMap(bidData);
      }).toList();

      // Sort by amount ascending (cheapest first)
      bidsList.sort((a, b) => a.amount.compareTo(b.amount));
      return bidsList;
    });
  }

  /// Accept a bid — update Firestore trip + clean up Realtime DB bids.
  static Future<void> acceptBid({
    required String tripId,
    required String bidId,
    required double finalPrice,
    required String driverUid,
  }) async {
    try {
      final batch = _firestore.batch();

      // Update trip status
      final tripRef = _firestore.collection('trips').doc(tripId);
      batch.update(tripRef, {
        'status': 'accepted',
        'driver_uid': driverUid,
        'accepted_price': finalPrice,
        'accepted_at': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // Clean up live bids in Realtime DB
      await _realtimeDb.child('live_bids/$tripId').remove();
    } catch (e) {
      debugPrint('❌ FirestoreService.acceptBid failed: $e');
      rethrow;
    }
  }

  /// Reject a specific bid in Realtime DB.
  static Future<void> rejectBid(String tripId, String bidId) async {
    try {
      await _realtimeDb.child('live_bids/$tripId/$bidId').update({
        'status': 'rejected',
      });
    } catch (e) {
      debugPrint('❌ FirestoreService.rejectBid failed: $e');
      rethrow;
    }
  }

  // ==================== Trip History ====================

  /// Get paginated trip history for a customer.
  ///
  /// Returns completed and cancelled trips ordered by creation date (newest first).
  /// Use [lastDoc] for pagination.
  static Future<List<TripModel>> getTripHistory(
    String uid, {
    int limit = 20,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      var query = _firestore
          .collection('trips')
          .where('customer_uid', isEqualTo: uid)
          .where('status', whereIn: ['completed', 'cancelled'])
          .orderBy('created_at', descending: true)
          .limit(limit);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return TripModel.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('❌ FirestoreService.getTripHistory failed: $e');
      rethrow;
    }
  }

  /// Get the last document snapshot for pagination
  static Future<DocumentSnapshot?> getTripHistoryLastDoc(
    String uid, {
    int limit = 20,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      var query = _firestore
          .collection('trips')
          .where('customer_uid', isEqualTo: uid)
          .where('status', whereIn: ['completed', 'cancelled'])
          .orderBy('created_at', descending: true)
          .limit(limit);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) return null;
      return snapshot.docs.last;
    } catch (e) {
      debugPrint('❌ FirestoreService.getTripHistoryLastDoc failed: $e');
      return null;
    }
  }

  // ==================== Trip Completion & Ratings ====================

  /// Get trip summary for a completed trip.
  ///
  /// Fetches the trip document and the driver profile to build a
  /// [TripSummaryModel] for the trip completion screen.
  static Future<TripSummaryModel?> getTripSummary(String tripId) async {
    try {
      final tripDoc = await _firestore.collection('trips').doc(tripId).get();
      if (!tripDoc.exists || tripDoc.data() == null) return null;

      final tripData = tripDoc.data()!;
      final trip = TripModel.fromMap({...tripData, 'id': tripDoc.id});

      // Fetch driver brief
      DriverBriefModel? driver;
      if (trip.driverUid != null) {
        final driverDoc = await _firestore
            .collection('driver_profiles')
            .doc(trip.driverUid)
            .get();
        if (driverDoc.exists && driverDoc.data() != null) {
          driver = DriverBriefModel.fromMap({
            ...driverDoc.data()!,
            'uid': driverDoc.id,
          });
        }
      }

      // Build summary from trip data using app_config pricing
      final totalFare = trip.acceptedPrice ?? trip.customerPrice;
      final config = await getAppConfig();
      final baseFare =
          (config?['base_fare'] as num?)?.toDouble() ?? 0;
      final pricePerKm =
          (config?['price_per_km'] as num?)?.toDouble() ?? 0;
      final pricePerMin =
          (config?['price_per_min'] as num?)?.toDouble() ?? 0;
      final distanceKm = trip.distanceKm ?? 0.0;
      final durationMin = trip.durationMinutes ?? 0;

      // Calculate real fare components from config
      final calculatedDistanceFare = pricePerKm * distanceKm;
      final calculatedTimeFare = pricePerMin * durationMin;

      return TripSummaryModel(
        tripId: trip.id,
        pickupAddress: trip.pickup.address,
        dropoffAddress: trip.dropoff.address,
        distanceKm: distanceKm,
        durationMinutes: durationMin,
        baseFare: baseFare,
        distanceFare: calculatedDistanceFare,
        timeFare: calculatedTimeFare,
        totalFare: totalFare,
        paymentMethod: trip.paymentMethod.toJson(),
        driver:
            driver ??
            const DriverBriefModel(
              uid: '',
              name: '',
              vehicleType: VehicleType.motorcycle,
              rating: 0,
            ),
      );
    } catch (e) {
      debugPrint('❌ FirestoreService.getTripSummary failed: $e');
      return null;
    }
  }

  /// Submit a rating for a trip.
  ///
  /// Creates a rating document and updates the driver's average rating.
  static Future<void> submitRating(RatingModel rating) async {
    try {
      final batch = _firestore.batch();

      // Create rating document
      final ratingRef = _firestore.collection('ratings').doc();
      batch.set(ratingRef, {...rating.toMap(), 'rating_id': ratingRef.id});

      // Update trip with rating reference
      final tripRef = _firestore.collection('trips').doc(rating.tripId);
      batch.update(tripRef, {'rating_id': ratingRef.id});

      await batch.commit();
    } catch (e) {
      debugPrint('❌ FirestoreService.submitRating failed: $e');
      rethrow;
    }
  }

  /// Tip the driver for a completed trip.
  ///
  /// Records the tip amount on the trip document. Actual wallet
  /// operations are handled by Cloud Functions.
  static Future<void> tipDriver(String tripId, double amount) async {
    try {
      await _firestore.collection('trips').doc(tripId).update({
        'tip_amount': amount,
        'tipped_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ FirestoreService.tipDriver failed: $e');
      rethrow;
    }
  }

  /// Get a driver brief by UID.
  static Future<DriverBriefModel?> getDriverBrief(String driverUid) async {
    try {
      final doc = await _firestore
          .collection('driver_profiles')
          .doc(driverUid)
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return DriverBriefModel.fromMap({...doc.data()!, 'uid': doc.id});
    } catch (e) {
      debugPrint('❌ FirestoreService.getDriverBrief failed: $e');
      return null;
    }
  }

  // ==================== Wallet ====================

  /// Listen to wallet balance in real-time
  static Stream<WalletModel?> listenToWallet(String uid) {
    return _firestore.collection('wallets').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return WalletModel.fromMap({...doc.data()!, 'uid': doc.id});
    });
  }

  /// Get paginated transaction history
  static Future<List<TransactionModel>> getTransactions(
    String uid, {
    int limit = 20,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      var query = _firestore
          .collection('transactions')
          .where('uid', isEqualTo: uid)
          .orderBy('created_at', descending: true)
          .limit(limit);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map(
            (doc) =>
                TransactionModel.fromMap({...doc.data(), 'txn_id': doc.id}),
          )
          .toList();
    } catch (e) {
      debugPrint('❌ FirestoreService.getTransactions failed: $e');
      return [];
    }
  }

  /// Get the last document snapshot for transaction pagination cursor.
  static Future<DocumentSnapshot?> getTransactionsLastDoc(
    String uid, {
    int limit = 20,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      var query = _firestore
          .collection('transactions')
          .where('uid', isEqualTo: uid)
          .orderBy('created_at', descending: true)
          .limit(limit);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) return null;
      return snapshot.docs.last;
    } catch (e) {
      debugPrint('❌ FirestoreService.getTransactionsLastDoc failed: $e');
      return null;
    }
  }

  /// Initiate a wallet top-up via Cloud Function.
  ///
  /// Returns the Paymob payment URL to load in a WebView.
  /// Note: The actual Cloud Function must be deployed separately.
  static Future<String?> initiateTopUp(
    double amount,
    String method,
    String uid,
  ) async {
    try {
      // Call Cloud Function to create Paymob order
      // This is a placeholder — the actual function must exist in Firebase
      final doc = await _firestore.collection('payment_requests').add({
        'uid': uid,
        'amount': amount,
        'method': method,
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
      });

      // In production, a Cloud Function trigger would create the Paymob
      // order and update this document with the payment URL.
      // For now, return the request ID for tracking.
      return doc.id;
    } catch (e) {
      debugPrint('❌ FirestoreService.initiateTopUp failed: $e');
      return null;
    }
  }

  /// Listen to a specific transaction for payment status updates
  static Stream<TransactionModel?> listenToTransaction(String txnId) {
    return _firestore.collection('transactions').doc(txnId).snapshots().map((
      doc,
    ) {
      if (!doc.exists || doc.data() == null) return null;
      return TransactionModel.fromMap({...doc.data()!, 'txn_id': doc.id});
    });
  }

  // ==================== Nearby Drivers ====================

  /// Stream nearby online drivers from Realtime DB.
  ///
  /// Filters by [radiusKm] (default 5 km) from [center] using
  /// Haversine formula. Returns max 50 results.
  static Stream<List<DriverLocationModel>> getNearbyDrivers(
    LatLng center, {
    double radiusKm = 5.0,
  }) {
    return _realtimeDb.child('driver_locations').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return <DriverLocationModel>[];

      final map = Map<String, dynamic>.from(data as Map);
      final drivers = <DriverLocationModel>[];

      for (final entry in map.entries) {
        final driverData = Map<String, dynamic>.from(entry.value as Map);

        // Only online drivers
        if (driverData['is_online'] != true) continue;

        final driver = DriverLocationModel.fromMap(entry.key, driverData);

        // Filter by distance
        final distance = _haversineDistance(
          center.latitude,
          center.longitude,
          driver.lat,
          driver.lng,
        );
        if (distance <= radiusKm) {
          drivers.add(driver);
        }

        // Max 50
        if (drivers.length >= 50) break;
      }

      return drivers;
    });
  }

  /// Haversine distance in km between two lat/lng pairs.
  static double _haversineDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;

  // ==================== Driver Stats ====================

  /// Get driver's trip count and total earnings for today.
  ///
  /// Queries transactions/ where driverUid == uid and created_at >= today start.
  /// Returns map with 'tripCount' and 'totalEarned'.
  static Future<Map<String, dynamic>> getDriverTodayStats(String uid) async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      final snapshot = await _firestore
          .collection('transactions')
          .where('uid', isEqualTo: uid)
          .where('type', isEqualTo: 'credit')
          .where(
            'created_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart),
          )
          .get();

      var totalEarned = 0.0;
      for (final doc in snapshot.docs) {
        final amount = (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
        totalEarned += amount;
      }

      return {'tripCount': snapshot.docs.length, 'totalEarned': totalEarned};
    } catch (e) {
      debugPrint('❌ FirestoreService.getDriverTodayStats failed: $e');
      return {'tripCount': 0, 'totalEarned': 0.0};
    }
  }

  /// Get driver's total earnings for the current week (Monday to now).
  static Future<double> getDriverWeeklyEarnings(String uid) async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartDate = DateTime(
        weekStart.year,
        weekStart.month,
        weekStart.day,
      );

      final snapshot = await _firestore
          .collection('transactions')
          .where('uid', isEqualTo: uid)
          .where('type', isEqualTo: 'credit')
          .where(
            'created_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(weekStartDate),
          )
          .get();

      var total = 0.0;
      for (final doc in snapshot.docs) {
        final amount = (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
        total += amount;
      }

      return total;
    } catch (e) {
      debugPrint('❌ FirestoreService.getDriverWeeklyEarnings failed: $e');
      return 0.0;
    }
  }

  /// Get driver profile data from driver_profiles collection.
  static Future<DriverProfileModel?> getDriverProfile(String uid) async {
    try {
      final doc = await _firestore.collection('driver_profiles').doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return DriverProfileModel.fromJson({...doc.data()!, 'uid': doc.id});
    } catch (e) {
      debugPrint('❌ FirestoreService.getDriverProfile failed: $e');
      return null;
    }
  }

  /// Get a single trip by ID.
  static Future<TripModel?> getTrip(String tripId) async {
    try {
      final doc = await _firestore.collection('trips').doc(tripId).get();
      if (!doc.exists || doc.data() == null) return null;
      return TripModel.fromMap({...doc.data()!, 'id': doc.id});
    } catch (e) {
      debugPrint('❌ FirestoreService.getTrip failed: $e');
      return null;
    }
  }

  /// Update trip status in both Firestore and Realtime DB.
  static Future<void> updateTripStatus(
    String tripId,
    String status, {
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final data = <String, dynamic>{
        'status': status,
        'updated_at': FieldValue.serverTimestamp(),
        ...?extraData,
      };
      await _firestore.collection('trips').doc(tripId).update(data);

      // Also update Realtime DB for live tracking
      await _realtimeDb.child('active_trips/$tripId').update({
        'status': status,
        'updated_at': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('❌ FirestoreService.updateTripStatus failed: $e');
      rethrow;
    }
  }

  /// Submit a driver bid to Realtime DB.
  static Future<String> submitDriverBid(
    String tripId,
    Map<String, dynamic> bidData,
  ) async {
    try {
      final ref = _realtimeDb.child('live_bids/$tripId').push();
      await ref.set({
        ...bidData,
        'bid_id': ref.key,
        'created_at': ServerValue.timestamp,
      });
      return ref.key!;
    } catch (e) {
      debugPrint('❌ FirestoreService.submitDriverBid failed: $e');
      rethrow;
    }
  }

  /// Listen to a specific bid's status changes in Realtime DB.
  static Stream<Map<String, dynamic>> listenToBidStatus(
    String tripId,
    String bidId,
  ) {
    return _realtimeDb.child('live_bids/$tripId/$bidId').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return <String, dynamic>{};
      return Map<String, dynamic>.from(data as Map);
    });
  }

  /// Listen to nearby trip requests from Realtime DB.
  ///
  /// Streams all pending trips from `/trip_requests/` node.
  /// Filtering by vehicle type and distance is done client-side.
  static Stream<List<Map<String, dynamic>>> listenToTripRequests() {
    return _realtimeDb.child('trip_requests').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return <Map<String, dynamic>>[];

      final map = Map<String, dynamic>.from(data as Map);
      return map.entries.map((entry) {
        final tripData = Map<String, dynamic>.from(entry.value as Map);
        tripData['trip_id'] = entry.key;
        return tripData;
      }).toList();
    });
  }

  /// Write driver location to active trip in RTDB for customer tracking.
  static Future<void> updateActiveTripDriverLocation(
    String tripId,
    Map<String, dynamic> locationData,
  ) async {
    try {
      await _realtimeDb.child('active_trips/$tripId').update({
        ...locationData,
        'updated_at': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint(
        '❌ FirestoreService.updateActiveTripDriverLocation failed: $e',
      );
    }
  }

  // ==================== Chat ====================

  /// Listen to chat messages for a trip from Realtime DB.
  static Stream<List<Map<String, dynamic>>> listenToChatMessages(
    String tripId,
  ) {
    return _realtimeDb
        .child('chats/$tripId/messages')
        .orderByChild('timestamp')
        .onValue
        .map((event) {
          final data = event.snapshot.value;
          if (data == null) return <Map<String, dynamic>>[];

          final map = Map<String, dynamic>.from(data as Map);
          final messages = map.entries.map((entry) {
            final msgData = Map<String, dynamic>.from(entry.value as Map);
            msgData['message_id'] = entry.key;
            return msgData;
          }).toList();

          // Sort by timestamp ascending
          messages.sort((a, b) {
            final aTime = (a['timestamp'] as num?)?.toInt() ?? 0;
            final bTime = (b['timestamp'] as num?)?.toInt() ?? 0;
            return aTime.compareTo(bTime);
          });

          return messages;
        });
  }

  /// Send a chat message to Realtime DB.
  static Future<void> sendChatMessage(
    String tripId,
    Map<String, dynamic> messageData,
  ) async {
    try {
      final ref = _realtimeDb.child('chats/$tripId/messages').push();
      await ref.set({
        ...messageData,
        'message_id': ref.key,
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('❌ FirestoreService.sendChatMessage failed: $e');
      rethrow;
    }
  }

  /// Mark chat messages as read for a user.
  static Future<void> markMessagesRead(String tripId, String uid) async {
    try {
      final snapshot = await _realtimeDb
          .child('chats/$tripId/messages')
          .orderByChild('is_read')
          .equalTo(false)
          .get();

      if (!snapshot.exists) return;

      final updates = <String, dynamic>{};
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      for (final entry in data.entries) {
        final msg = Map<String, dynamic>.from(entry.value as Map);
        if (msg['sender_uid'] != uid) {
          updates['chats/$tripId/messages/${entry.key}/is_read'] = true;
        }
      }

      if (updates.isNotEmpty) {
        await _realtimeDb.update(updates);
      }
    } catch (e) {
      debugPrint('❌ FirestoreService.markMessagesRead failed: $e');
    }
  }

  // ==================== Driver Ratings ====================

  /// Get paginated ratings for a driver.
  static Future<List<RatingModel>> getDriverRatings(
    String driverUid, {
    int limit = 20,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      var query = _firestore
          .collection('ratings')
          .where('ratee_uid', isEqualTo: driverUid)
          .orderBy('created_at', descending: true)
          .limit(limit);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        return RatingModel.fromMap({...doc.data(), 'rating_id': doc.id});
      }).toList();
    } catch (e) {
      debugPrint('❌ FirestoreService.getDriverRatings failed: $e');
      return [];
    }
  }

  /// Get driver's earnings for a specific date range.
  static Future<List<TransactionModel>> getDriverEarnings(
    String uid, {
    required DateTime from,
    required DateTime to,
    int limit = 100,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('uid', isEqualTo: uid)
          .where('type', isEqualTo: 'credit')
          .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
          .where('created_at', isLessThanOrEqualTo: Timestamp.fromDate(to))
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map(
            (doc) =>
                TransactionModel.fromMap({...doc.data(), 'txn_id': doc.id}),
          )
          .toList();
    } catch (e) {
      debugPrint('❌ FirestoreService.getDriverEarnings failed: $e');
      return [];
    }
  }

  // ==================== Notifications ====================

  /// Listen to notifications for a user (newest first, limited to 50).
  static Stream<List<NotificationModel>> listenToNotifications(String uid) {
    return _firestore
        .collection('notifications')
        .where('uid', isEqualTo: uid)
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return NotificationModel.fromMap({...doc.data(), 'id': doc.id});
          }).toList();
        });
  }

  /// Mark a single notification as read.
  static Future<void> markNotificationRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'is_read': true});
    } catch (e) {
      debugPrint('❌ FirestoreService.markNotificationRead failed: $e');
      rethrow;
    }
  }

  /// Mark all notifications as read for a user (batch write).
  static Future<void> markAllNotificationsRead(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('uid', isEqualTo: uid)
          .where('is_read', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'is_read': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('❌ FirestoreService.markAllNotificationsRead failed: $e');
      rethrow;
    }
  }

  // ==================== Promo Codes ====================

  /// Get a user's promo codes from Firestore.
  static Future<List<PromoCodeModel>> getUserPromoCodes(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('promo_codes')
          .where('uid', isEqualTo: uid)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return PromoCodeModel.fromMap({...doc.data(), 'id': doc.id});
      }).toList();
    } catch (e) {
      debugPrint('❌ FirestoreService.getUserPromoCodes failed: $e');
      return [];
    }
  }

  /// Validate and apply a promo code via Cloud Function.
  ///
  /// Returns the applied [PromoCodeModel] if valid, null otherwise.
  static Future<PromoCodeModel?> validatePromoCode(
    String code,
    String uid,
  ) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'validatePromoCode',
      );
      final result = await callable.call<dynamic>({
        'code': code,
        'uid': uid,
      });

      final data = result.data as Map<String, dynamic>?;
      if (data == null || data['success'] != true) return null;

      final promoData = data['promo'] as Map<String, dynamic>?;
      if (promoData == null) return null;

      return PromoCodeModel.fromMap(promoData);
    } catch (e) {
      debugPrint('❌ FirestoreService.validatePromoCode failed: $e');
      rethrow;
    }
  }

  // ==================== Referrals ====================

  /// Get referral data for a user.
  ///
  /// Returns a map with 'code', 'totalEarnings', and 'referrals' list.
  static Future<Map<String, dynamic>> getReferralData(String uid) async {
    try {
      // Get user's referral code from their profile
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final referralCode = userDoc.data()?['referral_code'] as String? ?? '';

      // Get referrals where this user is the referrer
      final snapshot = await _firestore
          .collection('referrals')
          .where('referrer_uid', isEqualTo: uid)
          .orderBy('created_at', descending: true)
          .get();

      final referrals = snapshot.docs.map((doc) {
        return ReferralModel.fromMap({...doc.data(), 'id': doc.id});
      }).toList();

      final totalEarnings = referrals
          .where((r) => r.isRewarded)
          .fold(0.0, (total, r) => total + r.rewardAmount);

      return {
        'code': referralCode,
        'totalEarnings': totalEarnings,
        'referrals': referrals,
      };
    } catch (e) {
      debugPrint('❌ FirestoreService.getReferralData failed: $e');
      return {'code': '', 'totalEarnings': 0.0, 'referrals': <ReferralModel>[]};
    }
  }

  // ==================== FCM Token ====================

  /// Update the user's FCM token in Firestore.
  static Future<void> updateFcmToken(String uid, String token) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'fcm_token': token,
        'fcm_updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ FirestoreService.updateFcmToken failed: $e');
    }
  }

  /// Clear the user's FCM token from Firestore (on sign out).
  static Future<void> clearFcmToken(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'fcm_token': FieldValue.delete(),
        'fcm_updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ FirestoreService.clearFcmToken failed: $e');
    }
  }

  // ==================== App Config (Pricing) ====================

  /// Get commission rate from app_config/pricing.
  static Future<double> getCommissionRate() async {
    try {
      final doc = await _firestore
          .collection('app_config')
          .doc('pricing')
          .get();
      if (doc.exists && doc.data() != null) {
        return (doc.data()!['commission_rate'] as num?)?.toDouble() ?? 0.15;
      }
      return 0.15;
    } catch (e) {
      debugPrint('❌ FirestoreService.getCommissionRate failed: $e');
      return 0.15;
    }
  }

  /// Call processCommission Cloud Function for a completed trip.
  static Future<void> callProcessCommission(String tripId) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'processCommission',
      );
      await callable.call<dynamic>({'tripId': tripId});
    } catch (e) {
      debugPrint('❌ FirestoreService.callProcessCommission failed: $e');
      rethrow;
    }
  }
}
