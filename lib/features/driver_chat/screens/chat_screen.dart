import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/features/driver_chat/controllers/chat_controller.dart';
import 'package:biko/features/driver_chat/widgets/chat_bubble.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Chat screen for driver-customer communication during a trip.
///
/// Matches stitch design: clean app bar, rounded message input,
/// primary-colored send button in circle, and styled bubbles.
class ChatScreen extends GetView<ChatController> {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppColorsExtension>()!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Customer avatar placeholder
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 20,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'chat.title'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: AppLoading());
              }

              if (controller.messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: ext.surfaceContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 32,
                          color: ext.textMuted,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'chat.no_messages'.tr,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: ext.textMuted,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: controller.scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final msg = controller.messages[index];
                  return ChatBubble(
                    message: msg,
                    isMe: controller.isMyMessage(msg),
                  );
                },
              );
            }),
          ),

          // Message input area
          DecoratedBox(
            decoration: BoxDecoration(
              color: ext.surfaceElevated,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 10, 10),
                child: Row(
                  children: [
                    // Rounded text input
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: ext.surfaceContainer,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusFull,
                          ),
                        ),
                        child: TextField(
                          controller: controller.messageController,
                          textInputAction: TextInputAction.send,
                          decoration: InputDecoration(
                            hintText: 'chat.type_message'.tr,
                            hintStyle: theme.textTheme.bodyMedium?.copyWith(
                              color: ext.textMuted,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => controller.sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Send button in circle
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: controller.sendMessage,
                        icon: const Icon(Icons.send_rounded),
                        iconSize: 20,
                        color: Colors.white,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
