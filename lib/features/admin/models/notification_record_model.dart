import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationRecordModel {
  NotificationRecordModel({
    required this.id,
    required this.targetSegment,
    required this.titleAr,
    required this.titleEn,
    required this.bodyAr,
    required this.bodyEn,
    required this.senderUid,
    required this.senderName,
    required this.sentAt,
  });

  factory NotificationRecordModel.fromMap(
    Map<String, dynamic> map, [
    String? docId,
  ]) {
    return NotificationRecordModel(
      id: docId ?? map['id'] as String? ?? '',
      targetSegment: map['target_segment'] as String? ?? '',
      titleAr: map['title_ar'] as String? ?? '',
      titleEn: map['title_en'] as String? ?? '',
      bodyAr: map['body_ar'] as String? ?? '',
      bodyEn: map['body_en'] as String? ?? '',
      senderUid: map['sender_uid'] as String? ?? '',
      senderName: map['sender_name'] as String? ?? '',
      sentAt: (map['sent_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Backward-compatible alias for [fromMap].
  factory NotificationRecordModel.fromJson(
    Map<String, dynamic> json,
    String id,
  ) => NotificationRecordModel.fromMap(json, id);

  final String id;
  final String targetSegment;
  final String titleAr;
  final String titleEn;
  final String bodyAr;
  final String bodyEn;
  final String senderUid;
  final String senderName;
  final DateTime sentAt;

  Map<String, dynamic> toMap() {
    return {
      'target_segment': targetSegment,
      'title_ar': titleAr,
      'title_en': titleEn,
      'body_ar': bodyAr,
      'body_en': bodyEn,
      'sender_uid': senderUid,
      'sender_name': senderName,
      'sent_at': Timestamp.fromDate(sentAt),
    };
  }

  /// Backward-compatible alias for [toMap].
  Map<String, dynamic> toJson() => toMap();

  NotificationRecordModel copyWith({
    String? id,
    String? targetSegment,
    String? titleAr,
    String? titleEn,
    String? bodyAr,
    String? bodyEn,
    String? senderUid,
    String? senderName,
    DateTime? sentAt,
  }) {
    return NotificationRecordModel(
      id: id ?? this.id,
      targetSegment: targetSegment ?? this.targetSegment,
      titleAr: titleAr ?? this.titleAr,
      titleEn: titleEn ?? this.titleEn,
      bodyAr: bodyAr ?? this.bodyAr,
      bodyEn: bodyEn ?? this.bodyEn,
      senderUid: senderUid ?? this.senderUid,
      senderName: senderName ?? this.senderName,
      sentAt: sentAt ?? this.sentAt,
    );
  }
}
