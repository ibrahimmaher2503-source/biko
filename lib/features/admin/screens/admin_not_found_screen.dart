import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 404 screen for unknown admin routes.
class AdminNotFoundScreen extends StatelessWidget {
  const AdminNotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'admin.common.page_not_found'.tr,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: Get.back,
              icon: Builder(
                builder: (context) {
                  final isRtl = Directionality.of(context) == TextDirection.rtl;
                  return Icon(isRtl ? Icons.arrow_forward : Icons.arrow_back);
                },
              ),
              label: Text('admin.common.go_back'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
