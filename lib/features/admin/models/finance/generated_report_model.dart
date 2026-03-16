import 'package:cloud_firestore/cloud_firestore.dart';

class GeneratedReportModel {
  const GeneratedReportModel({
    required this.id,
    required this.name,
    required this.type,
    required this.downloadUrl,
    required this.generatedAt,
    required this.generatedBy,
  });

  factory GeneratedReportModel.fromJson(Map<String, dynamic> json) {
    return GeneratedReportModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      downloadUrl: json['download_url'] as String? ?? '',
      generatedAt: _parseDate(json['generated_at']),
      generatedBy: json['generated_by'] as String? ?? '',
    );
  }

  final String id;
  final String name;
  final String type;
  final String downloadUrl;
  final DateTime generatedAt;
  final String generatedBy;

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'download_url': downloadUrl,
      'generated_at': Timestamp.fromDate(generatedAt),
      'generated_by': generatedBy,
    };
  }

  GeneratedReportModel copyWith({
    String? id,
    String? name,
    String? type,
    String? downloadUrl,
    DateTime? generatedAt,
    String? generatedBy,
  }) {
    return GeneratedReportModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      generatedAt: generatedAt ?? this.generatedAt,
      generatedBy: generatedBy ?? this.generatedBy,
    );
  }
}
