import 'dart:async';

import 'package:biko/core/models/chat_message_model.dart';
import 'package:biko/core/services/firestore_service.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Controller for in-trip chat between customer and driver.
///
/// Listens to chat messages in Realtime DB at `/chats/$tripId/messages`
/// and sends new messages via [FirestoreService].
class ChatController extends GetxController {
  final RxList<ChatMessageModel> messages = <ChatMessageModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isSending = false.obs;
  final RxString errorMessage = ''.obs;
  final messageController = TextEditingController();

  String _tripId = '';
  String _currentUid = '';
  StreamSubscription<List<Map<String, dynamic>>>? _messagesSub;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      _tripId = args['tripId'] as String? ?? '';
      _currentUid = args['uid'] as String? ?? '';
    }

    if (_tripId.isNotEmpty) {
      _listenToMessages();
    } else {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _messagesSub?.cancel();
    messageController.dispose();
    super.onClose();
  }

  /// Listen to chat messages from Realtime DB
  void _listenToMessages() {
    _messagesSub = FirestoreService.listenToChatMessages(_tripId).listen(
      (rawMessages) {
        messages.value = rawMessages.map((raw) {
          return ChatMessageModel.fromMap({
            'id': raw['message_id'] as String? ?? '',
            'trip_id': _tripId,
            'sender_uid': raw['sender_uid'] as String? ?? '',
            'message': raw['message'] as String? ?? '',
            'is_read': raw['is_read'] as bool? ?? false,
            'created_at': raw['timestamp'],
          });
        }).toList();
        isLoading.value = false;

        // Mark incoming messages as read
        if (_currentUid.isNotEmpty) {
          FirestoreService.markMessagesRead(_tripId, _currentUid);
        }
      },
      onError: (e) {
        debugPrint('[ChatController] Messages stream error: $e');
        isLoading.value = false;
        errorMessage.value = 'chat.load_error';
      },
    );
  }

  /// Send a message to the chat
  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (_tripId.isEmpty || text.isEmpty || isSending.value) return;

    isSending.value = true;
    try {
      await FirestoreService.sendChatMessage(_tripId, {
        'sender_uid': _currentUid,
        'message': text,
        'is_read': false,
      });
      messageController.clear();
    } catch (e) {
      debugPrint('[ChatController] Send message failed: $e');
      AppSnackbar.error('error.send_message_failed'.tr);
    } finally {
      isSending.value = false;
    }
  }

  /// Check if message is from current user
  bool isMyMessage(ChatMessageModel msg) => msg.senderUid == _currentUid;
}
