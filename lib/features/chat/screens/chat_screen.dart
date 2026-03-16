import 'package:biko/core/theme/app_theme.dart';
import 'package:biko/core/widgets/app_empty_state.dart';
import 'package:biko/core/widgets/app_error_widget.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/features/chat/controllers/chat_controller.dart';
import 'package:biko/features/chat/widgets/chat_bubble.dart';
import 'package:biko/features/chat/widgets/chat_input.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// In-trip chat screen with styled message bubbles and input bar
class ChatScreen extends GetView<ChatController> {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Driver avatar placeholder
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: ext.surfaceContainer,
                shape: BoxShape.circle,
                border: Border.all(color: ext.borderSubtle),
              ),
              child: Icon(Icons.person, size: 20, color: ext.textMuted),
            ),
            const SizedBox(width: 12),
            Text('chat.title'.tr),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: AppLoading());
              }
              if (controller.errorMessage.isNotEmpty) {
                return Center(
                  child: AppErrorWidget(
                    message: controller.errorMessage.value.tr,
                  ),
                );
              }
              if (controller.messages.isEmpty) {
                return Center(
                  child: AppEmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'chat.no_messages'.tr,
                  ),
                );
              }

              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final msg = controller
                      .messages[controller.messages.length - 1 - index];
                  return ChatBubble(
                    message: msg.message,
                    time: DateFormat('hh:mm a').format(msg.createdAt),
                    isMe: controller.isMyMessage(msg),
                  );
                },
              );
            }),
          ),

          // Input bar
          Obx(
            () => ChatInput(
              controller: controller.messageController,
              onSend: controller.sendMessage,
              isSending: controller.isSending.value,
            ),
          ),
        ],
      ),
    );
  }
}
