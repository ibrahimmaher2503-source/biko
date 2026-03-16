import 'package:biko/core/models/enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentModel {
  const DocumentModel({
    required this.id,
    required this.driverUid,
    required this.type,
    required this.fileUrl,
    required this.createdAt,
    this.status = DocumentStatus.pending,
    this.adminNote,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String? ?? '',
      driverUid: json['driver_uid'] as String? ?? '',
      type: DocumentType.fromJson(json['type'] as String? ?? 'national_id'),
      fileUrl: json['file_url'] as String? ?? '',
      status: DocumentStatus.fromJson(json['status'] as String? ?? 'pending'),
      adminNote: json['admin_note'] as String?,
      createdAt: json['created_at'] is Timestamp
          ? (json['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  final String id;
  final String driverUid;
  final DocumentType type;
  final String fileUrl;
  final DocumentStatus status;
  final String? adminNote;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_uid': driverUid,
      'type': type.toJson(),
      'file_url': fileUrl,
      'status': status.toJson(),
      'admin_note': adminNote,
      'created_at': FieldValue.serverTimestamp(),
    };
  }

  DocumentModel copyWith({
    String? id,
    String? driverUid,
    DocumentType? type,
    String? fileUrl,
    DocumentStatus? status,
    String? adminNote,
    DateTime? createdAt,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      driverUid: driverUid ?? this.driverUid,
      type: type ?? this.type,
      fileUrl: fileUrl ?? this.fileUrl,
      status: status ?? this.status,
      adminNote: adminNote ?? this.adminNote,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
