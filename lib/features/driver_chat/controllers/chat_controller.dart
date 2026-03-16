import 'dart:async';

import 'package:biko/core/models/chat_message_model.dart';
import 'package:biko/core/services/auth_service.dart';
import 'package:biko/core/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Controller for the driver chat screen.
///
/// Streams messages from RTDB and handles sending/read receipts.
class ChatController extends GetxController {
  final isLoading = true.obs;
  final messages = <ChatMessageModel>[].obs;
  final messageController = TextEditingController();
  final scrollController = ScrollController();

  late final String tripId;
  String? _currentUid;

  StreamSubscription<List<Map<String, dynamic>>>? _messagesSub;

  @override
  void onInit() {
    super.onInit();
    tripId = Get.arguments as String? ?? '';
    _currentUid = AuthService.currentUid;

    if (tripId.isNotEmpty) {
      _listenToMessages();
    } else {
      isLoading.value = false;
    }
  }

  void _listenToMessages() {
    isLoading.value = true;

    _messagesSub = FirestoreService.listenToChatMessages(tripId).listen(
      (data) {
        final parsed = data.map((map) {
          return ChatMessageModel(
            id: map['message_id'] as String? ?? '',
            tripId: tripId,
            senderUid: map['sender_uid'] as String? ?? '',
            message: map['message'] as String? ?? '',
            isRead: map['is_read'] as bool? ?? false,
            createdAt: map['timestamp'] is int
                ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int)
                : DateTime.now(),
          );
        }).toList();

        messages.assignAll(parsed);
        isLoading.value = false;

        // Mark incoming messages as read
        if (_currentUid != null) {
          FirestoreService.markMessagesRead(tripId, _currentUid!);
        }

        // Scroll to bottom after new messages
        _scrollToBottom();
      },
      onError: (Object e) {
        debugPrint('ChatController._listenToMessages error: $e');
        isLoading.value = false;
      },
    );
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || _currentUid == null) return;

    messageController.clear();

    try {
      await FirestoreService.sendChatMessage(tripId, {
        'sender_uid': _currentUid,
        'message': text,
        'is_read': false,
      });
    } catch (e) {
      debugPrint('ChatController.sendMessage error: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool isMyMessage(ChatMessageModel msg) => msg.senderUid == _currentUid;

  @override
  void onClose() {
    _messagesSub?.cancel();
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
