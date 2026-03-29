// Location: agrivana\lib\features\shop\view\chat_conversation_screen.dart
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../service/chat_service.dart';

class ChatConversationScreen extends StatefulWidget {
  const ChatConversationScreen({super.key});
  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  String? _conversationId;
  String _otherName = 'Chat';
  String? _otherPhoto;

  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _pollTimer;
  String? _myUserId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        _conversationId = args['conversationId']?.toString();
        _otherName = args['otherUserName']?.toString() ?? 'Chat';
        _otherPhoto = args['otherUserPhoto']?.toString();
        setState(() {});
        _loadMessages();
        _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadMessages(silent: true));
      }
    });
  }

  Future<void> _loadUserId() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'accessToken');
    if (token == null) return;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return;
      final payload = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(payload));
      final json = jsonDecode(decoded) as Map<String, dynamic>;
      // Try common JWT claims for user ID including ASP.NET Core Identity
      final userId = json['userId'] ??
          json['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ??
          json['nameid'] ??
          json['sub'] ??
          json['user_id'];
      if (userId != null && mounted) setState(() => _myUserId = userId.toString());
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (_conversationId == null) return;
    if (!silent) setState(() => _loading = true);
    final result = await ChatService.getMessages(_conversationId!);
    if (result.success && result.data != null && mounted) {
      final list = (result.data is List ? result.data as List : [])
          .map((m) => m is Map<String, dynamic> ? m : <String, dynamic>{})
          .toList()
          .cast<Map<String, dynamic>>();
      // Messages come in DESC order from API, reverse for display
      list.sort((a, b) {
        final aTime = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime.now();
        final bTime = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime.now();
        return aTime.compareTo(bTime);
      });
      setState(() {
        _messages = list;
        _loading = false;
      });
      if (!silent) _scrollToBottom();
    } else {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _conversationId == null) return;

    _msgCtrl.clear();
    setState(() => _sending = true);

    final result = await ChatService.sendMessage(_conversationId!, text);
    if (mounted) {
      setState(() => _sending = false);
      if (result.success) {
        _loadMessages();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
            backgroundImage: _otherPhoto != null ? NetworkImage(_otherPhoto!) : null,
            child: _otherPhoto == null
                ? const Icon(Icons.person_rounded, color: AppTheme.primary, size: 20)
                : null,
          ),
          const SizedBox(width: 10),
          Text(_otherName, style: const TextStyle(fontSize: 16)),
        ]),
      ),
      body: Column(children: [
        // Messages
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
                  ? const Center(
                      child: Text('Belum ada pesan.\nMulai percakapan!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textHint)))
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) => _buildMessage(_messages[i]),
                    ),
        ),

        // Input bar
        Container(
          padding: EdgeInsets.fromLTRB(12, 8, 8, MediaQuery.of(context).padding.bottom + 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, -1))],
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _msgCtrl,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Tulis pesan...',
                  hintStyle: const TextStyle(fontSize: 14, color: AppTheme.textHint),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: AppTheme.background,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                maxLines: null,
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppTheme.primary,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: _sending ? null : _sendMessage,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: _sending
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    final senderId = msg['senderId']?.toString();
    final isMe = senderId == _myUserId;
    final content = msg['content']?.toString() ?? '';
    final senderName = msg['senderName']?.toString() ?? (isMe ? 'Anda' : _otherName);
    final time = DateTime.tryParse(msg['createdAt']?.toString() ?? '');
    // Convert UTC to WIB (UTC+7)
    final wibTime = time != null ? time.toUtc().add(const Duration(hours: 7)) : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          // Sender name
          Padding(
            padding: EdgeInsets.only(left: isMe ? 4 : 0, right: isMe ? 0 : 4, bottom: 3),
            child: Text(
              isMe ? 'Anda' : senderName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isMe ? AppTheme.primary : Colors.teal.shade700,
              ),
            ),
          ),
          // Message bubble
          Align(
            alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.primary : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 4 : 16),
                  bottomRight: Radius.circular(isMe ? 16 : 4),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
              ),
              child: Column(crossAxisAlignment: isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                Text(content, style: TextStyle(fontSize: 14, color: isMe ? Colors.white : AppTheme.textPrimary, height: 1.4)),
                if (wibTime != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    '${wibTime.hour.toString().padLeft(2, '0')}:${wibTime.minute.toString().padLeft(2, '0')} WIB',
                    style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : AppTheme.textHint),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
