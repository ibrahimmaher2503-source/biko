class ScheduledReportModel {
  const ScheduledReportModel({
    required this.id,
    required this.reportType,
    required this.frequency,
    this.emailRecipients = const [],
    this.isActive = true,
  });

  factory ScheduledReportModel.fromJson(Map<String, dynamic> json) {
    return ScheduledReportModel(
      id: json['id'] as String? ?? '',
      reportType: json['report_type'] as String? ?? '',
      frequency: json['frequency'] as String? ?? '',
      emailRecipients:
          (json['email_recipients'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  final String id;
  final String reportType;
  final String frequency;
  final List<String> emailRecipients;
  final bool isActive;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'report_type': reportType,
      'frequency': frequency,
      'email_recipients': emailRecipients,
      'is_active': isActive,
    };
  }

  ScheduledReportModel copyWith({
    String? id,
    String? reportType,
    String? frequency,
    List<String>? emailRecipients,
    bool? isActive,
  }) {
    return ScheduledReportModel(
      id: id ?? this.id,
      reportType: reportType ?? this.reportType,
      frequency: frequency ?? this.frequency,
      emailRecipients: emailRecipients ?? this.emailRecipients,
      isActive: isActive ?? this.isActive,
    );
  }
}
