part of '../driver_screens.dart';

class DriverBootstrapScreen extends ConsumerStatefulWidget {
  const DriverBootstrapScreen({super.key});
  @override
  ConsumerState<DriverBootstrapScreen> createState() =>
      _DriverBootstrapScreenState();
}

class _DriverBootstrapScreenState extends ConsumerState<DriverBootstrapScreen> {
  Object? _error;
  @override
  void initState() {
    super.initState();
    Future.microtask(_restore);
  }

  Future<void> _restore() async {
    setState(() => _error = null);
    try {
      ref.invalidate(driverAccountProvider);
      ref.invalidate(driverActiveOrderProvider);
      final data = await ref.read(driverDashboardProvider.future);
      if (mounted) {
        context.go(
          data.account == null
              ? '/onboarding'
              : driverStartupLocation(data.activeOrder),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      actions: [
        TextButton(
          onPressed: () => context.go('/profile'),
          child: const Text('الحساب'),
        ),
        const SafeSignOutButton(),
      ],
    ),
    body: SafeArea(
      child: _error == null
          ? const LoadingSkeleton()
          : ConnectionStateView(
              phase: RecoveryPhase.unavailable,
              onRetry: _restore,
              message: driverErrorMessage(_error!),
            ),
    ),
  );
}

class DriverRecoveryBoundary extends ConsumerWidget {
  const DriverRecoveryBoundary({
    required this.child,
    this.onProfile,
    super.key,
  });
  final Widget child;
  final VoidCallback? onProfile;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(driverMutationProvider);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Column(
        children: [
          if (controller.blocksActions && !controller.isWaiting)
            Material(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        controller.readError == null
                            ? 'لم نتأكد من نتيجة الإجراء. لن نعيد إرساله.'
                            : driverErrorMessage(controller.readError!),
                      ),
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          TextButton(
                            onPressed: controller.retryRead,
                            child: const Text('إعادة التحقق'),
                          ),
                          if (onProfile != null)
                            TextButton(
                              onPressed: onProfile,
                              child: const Text('الحساب'),
                            ),
                          const SafeSignOutButton(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                AbsorbPointer(absorbing: controller.isWaiting, child: child),
                if (controller.isWaiting)
                  Positioned.fill(
                    child: Material(
                      color: Theme.of(context).colorScheme.surface,
                      child: Center(
                        child: ConnectionStateView(
                          phase: controller.phase,
                          onRetry: controller.retryRead,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
