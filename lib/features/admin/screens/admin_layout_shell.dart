import 'package:biko/features/admin/controllers/admin_layout_controller.dart';
import 'package:biko/features/admin/widgets/admin_sidebar.dart';
import 'package:biko/features/admin/widgets/admin_topbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Layout wrapper — sidebar + topbar + content area.
///
/// Uses [LayoutBuilder] for responsive breakpoints:
/// - Desktop (>1200px): expanded sidebar
/// - Tablet (768-1200px): collapsed sidebar (icons only)
/// - Mobile (<768px): drawer sidebar
class AdminLayoutShell extends GetView<AdminLayoutController> {
  const AdminLayoutShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Schedule width update after build to avoid modifying .obs
        // during the build phase.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller.updateScreenWidth(constraints.maxWidth);
        });

        return Obx(() {
          if (controller.isMobile) {
            return Scaffold(
              drawer: const Drawer(child: AdminSidebar()),
              body: Column(
                children: [
                  const AdminTopbar(),
                  Expanded(child: child),
                ],
              ),
            );
          }

          return Scaffold(
            body: Row(
              children: [
                const AdminSidebar(),
                Expanded(
                  child: Column(
                    children: [
                      const AdminTopbar(),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}
