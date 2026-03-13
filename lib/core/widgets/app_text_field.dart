import 'package:flutter/material.dart';

/// BikeRide branded text field widget with support for:
/// - Material 3 styling following AppTheme
/// - Prefix and suffix icons with RTL support
/// - Label, hint, and error text
/// - Validation and error states
/// - Obscure text for passwords
/// - Character limits and multiline support
///
/// **RTL HANDLING:**
/// Icons automatically flip in RTL layouts (Arabic):
/// - `prefixIcon` becomes suffix in RTL
/// - `suffixIcon` becomes prefix in RTL
/// - Text alignment follows system locale direction
/// - Implementation: `Directionality.of(context)` determines text direction
///
/// **THEME ADAPTATION:**
/// Text field automatically adapts to current theme:
/// - Colors: Uses theme InputDecorationTheme from AppTheme
/// - Border radius: Uses `AppTheme.radiusXl` (16dp)
/// - Focus colors: Primary color on focus
/// - Error colors: Red (#F44336) for validation errors
/// - Dark mode: Automatically applies dark theme input styling
///
/// Example usage:
/// ```dart
/// final controller = TextEditingController();
///
/// AppTextField(
///   controller: controller,
///   label: 'Email',
///   hint: 'Enter your email address',
///   prefixIcon: Icons.email,  // Will flip in RTL
///   keyboardType: TextInputType.emailAddress,
///   validator: (value) => value?.isEmpty == true ? 'Required' : null,
/// )
/// ```
class AppTextField extends StatefulWidget {
  const AppTextField({
    required this.controller,
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.maxLength,
    this.maxLines = 1,
    this.validator,
    this.onTap,
    this.onChanged,
    this.onEditingComplete,
    this.focusNode,
    this.autofocus = false,
  });

  /// Text editing controller (required)
  final TextEditingController controller;

  /// Label text displayed above the field
  final String? label;

  /// Hint text displayed when field is empty
  final String? hint;

  /// Error message displayed below the field
  final String? errorText;

  /// Icon displayed at the start of the field (flipped in RTL)
  final IconData? prefixIcon;

  /// Icon displayed at the end of the field (flipped in RTL)
  final IconData? suffixIcon;

  /// Hide text input (for passwords)
  final bool obscureText;

  /// Enable or disable the field
  final bool enabled;

  /// Keyboard type for input
  final TextInputType? keyboardType;

  /// Action button on keyboard
  final TextInputAction? textInputAction;

  /// Maximum number of characters allowed
  final int? maxLength;

  /// Maximum number of lines (1 for single-line, null for unlimited)
  final int? maxLines;

  /// Validation function for form fields
  final String? Function(String?)? validator;

  /// Callback when field is tapped
  final VoidCallback? onTap;

  /// Callback when text changes
  final void Function(String)? onChanged;

  /// Callback when editing is complete (e.g., user presses done)
  final VoidCallback? onEditingComplete;

  /// Focus node for managing focus state
  final FocusNode? focusNode;

  /// Auto-focus this field when widget is built
  final bool autofocus;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    // Handle icon flipping for RTL
    final actualPrefixIcon = isRTL ? widget.suffixIcon : widget.prefixIcon;
    final actualSuffixIcon = isRTL ? widget.prefixIcon : widget.suffixIcon;

    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      maxLength: widget.maxLength,
      maxLines: widget.maxLines,
      validator: widget.validator,
      onTap: widget.onTap,
      onChanged: widget.onChanged,
      onEditingComplete: widget.onEditingComplete,
      autofocus: widget.autofocus,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        errorText: widget.errorText,
        prefixIcon: actualPrefixIcon != null ? Icon(actualPrefixIcon) : null,
        suffixIcon: actualSuffixIcon != null ? Icon(actualSuffixIcon) : null,
        // Error border styling is handled by theme InputDecorationTheme
        // but we can override specific properties here if needed
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        // Counter text for character limit
        counterText: widget.maxLength != null
            ? ''
            : null, // Hide default counter
      ),
      style: theme.textTheme.bodyLarge,
    );
  }
}
