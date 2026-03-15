import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduledReportModel {
  const ScheduledReportModel({
    required this.id,
    required this.type,
    required this.frequency,
    this.title = '',
    this.isActive = true,
    this.recipients = const [],
    this.lastRunAt,
    this.nextRunAt,
    this.createdBy = '',
  });

  factory ScheduledReportModel.fromMap(Map<String, dynamic> map) {
    return ScheduledReportModel(
      id: map['id'] as String? ?? '',
      type: map['type'] as String? ?? '',
      frequency: map['frequency'] as String? ?? 'daily',
      title: map['title'] as String? ?? '',
      isActive: map['is_active'] as bool? ?? true,
      recipients: (map['recipients'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      lastRunAt: map['last_run_at'] is Timestamp
          ? (map['last_run_at'] as Timestamp).toDate()
          : null,
      nextRunAt: map['next_run_at'] is Timestamp
          ? (map['next_run_at'] as Timestamp).toDate()
          : null,
      createdBy: map['created_by'] as String? ?? '',
    );
  }

  final String id;
  final String type;
  final String frequency;
  final String title;
  final bool isActive;
  final List<String> recipients;
  final DateTime? lastRunAt;
  final DateTime? nextRunAt;
  final String createdBy;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'frequency': frequency,
      'title': title,
      'is_active': isActive,
      'recipients': recipients,
      'last_run_at':
          lastRunAt != null ? Timestamp.fromDate(lastRunAt!) : null,
      'next_run_at':
          nextRunAt != null ? Timestamp.fromDate(nextRunAt!) : null,
      'created_by': createdBy,
    };
  }

  ScheduledReportModel copyWith({
    String? id,
    String? type,
    String? frequency,
    String? title,
    bool? isActive,
    List<String>? recipients,
    DateTime? lastRunAt,
    DateTime? nextRunAt,
    String? createdBy,
  }) {
    return ScheduledReportModel(
      id: id ?? this.id,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      title: title ?? this.title,
      isActive: isActive ?? this.isActive,
      recipients: recipients ?? this.recipients,
      lastRunAt: lastRunAt ?? this.lastRunAt,
      nextRunAt: nextRunAt ?? this.nextRunAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
