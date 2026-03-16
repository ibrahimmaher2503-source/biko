import 'package:biko/core/models/enums.dart';
import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Colored badge for displaying statuses (UserStatus, DocumentStatus,
/// TripStatus, or any custom string).
///
/// Factory constructors use the app's brand colors where possible and
/// localized labels via `.tr` translations.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.label,
    required this.color,
    super.key,
    this.backgroundColor,
  });

  /// Create a badge from [UserStatus].
  factory StatusBadge.fromUserStatus(UserStatus status) {
    switch (status) {
      case UserStatus.active:
        return StatusBadge(
          label: 'admin.status.active'.tr,
          color: _successColor,
          backgroundColor: _successBg,
        );
      case UserStatus.suspended:
        return StatusBadge(
          label: 'admin.status.suspended'.tr,
          color: _errorColor,
          backgroundColor: _errorBg,
        );
      case UserStatus.pendingApproval:
        return StatusBadge(
          label: 'admin.status.pending'.tr,
          color: _warningColor,
          backgroundColor: _warningBg,
        );
    }
  }

  /// Create a badge from [DocumentStatus].
  factory StatusBadge.fromDocumentStatus(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.pending:
        return StatusBadge(
          label: 'admin.status.pending'.tr,
          color: _warningColor,
          backgroundColor: _warningBg,
        );
      case DocumentStatus.approved:
        return StatusBadge(
          label: 'admin.status.approved'.tr,
          color: _successColor,
          backgroundColor: _successBg,
        );
      case DocumentStatus.rejected:
        return StatusBadge(
          label: 'admin.status.rejected'.tr,
          color: _errorColor,
          backgroundColor: _errorBg,
        );
    }
  }

  /// Create a badge from [TripStatus].
  factory StatusBadge.fromTripStatus(TripStatus status) {
    Color color;
    Color bg;
    String labelKey;
    switch (status) {
      case TripStatus.completed:
        color = _successColor;
        bg = _successBg;
        labelKey = 'admin.status.completed';
      case TripStatus.cancelled:
        color = _errorColor;
        bg = _errorBg;
        labelKey = 'admin.status.cancelled';
      case TripStatus.inProgress:
      case TripStatus.onTheWay:
      case TripStatus.arrived:
        color = _infoColor;
        bg = _infoBg;
        labelKey = 'admin.status.${status.toJson()}';
      default:
        color = _warningColor;
        bg = _warningBg;
        labelKey = 'admin.status.${status.toJson()}';
    }
    return StatusBadge(label: labelKey.tr, color: color, backgroundColor: bg);
  }

  // Semantic status colors — aligned with AppColorsExtension tokens.
  // These are used in factories which don't have BuildContext.
  static const _successColor = Color(0xFF16A34A);
  static const _successBg = Color(0xFFDCFCE7);
  static const _errorColor = Color(0xFFDC2626);
  static const _errorBg = Color(0xFFFEE2E2);
  static const _warningColor = Color(0xFFD97706);
  static const _warningBg = Color(0xFFFEF3C7);
  static const _infoColor = Color(0xFF2563EB);
  static const _infoBg = Color(0xFFEFF6FF);

  final String label;
  final Color color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
