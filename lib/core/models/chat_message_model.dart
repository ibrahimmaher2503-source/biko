import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for in-trip chat messages
class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.tripId,
    required this.senderUid,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      id: map['id'] as String? ?? '',
      tripId: map['trip_id'] as String? ?? '',
      senderUid: map['sender_uid'] as String? ?? '',
      message: map['message'] as String? ?? '',
      isRead: map['is_read'] as bool? ?? false,
      createdAt: map['created_at'] is Timestamp
          ? (map['created_at'] as Timestamp).toDate()
          : map['created_at'] is int
              ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
              : DateTime.now(),
    );
  }

  final String id;
  final String tripId;
  final String senderUid;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'sender_uid': senderUid,
      'message': message,
      'is_read': isRead,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  ChatMessageModel copyWith({
    String? id,
    String? tripId,
    String? senderUid,
    String? message,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      senderUid: senderUid ?? this.senderUid,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
