class ApprovalStatsModel {
  const ApprovalStatsModel({
    this.pendingCount = 0,
    this.approvedTodayCount = 0,
    this.rejectedTodayCount = 0,
    this.avgApprovalTimeHours = 0.0,
  });

  factory ApprovalStatsModel.fromJson(Map<String, dynamic> json) {
    return ApprovalStatsModel(
      pendingCount: (json['pending_count'] as num?)?.toInt() ?? 0,
      approvedTodayCount:
          (json['approved_today_count'] as num?)?.toInt() ?? 0,
      rejectedTodayCount:
          (json['rejected_today_count'] as num?)?.toInt() ?? 0,
      avgApprovalTimeHours:
          (json['avg_approval_time_hours'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final int pendingCount;
  final int approvedTodayCount;
  final int rejectedTodayCount;
  final double avgApprovalTimeHours;

  Map<String, dynamic> toJson() {
    return {
      'pending_count': pendingCount,
      'approved_today_count': approvedTodayCount,
      'rejected_today_count': rejectedTodayCount,
      'avg_approval_time_hours': avgApprovalTimeHours,
    };
  }

  ApprovalStatsModel copyWith({
    int? pendingCount,
    int? approvedTodayCount,
    int? rejectedTodayCount,
    double? avgApprovalTimeHours,
  }) {
    return ApprovalStatsModel(
      pendingCount: pendingCount ?? this.pendingCount,
      approvedTodayCount: approvedTodayCount ?? this.approvedTodayCount,
      rejectedTodayCount: rejectedTodayCount ?? this.rejectedTodayCount,
      avgApprovalTimeHours:
          avgApprovalTimeHours ?? this.avgApprovalTimeHours,
    );
  }
}
