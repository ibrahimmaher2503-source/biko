import 'package:flutter/material.dart';

/// Button variant types following Material Design 3 guidelines
enum ButtonVariant {
  /// Filled button with primary color background (highest emphasis)
  primary,

  /// Filled tonal button with secondary color (medium emphasis)
  secondary,

  /// Outlined button with transparent background (low emphasis)
  outline,

  /// Text-only button with no background or border (lowest emphasis)
  text,
}

/// BikeRide branded button widget with support for:
/// - Multiple variants (primary, secondary, outline, text)
/// - Loading state with spinner
/// - Disabled state with reduced opacity
/// - Leading and trailing icons with RTL support
/// - Consistent styling following AppTheme
///
/// **RTL HANDLING:**
/// Icons automatically flip in RTL layouts (Arabic):
/// - `leadingIcon` becomes trailing in RTL
/// - `trailingIcon` becomes leading in RTL
/// - Implementation: `Directionality.of(context)` determines text direction
///
/// **THEME ADAPTATION:**
/// Button automatically adapts to current theme:
/// - Colors: Uses `theme.colorScheme.primary` and variants
/// - Typography: Uses `theme.textTheme` styles from AppTheme
/// - Dark mode: Automatically applies dark theme colors
/// - Border radius: Uses `AppTheme.radiusXl` constant
///
/// Example usage:
/// ```dart
/// AppButton(
///   text: 'Continue',
///   onPressed: () => _handleContinue(),
///   leadingIcon: Icons.arrow_forward,  // Will flip in RTL
///   variant: ButtonVariant.primary,
/// )
/// ```
class AppButton extends StatelessWidget {
  const AppButton({
    required this.text,
    required this.onPressed,
    super.key,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.width = double.infinity,
    this.height = 56.0,
  });

  /// Button label text
  final String text;

  /// Callback when button is pressed (null for disabled state)
  final VoidCallback? onPressed;

  /// Visual style variant
  final ButtonVariant variant;

  /// Shows spinner when true, prevents interaction
  final bool isLoading;

  /// Icon displayed before text (flipped in RTL)
  final IconData? leadingIcon;

  /// Icon displayed after text (flipped in RTL)
  final IconData? trailingIcon;

  /// Custom width (defaults to double.infinity for full-width, pass null for intrinsic width)
  final double? width;

  /// Button height (default 56dp per design spec)
  final double height;

  @override
  Widget build(BuildContext context) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final isDisabled = onPressed == null;

    // Build button content (text + icons + loading)
    Widget content = _buildContent(context, isRTL);

    // Apply opacity for disabled state
    if (isDisabled && !isLoading) {
      content = Opacity(opacity: 0.5, child: content);
    }

    // Build appropriate button based on variant
    final button = _buildButton(context, content);

    // Only wrap in SizedBox if width is not infinite
    // When width is infinite, let parent constraints determine width
    if (width == double.infinity) {
      return SizedBox(height: height, child: button);
    }
    return SizedBox(width: width, height: height, child: button);
  }

  /// Build button content (text with optional icons and loading indicator)
  Widget _buildContent(BuildContext context, bool isRTL) {
    if (isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    final List<Widget> children = <Widget>[];

    // Handle icon positioning based on RTL
    final actualLeadingIcon = isRTL ? trailingIcon : leadingIcon;
    final actualTrailingIcon = isRTL ? leadingIcon : trailingIcon;

    if (actualLeadingIcon != null) {
      children.add(Icon(actualLeadingIcon, size: 20));
      children.add(const SizedBox(width: 8));
    }

    children.add(Text(text));

    if (actualTrailingIcon != null) {
      children.add(const SizedBox(width: 8));
      children.add(Icon(actualTrailingIcon, size: 20));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }

  /// Build appropriate button widget based on variant
  Widget _buildButton(BuildContext context, Widget content) {
    // Disable interaction when loading or disabled
    final effectiveOnPressed = (isLoading || onPressed == null)
        ? null
        : onPressed;

    switch (variant) {
      case ButtonVariant.primary:
        return FilledButton(onPressed: effectiveOnPressed, child: content);

      case ButtonVariant.secondary:
        return FilledButton.tonal(
          onPressed: effectiveOnPressed,
          child: content,
        );

      case ButtonVariant.outline:
        return OutlinedButton(onPressed: effectiveOnPressed, child: content);

      case ButtonVariant.text:
        return TextButton(onPressed: effectiveOnPressed, child: content);
    }
  }
}
