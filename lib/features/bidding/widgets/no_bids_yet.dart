import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Placeholder shown when no driver bids have arrived yet.
///
/// Displays a pulsing search icon with waiting text.
class NoBidsYet extends StatefulWidget {
  const NoBidsYet({super.key});

  @override
  State<NoBidsYet> createState() => _NoBidsYetState();
}

class _NoBidsYetState extends State<NoBidsYet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) =>
                  Opacity(opacity: _animation.value, child: child),
              child: Icon(Icons.search, size: 48, color: colors.textMuted),
            ),
            const SizedBox(height: 16),
            Text(
              'bids.no_bids_yet'.tr,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
