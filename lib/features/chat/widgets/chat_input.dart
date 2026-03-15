import 'package:biko/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Chat message input bar with rounded text field and circle send button
class ChatInput extends StatelessWidget {
  const ChatInput({
    required this.controller,
    required this.onSend,
    this.isSending = false,
    super.key,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: ext.surfaceElevated,
        border: Border(top: BorderSide(color: ext.borderSubtle)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Text input in rounded container
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: ext.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  border: Border.all(color: ext.borderSubtle),
                ),
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'chat.type_message'.tr,
                    hintStyle: TextStyle(color: ext.textMuted),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Circle send button
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
                onPressed: isSending ? null : onSend,
                icon: isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 20),
                color: Colors.white,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
