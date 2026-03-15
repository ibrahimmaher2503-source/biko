import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';

class NotificationPreviewCard extends StatefulWidget {
  const NotificationPreviewCard({
    required this.titleAr,
    required this.titleEn,
    required this.bodyAr,
    required this.bodyEn,
    super.key,
  });
  final String titleAr;
  final String titleEn;
  final String bodyAr;
  final String bodyEn;

  @override
  State<NotificationPreviewCard> createState() =>
      _NotificationPreviewCardState();
}

class _NotificationPreviewCardState extends State<NotificationPreviewCard> {
  bool _showArabic = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>()!;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'admin.notifications.preview.title'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('admin.notifications.preview.arabic'.tr),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('admin.notifications.preview.english'.tr),
                  ),
                ],
                selected: {_showArabic},
                onSelectionChanged: (Set<bool> selection) {
                  setState(() {
                    _showArabic = selection.first;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: 320,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.bike_scooter,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BikeRide',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'admin.notifications.preview.now'.tr,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_showArabic) ...[
                  Text(
                    widget.titleAr.isEmpty
                        ? 'admin.notifications.preview.title_placeholder'.tr
                        : widget.titleAr,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: widget.titleAr.isEmpty
                          ? colors.textMuted
                          : theme.colorScheme.onSurface,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.bodyAr.isEmpty
                        ? 'admin.notifications.preview.body_placeholder'.tr
                        : widget.bodyAr,
                    style: TextStyle(
                      fontSize: 13,
                      color: widget.bodyAr.isEmpty
                          ? colors.textMuted
                          : theme.colorScheme.onSurface,
                    ),
                    textDirection: TextDirection.rtl,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else ...[
                  Text(
                    widget.titleEn.isEmpty
                        ? 'admin.notifications.preview.title_placeholder'.tr
                        : widget.titleEn,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: widget.titleEn.isEmpty
                          ? colors.textMuted
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.bodyEn.isEmpty
                        ? 'admin.notifications.preview.body_placeholder'.tr
                        : widget.bodyEn,
                    style: TextStyle(
                      fontSize: 13,
                      color: widget.bodyEn.isEmpty
                          ? colors.textMuted
                          : theme.colorScheme.onSurface,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
