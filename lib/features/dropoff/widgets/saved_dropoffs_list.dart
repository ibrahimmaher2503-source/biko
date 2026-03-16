import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/features/dropoff/controllers/dropoff_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Horizontal chips row for saved places (Home/Work) and recent dropoffs.
class SavedDropoffsList extends GetView<DropoffController> {
  const SavedDropoffsList({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),

        // Recent dropoffs header
        Obx(
          () => controller.recentDropoffs.isNotEmpty
              ? Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: 8),
                  child: Text(
                    'dropoff.recent_dropoffs'.tr,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // Recent dropoffs list
        Obx(() {
          if (controller.recentDropoffs.isEmpty) {
            return const SizedBox.shrink();
          }

          return ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.recentDropoffs.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, indent: 44, color: colors.borderSubtle),
              itemBuilder: (context, index) {
                final place = controller.recentDropoffs[index];
                return InkWell(
                  onTap: () => controller.selectDropoff(place),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: colors.surfaceContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.history,
                            size: 16,
                            color: colors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                place.name,
                                style: theme.textTheme.bodyMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                place.address,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }
}
