import 'package:flutter/material.dart';

/// Centralized status color mappings for admin dashboard screens.
/// Replaces hardcoded Color(0xFF...) throughout admin screens.
///
/// Color constants match the light-theme values from [AppColorsExtension].
/// For theme-aware usage inside widgets that already hold a `colors` reference,
/// prefer `colors.success` / `colors.warning` etc. Use this utility when a
/// *status string* must be translated to a colour without access to the
/// extension (e.g. inside a helper method that receives only a [String]).
class AdminStatusColors {
  AdminStatusColors._();

  // ───────────────────── Semantic base colours ─────────────────────
  /// Green — success / active / completed / approved / online / rewarded
  static const Color success = Color(0xFF16A34A);

  /// Red — error / rejected / suspended / failed / cancelled / debit
  static const Color error = Color(0xFFDC2626);

  /// Amber — warning / pending / processing / inactive / refund
  static const Color warning = Color(0xFFD97706);

  /// Gray — neutral / exhausted / offline
  static const Color neutral = Color(0xFF6B7280);

  /// Blue — info / default fallback
  static const Color info = Color(0xFF2563EB);

  // ───────────────────── Background variants ─────────────────────
  static const Color successBg = Color(0xFFDCFCE7);
  static const Color errorBg = Color(0xFFFEE2E2);
  static const Color warningBg = Color(0xFFFEF3C7);

  // ───────────────────── Trip-type accent colours ─────────────────
  /// Purple — C2C delivery
  static const Color c2cPurple = Color(0xFF7C3AED);

  /// Teal — B2B delivery
  static const Color b2bTeal = Color(0xFF0891B2);

  // ───────────────────── Status helpers ─────────────────────────

  /// General status → foreground colour.
  ///
  /// Covers: approved, active, completed, success, online, rewarded,
  /// pending, processing, inactive, rejected, suspended, failed,
  /// cancelled, expired, error, exhausted, offline, credit, top_up,
  /// debit, refund.
  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'active':
      case 'completed':
      case 'success':
      case 'online':
      case 'rewarded':
      case 'credit':
      case 'top_up':
        return success;
      case 'pending':
      case 'processing':
      case 'inactive':
      case 'refund':
        return warning;
      case 'rejected':
      case 'suspended':
      case 'failed':
      case 'cancelled':
      case 'expired':
      case 'error':
      case 'debit':
        return error;
      case 'exhausted':
      case 'offline':
        return neutral;
      default:
        return info;
    }
  }

  /// Light background variant for status badges.
  static Color statusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'active':
      case 'completed':
      case 'success':
      case 'online':
      case 'rewarded':
        return successBg;
      case 'pending':
      case 'processing':
      case 'inactive':
        return warningBg;
      case 'rejected':
      case 'suspended':
      case 'failed':
      case 'cancelled':
      case 'expired':
      case 'error':
        return errorBg;
      case 'exhausted':
      case 'offline':
        return neutral.withValues(alpha: 0.1);
      default:
        return info.withValues(alpha: 0.1);
    }
  }

  /// Trip-type badge colour.
  static Color tripTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'ride':
        return info;
      case 'c2c_delivery':
      case 'c2cdelivery':
        return c2cPurple;
      case 'b2b_delivery':
      case 'b2bdelivery':
        return b2bTeal;
      default:
        return neutral;
    }
  }

  /// Trip-type badge background colour.
  static Color tripTypeBgColor(String type) {
    switch (type.toLowerCase()) {
      case 'ride':
        return const Color(0xFFEFF6FF);
      case 'c2c_delivery':
      case 'c2cdelivery':
        return const Color(0xFFF5F3FF);
      case 'b2b_delivery':
      case 'b2bdelivery':
        return const Color(0xFFECFEFF);
      default:
        return neutral.withValues(alpha: 0.1);
    }
  }

  /// Credit / debit indicator colour.
  static Color transactionColor({required bool isCredit}) {
    return isCredit ? success : error;
  }
}
