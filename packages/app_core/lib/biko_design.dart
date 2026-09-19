import 'package:flutter/material.dart';

/// Biko's shared visual vocabulary. Apps may add product-specific behavior,
/// but brand and semantic colors stay here so they cannot drift apart.
abstract final class BikoColors {
  static const primary = Color(0xFFE50914);
  static const primaryDark = Color(0xFFB70710);
  static const primarySoft = Color(0xFFFFF1F2);

  static const background = Color(0xFFF7F7F8);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSecondary = Color(0xFFF3F4F6);

  static const textPrimary = Color(0xFF111111);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9CA3AF);
  static const border = Color(0xFFE5E7EB);

  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFDC2626);
  static const info = Color(0xFF2563EB);
}

abstract final class BikoSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const gap = 12.0;
  static const md = 16.0;
  static const section = 20.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 40.0;
}

abstract final class BikoRadius {
  static const compact = 10.0;
  static const small = 12.0;
  static const card = 14.0;
  static const medium = 16.0;
  static const largeCompact = 18.0;
  static const large = 20.0;
  static const sheet = 24.0;
}

abstract final class BikoMotion {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 350);
}

ThemeData buildBikoTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: BikoColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: BikoColors.primary,
        onPrimary: BikoColors.surface,
        primaryContainer: BikoColors.primarySoft,
        onPrimaryContainer: BikoColors.primaryDark,
        secondary: BikoColors.warning,
        onSecondary: BikoColors.textPrimary,
        tertiary: BikoColors.success,
        onTertiary: BikoColors.surface,
        error: BikoColors.error,
        surface: BikoColors.surface,
        onSurface: BikoColors.textPrimary,
        surfaceContainerLowest: BikoColors.surface,
        surfaceContainerLow: BikoColors.surfaceSecondary,
        surfaceContainerHighest: BikoColors.surfaceSecondary,
        outline: BikoColors.border,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Cairo',
    package: 'app_core',
    scaffoldBackgroundColor: BikoColors.background,
    visualDensity: VisualDensity.standard,
    appBarTheme: const AppBarTheme(
      backgroundColor: BikoColors.background,
      foregroundColor: BikoColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: BikoColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        color: BikoColors.textPrimary,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      headlineMedium: TextStyle(
        color: BikoColors.textPrimary,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
      titleLarge: TextStyle(
        color: BikoColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      titleMedium: TextStyle(
        color: BikoColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      titleSmall: TextStyle(
        color: BikoColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      bodyLarge: TextStyle(
        color: BikoColors.textPrimary,
        fontSize: 16,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        color: BikoColors.textSecondary,
        fontSize: 14,
        height: 1.45,
      ),
      bodySmall: TextStyle(
        color: BikoColors.textMuted,
        fontSize: 12,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        color: BikoColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: const CardThemeData(
      color: BikoColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(BikoRadius.medium)),
        side: BorderSide(color: BikoColors.border),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: BikoColors.surface,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(BikoRadius.medium)),
        borderSide: BorderSide(color: BikoColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(BikoRadius.medium)),
        borderSide: BorderSide(color: BikoColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(BikoRadius.medium)),
        borderSide: BorderSide(color: BikoColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(BikoRadius.medium)),
        borderSide: BorderSide(color: BikoColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(BikoRadius.medium)),
        borderSide: BorderSide(color: BikoColors.error, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(BikoRadius.medium)),
        borderSide: BorderSide(color: BikoColors.border),
      ),
      hintStyle: TextStyle(color: BikoColors.textMuted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: BikoColors.primary,
        foregroundColor: BikoColors.surface,
        disabledBackgroundColor: BikoColors.primarySoft,
        disabledForegroundColor: BikoColors.textMuted,
        minimumSize: const Size(44, 54),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BikoRadius.medium),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(44, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BikoRadius.medium),
        ),
        side: const BorderSide(color: BikoColors.border),
        foregroundColor: BikoColors.textPrimary,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size.square(48)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 64,
      backgroundColor: BikoColors.surface,
      elevation: 0,
      indicatorColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? BikoColors.primary
              : BikoColors.textSecondary,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? BikoColors.primary
              : BikoColors.textSecondary,
          size: 23,
        ),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: BikoColors.surface,
      modalBackgroundColor: BikoColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BikoRadius.sheet),
        ),
      ),
      showDragHandle: true,
    ),
  );
}

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({required this.title, this.actions, super.key});

  final String title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) =>
      AppBar(title: Text(title), actions: actions);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: BikoColors.border)),
    ),
    child: NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: destinations,
    ),
  );
}

class ButtonLoading extends StatelessWidget {
  const ButtonLoading({this.color, super.key});

  final Color? color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'جاري التنفيذ',
    liveRegion: true,
    child: SizedBox.square(
      dimension: 20,
      child: CircularProgressIndicator(
        color: color ?? Theme.of(context).colorScheme.onPrimary,
        strokeWidth: 2,
      ),
    ),
  );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final child = isLoading ? const ButtonLoading() : Text(label);
    return Semantics(
      container: true,
      excludeSemantics: true,
      button: true,
      label: label,
      enabled: onPressed != null && !isLoading,
      onTap: isLoading ? null : onPressed,
      value: isLoading ? 'جاري التنفيذ' : null,
      child: SizedBox(
        width: double.infinity,
        child: icon == null || isLoading
            ? FilledButton(
                onPressed: isLoading ? null : onPressed,
                style: backgroundColor == null
                    ? null
                    : FilledButton.styleFrom(backgroundColor: backgroundColor),
                child: child,
              )
            : FilledButton.icon(
                onPressed: onPressed,
                style: backgroundColor == null
                    ? null
                    : FilledButton.styleFrom(backgroundColor: backgroundColor),
                icon: Icon(icon),
                label: child,
              ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: icon == null
        ? OutlinedButton(onPressed: onPressed, child: Text(label))
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          ),
  );
}

class DestructiveButton extends StatelessWidget {
  const DestructiveButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
    final style = OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color.withValues(alpha: .45)),
    );
    return Semantics(
      container: true,
      excludeSemantics: true,
      button: true,
      label: label,
      enabled: onPressed != null && !isLoading,
      onTap: isLoading ? null : onPressed,
      value: isLoading ? 'جاري التنفيذ' : null,
      child: SizedBox(
        width: double.infinity,
        child: icon == null || isLoading
            ? OutlinedButton(
                onPressed: isLoading ? null : onPressed,
                style: style,
                child: isLoading ? ButtonLoading(color: color) : Text(label),
              )
            : OutlinedButton.icon(
                onPressed: onPressed,
                style: style,
                icon: Icon(icon),
                label: Text(label),
              ),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    this.controller,
    this.label,
    this.hint,
    this.validator,
    this.keyboardType,
    this.textDirection,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.maxLines = 1,
    super.key,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextDirection? textDirection;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final int maxLines;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    validator: validator,
    keyboardType: keyboardType,
    textDirection: textDirection,
    obscureText: obscureText,
    enabled: enabled,
    maxLines: obscureText ? 1 : maxLines,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
    ),
  );
}

class LocationField extends StatelessWidget {
  const LocationField({
    required this.label,
    required this.onTap,
    this.address,
    this.placeholder = 'اختر من الخريطة',
    this.enabled = true,
    this.isLoading = false,
    this.fieldKey,
    super.key,
  });

  final String label;
  final String? address;
  final String placeholder;
  final bool enabled;
  final bool isLoading;
  final VoidCallback onTap;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    excludeSemantics: true,
    button: true,
    enabled: enabled && !isLoading,
    onTap: enabled && !isLoading ? onTap : null,
    label: label,
    value: address ?? placeholder,
    child: InkWell(
      key: fieldKey,
      onTap: enabled && !isLoading ? onTap : null,
      borderRadius: BorderRadius.circular(BikoRadius.medium),
      child: InputDecorator(
        isEmpty: address == null,
        decoration: InputDecoration(
          enabled: enabled,
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          prefixIcon: const Icon(Icons.location_on_outlined),
          suffixIcon: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(BikoSpace.gap),
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const Icon(Icons.map_outlined),
        ),
        child: Text(
          address ?? placeholder,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: address == null
              ? Theme.of(context).textTheme.bodyMedium
              : Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    ),
  );
}

class PriceInput extends StatelessWidget {
  const PriceInput({
    required this.controller,
    required this.validator,
    this.label = 'السعر المقترح',
    this.supportingText,
    this.enabled = true,
    this.isLoading = false,
    this.onFieldSubmitted,
    this.fieldKey,
    super.key,
  });

  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final String label;
  final String? supportingText;
  final bool enabled;
  final bool isLoading;
  final ValueChanged<String>? onFieldSubmitted;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) => TextFormField(
    key: fieldKey,
    controller: controller,
    enabled: enabled && !isLoading,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.right,
    textInputAction: TextInputAction.done,
    style: Theme.of(context).textTheme.titleLarge,
    decoration: InputDecoration(
      labelText: label,
      helperText: supportingText,
      prefixText: 'ج.م',
      suffixIcon: isLoading
          ? const Padding(
              padding: EdgeInsets.all(BikoSpace.gap),
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : null,
    ),
    validator: validator,
    onFieldSubmitted: onFieldSubmitted,
  );
}

class InlineLoading extends StatelessWidget {
  const InlineLoading({required this.label, this.icon, super.key});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Semantics(
    excludeSemantics: true,
    label: label,
    liveRegion: true,
    child: Row(
      children: [
        SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
            strokeWidth: 2,
          ),
        ),
        const SizedBox(width: BikoSpace.gap),
        if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: BikoSpace.sm),
        ],
        Expanded(child: Text(label)),
      ],
    ),
  );
}

Future<T?> showBikoBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: builder,
);

class ServiceCard extends StatelessWidget {
  const ServiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.color,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? Theme.of(context).colorScheme.primary;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BikoRadius.medium),
        child: Padding(
          padding: const EdgeInsets.all(BikoSpace.md),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(BikoRadius.medium),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(icon, color: accent, size: 28),
                ),
              ),
              const SizedBox(width: BikoSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: BikoSpace.xs),
                    Text(description),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.label,
    required this.color,
    this.icon,
    super.key,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Semantics(
    excludeSemantics: true,
    label: label,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(BikoSpace.lg),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 48,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: BikoSpace.md),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: BikoSpace.sm),
        Text(
          description,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: BikoSpace.lg),
          PrimaryButton(label: actionLabel!, onPressed: onAction),
        ],
      ],
    ),
  );
}

class ErrorState extends StatelessWidget {
  const ErrorState({required this.message, required this.onRetry, super.key});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.cloud_off_outlined,
    title: 'تعذر تحميل البيانات',
    description: message,
    actionLabel: 'إعادة المحاولة',
    onAction: onRetry,
  );
}
