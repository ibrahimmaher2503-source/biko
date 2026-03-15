import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/features/dropoff/controllers/dropoff_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Overlay list showing autocomplete search results for dropoff.
///
/// Shows loading indicator during API calls, "No results" when
/// empty, or a scrollable list of [PlaceAutocompleteResult] items.
class DropoffResultsList extends GetView<DropoffController> {
  const DropoffResultsList({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {},
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Obx(() {
          // Loading state
          if (controller.isSearching.value) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          // No results
          if (controller.searchResults.isEmpty &&
              controller.searchQuery.value.length >= 2) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'dropoff.no_results'.tr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ),
            );
          }

          // Empty query — show nothing
          if (controller.searchResults.isEmpty) {
            return const SizedBox.shrink();
          }

          // Results list
          return ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: controller.searchResults.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, indent: 56, color: colors.borderSubtle),
              itemBuilder: (context, index) {
                final result = controller.searchResults[index];
                return ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: colors.textMuted,
                    ),
                  ),
                  title: Text(
                    result.mainText,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    result.secondaryText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  contentPadding: const EdgeInsetsDirectional.fromSTEB(
                    12,
                    0,
                    12,
                    0,
                  ),
                  onTap: () => controller.onResultTap(result),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}
