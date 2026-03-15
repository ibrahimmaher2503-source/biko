import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for driver/trip ratings
class RatingModel {
  const RatingModel({
    required this.ratingId,
    required this.tripId,
    required this.raterUid,
    required this.rateeUid,
    required this.score,
    required this.createdAt,
    this.comment,
    this.chips = const [],
  });

  factory RatingModel.fromMap(Map<String, dynamic> map) {
    return RatingModel(
      ratingId: map['rating_id'] as String? ?? '',
      tripId: map['trip_id'] as String? ?? '',
      raterUid: map['rater_uid'] as String? ?? '',
      rateeUid: map['ratee_uid'] as String? ?? '',
      score: (map['score'] as num?)?.toInt() ?? 3,
      comment: map['comment'] as String?,
      chips:
          (map['chips'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      createdAt: map['created_at'] is Timestamp
          ? (map['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  final String ratingId;
  final String tripId;
  final String raterUid;
  final String rateeUid;
  final int score;
  final String? comment;
  final List<String> chips;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'rating_id': ratingId,
      'trip_id': tripId,
      'rater_uid': raterUid,
      'ratee_uid': rateeUid,
      'score': score,
      'comment': comment,
      'chips': chips,
      'created_at': FieldValue.serverTimestamp(),
    };
  }

  RatingModel copyWith({
    String? ratingId,
    String? tripId,
    String? raterUid,
    String? rateeUid,
    int? score,
    String? comment,
    List<String>? chips,
    DateTime? createdAt,
  }) {
    return RatingModel(
      ratingId: ratingId ?? this.ratingId,
      tripId: tripId ?? this.tripId,
      raterUid: raterUid ?? this.raterUid,
      rateeUid: rateeUid ?? this.rateeUid,
      score: score ?? this.score,
      comment: comment ?? this.comment,
      chips: chips ?? this.chips,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'RatingModel(tripId: $tripId, score: $score, rater: $raterUid)';
}
