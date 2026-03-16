class DashboardStatsModel {
  DashboardStatsModel({
    this.tripsToday = 0,
    this.revenueToday = 0.0,
    this.driversOnline = 0,
    this.pendingReviews = 0,
    this.totalCustomers = 0,
    this.totalDrivers = 0,
    this.weeklyTrips = 0,
    this.weeklyRevenue = 0.0,
    this.cancellationRate = 0.0,
  });

  factory DashboardStatsModel.fromMap(Map<String, dynamic> map) {
    return DashboardStatsModel(
      tripsToday: (map['tripsToday'] as num?)?.toInt() ?? 0,
      revenueToday: (map['revenueToday'] as num?)?.toDouble() ?? 0.0,
      driversOnline: (map['driversOnline'] as num?)?.toInt() ?? 0,
      pendingReviews: (map['pendingReviews'] as num?)?.toInt() ?? 0,
      totalCustomers: (map['totalCustomers'] as num?)?.toInt() ?? 0,
      totalDrivers: (map['totalDrivers'] as num?)?.toInt() ?? 0,
      weeklyTrips: (map['weeklyTrips'] as num?)?.toInt() ?? 0,
      weeklyRevenue: (map['weeklyRevenue'] as num?)?.toDouble() ?? 0.0,
      cancellationRate: (map['cancellationRate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final int tripsToday;
  final double revenueToday;
  final int driversOnline;
  final int pendingReviews;
  final int totalCustomers;
  final int totalDrivers;
  final int weeklyTrips;
  final double weeklyRevenue;
  final double cancellationRate;

  Map<String, dynamic> toMap() {
    return {
      'tripsToday': tripsToday,
      'revenueToday': revenueToday,
      'driversOnline': driversOnline,
      'pendingReviews': pendingReviews,
      'totalCustomers': totalCustomers,
      'totalDrivers': totalDrivers,
      'weeklyTrips': weeklyTrips,
      'weeklyRevenue': weeklyRevenue,
      'cancellationRate': cancellationRate,
    };
  }

  DashboardStatsModel copyWith({
    int? tripsToday,
    double? revenueToday,
    int? driversOnline,
    int? pendingReviews,
    int? totalCustomers,
    int? totalDrivers,
    int? weeklyTrips,
    double? weeklyRevenue,
    double? cancellationRate,
  }) {
    return DashboardStatsModel(
      tripsToday: tripsToday ?? this.tripsToday,
      revenueToday: revenueToday ?? this.revenueToday,
      driversOnline: driversOnline ?? this.driversOnline,
      pendingReviews: pendingReviews ?? this.pendingReviews,
      totalCustomers: totalCustomers ?? this.totalCustomers,
      totalDrivers: totalDrivers ?? this.totalDrivers,
      weeklyTrips: weeklyTrips ?? this.weeklyTrips,
      weeklyRevenue: weeklyRevenue ?? this.weeklyRevenue,
      cancellationRate: cancellationRate ?? this.cancellationRate,
    );
  }
}
