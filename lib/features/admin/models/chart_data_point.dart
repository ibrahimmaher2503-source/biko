/// Generic data point for time-series charts.
///
/// Used by revenue chart (30-day line), trip volume (stacked bar),
/// and cancellation trend (line).
class ChartDataPoint {
  const ChartDataPoint({
    required this.date,
    required this.value,
    this.label,
    this.extraData,
  });

  factory ChartDataPoint.fromMap(Map<String, dynamic> map) {
    return ChartDataPoint(
      date: map['date'] is DateTime
          ? map['date'] as DateTime
          : DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      value: (map['value'] as num?)?.toDouble() ?? 0.0,
      label: map['label'] as String?,
      extraData: map['extraData'] as Map<String, dynamic>?,
    );
  }

  /// Day of the data point.
  final DateTime date;

  /// Metric value for that day.
  final double value;

  /// Optional category label (for stacked charts).
  final String? label;

  /// Extra data for stacked bar charts
  final Map<String, dynamic>? extraData;

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'value': value,
      if (label != null) 'label': label,
      if (extraData != null) 'extraData': extraData,
    };
  }

  ChartDataPoint copyWith({
    DateTime? date,
    double? value,
    String? label,
    Map<String, dynamic>? extraData,
  }) {
    return ChartDataPoint(
      date: date ?? this.date,
      value: value ?? this.value,
      label: label ?? this.label,
      extraData: extraData ?? this.extraData,
    );
  }
}
