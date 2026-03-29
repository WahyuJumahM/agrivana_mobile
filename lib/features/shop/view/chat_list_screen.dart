// Location: agrivana\lib\features\shop\view\chat_list_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../utils/formatters.dart';
import '../service/chat_service.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});
  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<dynamic> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await ChatService.getConversations();
    if (result.success && result.data != null && mounted) {
      setState(() {
        _conversations = result.data is List ? result.data : [];
        _loading = false;
      });
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Chat')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.chat_outlined, size: 64, color: AppTheme.textHint.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    const Text('Belum ada chat', style: TextStyle(fontSize: 16, color: AppTheme.textHint)),
                    const SizedBox(height: 8),
                    const Text('Mulai chat dari halaman produk',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    itemCount: _conversations.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                    itemBuilder: (_, i) {
                      final conv = _conversations[i] as Map<String, dynamic>;
                      final lastMsg = conv['lastMessage']?.toString();
                      final lastAt = conv['lastMessageAt'] != null
                          ? DateTime.tryParse(conv['lastMessageAt'].toString())
                          : null;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                          backgroundImage: conv['otherUserPhoto'] != null
                              ? NetworkImage(conv['otherUserPhoto'].toString())
                              : null,
                          child: conv['otherUserPhoto'] == null
                              ? const Icon(Icons.person_rounded, color: AppTheme.primary, size: 24)
                              : null,
                        ),
                        title: Text(conv['otherUserName']?.toString() ?? 'User',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: lastMsg != null
                            ? Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))
                            : null,
                        trailing: lastAt != null
                            ? Text(AppFormatters.timeAgo(lastAt),
                                style: const TextStyle(fontSize: 11, color: AppTheme.textHint))
                            : null,
                        onTap: () async {
                          await Navigator.of(context).pushNamed(
                            AppRoutes.chatConversation,
                            arguments: {
                              'conversationId': conv['id']?.toString(),
                              'otherUserName': conv['otherUserName']?.toString() ?? 'User',
                              'otherUserPhoto': conv['otherUserPhoto']?.toString(),
                            },
                          );
                          _load(); // refresh on return
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
