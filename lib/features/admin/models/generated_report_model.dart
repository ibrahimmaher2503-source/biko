import 'package:cloud_firestore/cloud_firestore.dart';

class GeneratedReportModel {
  const GeneratedReportModel({
    required this.id,
    required this.type,
    required this.createdAt,
    this.title = '',
    this.status = 'completed',
    this.fileUrl,
    this.generatedBy = '',
    this.dateFrom,
    this.dateTo,
  });

  factory GeneratedReportModel.fromMap(Map<String, dynamic> map) {
    return GeneratedReportModel(
      id: map['id'] as String? ?? '',
      type: map['type'] as String? ?? '',
      title: map['title'] as String? ?? '',
      status: map['status'] as String? ?? 'completed',
      fileUrl: map['file_url'] as String?,
      generatedBy: map['generated_by'] as String? ?? '',
      dateFrom: map['date_from'] is Timestamp
          ? (map['date_from'] as Timestamp).toDate()
          : null,
      dateTo: map['date_to'] is Timestamp
          ? (map['date_to'] as Timestamp).toDate()
          : null,
      createdAt: map['created_at'] is Timestamp
          ? (map['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  final String id;
  final String type;
  final String title;
  final String status;
  final String? fileUrl;
  final String generatedBy;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'status': status,
      'file_url': fileUrl,
      'generated_by': generatedBy,
      'date_from':
          dateFrom != null ? Timestamp.fromDate(dateFrom!) : null,
      'date_to': dateTo != null ? Timestamp.fromDate(dateTo!) : null,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  GeneratedReportModel copyWith({
    String? id,
    String? type,
    String? title,
    String? status,
    String? fileUrl,
    String? generatedBy,
    DateTime? dateFrom,
    DateTime? dateTo,
    DateTime? createdAt,
  }) {
    return GeneratedReportModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      status: status ?? this.status,
      fileUrl: fileUrl ?? this.fileUrl,
      generatedBy: generatedBy ?? this.generatedBy,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
