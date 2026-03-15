import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading.dart';
import '../controllers/admin_notifications_controller.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/notification_preview_card.dart';

class AdminNotificationsScreen extends GetView<AdminNotificationsController> {
  const AdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('admin.notifications.title'.tr),
          bottom: TabBar(
            tabs: [
              Tab(text: 'admin.notifications.tabs.send'.tr),
              Tab(text: 'admin.notifications.tabs.history'.tr),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSendTab(context, colors),
            _buildHistoryTab(context, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildSendTab(BuildContext context, AppColorsExtension colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'admin.notifications.form.title'.tr,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'admin.notifications.form.target_segment'.tr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(
                    () => DropdownButtonFormField<String>(
                      initialValue: controller.targetSegment.value,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('admin.notifications.segments.all'.tr),
                        ),
                        DropdownMenuItem(
                          value: 'customers',
                          child: Text(
                            'admin.notifications.segments.customers'.tr,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'drivers',
                          child: Text(
                            'admin.notifications.segments.drivers'.tr,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'specific',
                          child: Text(
                            'admin.notifications.segments.specific'.tr,
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          controller.targetSegment.value = value;
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Obx(
                    () => controller.targetSegment.value == 'specific'
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'admin.notifications.form.user_uid'.tr,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                decoration: InputDecoration(
                                  hintText:
                                      'admin.notifications.form.user_uid_hint'
                                          .tr,
                                  border: const OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  controller.specificUid.value = value;
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                  const Divider(height: 32),
                  Text(
                    'admin.notifications.form.arabic_section'.tr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'admin.notifications.form.title_ar'.tr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'admin.notifications.form.title_ar_hint'.tr,
                      border: const OutlineInputBorder(),
                    ),
                    textDirection: TextDirection.rtl,
                    onChanged: (value) {
                      controller.titleAr.value = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'admin.notifications.form.body_ar'.tr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'admin.notifications.form.body_ar_hint'.tr,
                      border: const OutlineInputBorder(),
                    ),
                    textDirection: TextDirection.rtl,
                    maxLines: 3,
                    onChanged: (value) {
                      controller.bodyAr.value = value;
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'admin.notifications.form.english_section'.tr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'admin.notifications.form.title_en'.tr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'admin.notifications.form.title_en_hint'.tr,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      controller.titleEn.value = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'admin.notifications.form.body_en'.tr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'admin.notifications.form.body_en_hint'.tr,
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      controller.bodyEn.value = value;
                    },
                  ),
                  const SizedBox(height: 32),
                  Obx(
                    () => AppButton(
                      text: 'admin.notifications.form.send'.tr,
                      onPressed: controller.isFormValid
                          ? () => _showSendConfirmDialog(context)
                          : null,
                      isLoading: controller.isSending.value,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Obx(
              () => NotificationPreviewCard(
                titleAr: controller.titleAr.value,
                titleEn: controller.titleEn.value,
                bodyAr: controller.bodyAr.value,
                bodyEn: controller.bodyEn.value,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(BuildContext context, AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Obx(() {
        if (controller.isLoading.value && controller.sentHistory.isEmpty) {
          return const Center(child: AppLoading());
        }

        if (controller.sentHistory.isEmpty) {
          return Center(
            child: Text(
              'admin.notifications.history.empty'.tr,
              style: TextStyle(color: colors.textMuted),
            ),
          );
        }

        return ListView.separated(
          itemCount: controller.sentHistory.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final record = controller.sentHistory[index];
            return ListTile(
              title: Text(record.titleEn),
              subtitle: Text(_formatTargetSegment(record.targetSegment)),
              trailing: Text(
                DateFormat('yyyy-MM-dd HH:mm').format(record.sentAt),
                style: TextStyle(color: colors.textMuted, fontSize: 12),
              ),
              leading: Text(
                record.senderName,
                style: const TextStyle(fontSize: 12),
              ),
            );
          },
        );
      }),
    );
  }

  String _formatTargetSegment(String segment) {
    if (segment.startsWith('specific:')) {
      return '${'admin.notifications.segments.specific'.tr} (${segment.substring(9)})';
    }
    return 'admin.notifications.segments.$segment'.tr;
  }

  Future<void> _showSendConfirmDialog(BuildContext context) async {
    final segmentLabel = controller.targetSegment.value == 'specific'
        ? '${'admin.notifications.segments.specific'.tr} (${controller.specificUid.value})'
        : 'admin.notifications.segments.${controller.targetSegment.value}'.tr;

    final confirmed = await ConfirmDialog.show(
      title: 'admin.notifications.confirm.title'.tr,
      message: 'admin.notifications.confirm.message'.trParams({
        'segment': segmentLabel,
      }),
      confirmLabel: 'admin.notifications.confirm.send'.tr,
      cancelLabel: 'admin.common.cancel'.tr,
    );

    if (confirmed) {
      await controller.sendNotification();
    }
  }
}
