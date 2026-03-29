// Location: agrivana\lib\features\chatbot\bloc\chatbot_bloc.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../service/chatbot_service.dart';
import '../../../utils/dialogs.dart';

// Events
abstract class ChatbotEvent extends Equatable {
  const ChatbotEvent();
  @override
  List<Object?> get props => [];
}

class ChatbotSendMessage extends ChatbotEvent {
  final String message;
  final String? imageBase64;
  const ChatbotSendMessage(this.message, {this.imageBase64});
  @override
  List<Object?> get props => [message, imageBase64];
}

class ChatbotClearChat extends ChatbotEvent {}

// States
abstract class ChatbotState extends Equatable {
  const ChatbotState();
  @override
  List<Object?> get props => [];
}

class ChatbotReady extends ChatbotState {
  final List<Map<String, String>> messages;
  final bool isSending;

  const ChatbotReady({this.messages = const [], this.isSending = false});
  @override
  List<Object?> get props => [messages, isSending];
}

// Bloc
class ChatbotBloc extends Bloc<ChatbotEvent, ChatbotState> {
  final List<Map<String, String>> _messages = [];

  ChatbotBloc() : super(const ChatbotReady()) {
    on<ChatbotSendMessage>(_onSend);
    on<ChatbotClearChat>(_onClear);
  }

  Future<void> _onSend(ChatbotSendMessage event, Emitter<ChatbotState> emit) async {
    // We could store base64 in state, but to save memory we just tag it.
    // However, if we want to display the image locally, we should pass it. 
    // For now, we optionally add the base64 to the local message so ChatBubble can display it.
    final userMsg = {'role': 'user', 'content': event.message};
    if (event.imageBase64 != null) userMsg['imageBase64'] = event.imageBase64!;
    
    _messages.add(userMsg);
    emit(ChatbotReady(messages: List.from(_messages), isSending: true));

    final result = await ChatbotService.sendMessage(event.message, imageBase64: event.imageBase64);
    if (result.success && result.data != null) {
      _messages.add({'role': 'assistant', 'content': result.data['reply']?.toString() ?? ''});
    } else {
      _messages.add({'role': 'assistant', 'content': result.message});
    }

    emit(ChatbotReady(messages: List.from(_messages), isSending: false));
  }

  Future<void> _onClear(ChatbotClearChat event, Emitter<ChatbotState> emit) async {
    final confirmed = await AppDialogs.showConfirmDialog(
      title: 'Hapus Riwayat Chat',
      message: 'Semua pesan akan dihapus.',
      confirmText: 'Hapus',
      confirmColor: const Color(0xFFD32F2F),
      icon: Icons.delete_forever,
    );
    if (!confirmed) return;

    await ChatbotService.clearSession();
    _messages.clear();
    emit(const ChatbotReady(messages: []));
  }
}
