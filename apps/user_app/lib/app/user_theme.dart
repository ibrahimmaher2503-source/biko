import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';

abstract final class UserColors {
  static const primary = BikoColors.primary;
  static const primaryDark = BikoColors.primaryDark;
  static const primarySoft = BikoColors.primarySoft;
  static const background = BikoColors.background;
  static const surface = BikoColors.surface;
  static const surfaceSecondary = BikoColors.surfaceSecondary;
  static const text = BikoColors.textPrimary;
  static const muted = BikoColors.textSecondary;
  static const textMuted = BikoColors.textMuted;
  static const border = BikoColors.border;
  static const success = BikoColors.success;
  static const warning = BikoColors.warning;
  static const error = BikoColors.error;
  static const info = BikoColors.info;
}

ThemeData buildUserTheme() => buildBikoTheme();
