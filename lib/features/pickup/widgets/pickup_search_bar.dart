import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/features/pickup/controllers/pickup_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Floating search bar overlaid at the top of the pickup map screen.
///
/// When tapped, expands to full-width and activates the search overlay.
/// Supports RTL text input. Uses [AppColorsExtension.surfaceElevated]
/// background with subtle shadow.
class PickupSearchBar extends GetView<PickupController> {
  const PickupSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(Icons.search, size: 20, color: colors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller.searchTextController,
              focusNode: controller.searchFocusNode,
              onChanged: controller.onSearchChanged,
              onTap: controller.activateSearch,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'pickup.search_placeholder'.tr,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.textMuted,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          // Clear button
          Obx(
            () => controller.searchQuery.value.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      controller.searchTextController.clear();
                      controller.onSearchChanged('');
                    },
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 12),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: colors.textMuted,
                      ),
                    ),
                  )
                : const SizedBox(width: 14),
          ),
        ],
      ),
    );
  }
}
