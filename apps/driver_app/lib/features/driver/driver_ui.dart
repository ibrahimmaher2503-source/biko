import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

abstract final class DriverColors {
  static const primary = BikoColors.primary;
  static const primaryDark = BikoColors.primaryDark;
  static const background = BikoColors.background;
  static const surface = BikoColors.surface;
  static const text = BikoColors.textPrimary;
  static const muted = BikoColors.textSecondary;
  static const textMuted = BikoColors.textMuted;
  static const border = BikoColors.border;
  static const success = BikoColors.success;
  static const warning = BikoColors.warning;
  static const error = BikoColors.error;
  static const info = BikoColors.info;
}

abstract final class DriverSpace {
  static const xs = BikoSpace.xs;
  static const sm = BikoSpace.sm;
  static const md = BikoSpace.md;
  static const lg = BikoSpace.lg;
  static const xl = BikoSpace.xl;
}

ThemeData buildDriverTheme() => buildBikoTheme();

class DriverShell extends StatelessWidget {
  const DriverShell({
    required this.selectedIndex,
    required this.title,
    required this.child,
    super.key,
  });

  final int selectedIndex;
  final String title;
  final Widget child;

  static const _routes = ['/home', '/history', '/earnings', '/profile'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: title),
      body: SafeArea(top: false, child: child),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: selectedIndex,
        onDestinationSelected: (index) => context.go(_routes[index]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route_rounded),
            label: 'الرحلات',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments_rounded),
            label: 'الأرباح',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'الحساب',
          ),
        ],
      ),
    );
  }
}

class DriverCard extends StatelessWidget {
  const DriverCard({required this.child, this.color, super.key});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) => Card(
    color: color,
    child: Padding(padding: const EdgeInsets.all(DriverSpace.md), child: child),
  );
}

class DriverEmptyState extends StatelessWidget {
  const DriverEmptyState({
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
    padding: const EdgeInsets.all(DriverSpace.lg),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 52, color: DriverColors.muted),
        const SizedBox(height: DriverSpace.md),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: DriverSpace.sm),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(color: DriverColors.muted, height: 1.5),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: DriverSpace.lg),
          FilledButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    ),
  );
}

class DriverErrorState extends StatelessWidget {
  const DriverErrorState({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ConnectionStateView(
    phase: RecoveryPhase.unavailable,
    onRetry: onRetry,
    message: message,
  );
}

class DriverLoadingState extends StatelessWidget {
  const DriverLoadingState({super.key});

  @override
  Widget build(BuildContext context) => const LoadingSkeleton();
}

String driverStatusLabel(DriverStatus status) => switch (status) {
  DriverStatus.pending => 'قيد المراجعة',
  DriverStatus.active => 'نشط',
  DriverStatus.suspended => 'موقوف مؤقتًا',
  DriverStatus.rejected => 'مرفوض',
};

String driverTypeLabel(DriverType type) => switch (type) {
  DriverType.independent => 'سائق مستقل',
  DriverType.officeDriver => 'سائق مكتب',
};
