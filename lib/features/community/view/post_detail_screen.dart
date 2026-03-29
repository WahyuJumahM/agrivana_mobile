import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../service/community_service.dart';
import '../model/community_model.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key});
  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  CommunityPost? _post;
  List<CommentModel> _comments = [];
  bool _loading = true;
  final _commentCtrl = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final postId = args?['postId']?.toString() ?? '';
    if (postId.isNotEmpty && _post == null) _load(postId);
  }

  Future<void> _load(String id) async {
    final result = await CommunityService.getPostDetail(id);
    if (result.success && result.data != null && mounted) {
      final pResult = result.data['post'] ?? result.data;
      setState(() {
        _post = CommunityPost.fromJson(pResult);
        _loading = false;
      });
    } else if (mounted) {
      setState(() => _loading = false);
    }
    // Load comments
    final comResult = await CommunityService.getComments(id);
    if (comResult.success && comResult.data != null && mounted) {
      final items = comResult.data is List ? comResult.data : (comResult.data['items'] ?? []);
      final list = items is List ? items : [];
      setState(() {
        _comments = list.map<CommentModel>((e) => CommentModel.fromJson(e)).toList();
      });
    }
  }

  Future<void> _toggleLike() async {
    if (_post == null) return;
    final postId = _post!.id;
    final result = await CommunityService.toggleReaction(postId, 'like');
    if (result.success) {
      _load(postId); // reload to get updated likeCount and isLiked status
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Detail Diskusi'),
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _post == null
          ? const Center(child: Text('Diskusi tidak ditemukan'))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main Post Card
                        Container(
                          width: double.infinity,
                          color: Colors.white,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Author info
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                                    backgroundImage: _post!.authorPhoto != null ? NetworkImage(_post!.authorPhoto!) : null,
                                    child: _post!.authorPhoto == null ? const Icon(Icons.person, size: 20, color: AppTheme.primary) : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _post!.authorName ?? 'Anonymous',
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                        ),
                                        if (_post!.channelName != null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text(
                                              _post!.channelName!,
                                              style: TextStyle(fontSize: 12, color: AppTheme.primary.withValues(alpha: 0.8), fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Text(
                                _post!.title,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, height: 1.3),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _post!.body,
                                style: const TextStyle(fontSize: 15, height: 1.6, color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 20),
                              // Tags
                              if (_post!.plantTags != null && _post!.plantTags!.isNotEmpty) ...[
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _post!.plantTags!
                                      .map(
                                        (tag) => Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primarySurface,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                                          ),
                                          child: Text('#$tag', style: const TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                                        ),
                                      ).toList(),
                                ),
                                const SizedBox(height: 24),
                              ],
                              const Divider(height: 1),
                              const SizedBox(height: 16),
                              // Reaction row
                              Row(
                                children: [
                                  InkWell(
                                    onTap: _toggleLike,
                                    borderRadius: BorderRadius.circular(24),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: _post!.isLiked == true ? AppTheme.primary : AppTheme.background,
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.volunteer_activism_rounded,
                                            size: 18,
                                            color: _post!.isLiked == true ? Colors.white : AppTheme.textHint,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${_post!.likeCount} Membantu',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: _post!.isLiked == true ? Colors.white : AppTheme.textSecondary,
                                              fontWeight: _post!.isLiked == true ? FontWeight.bold : FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    child: Row(
                                      children: [
                                        Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Colors.grey.shade500),
                                        const SizedBox(width: 6),
                                        Text('${_comments.length} Balasan', style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Comments Section Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                          child: Text(
                            'Balasan (${_comments.length})',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                        ),
                        
                        // Comments List
                        if (_comments.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.chat_rounded, size: 48, color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  Text('Belum ada balasan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                                  const SizedBox(height: 4),
                                  Text('Beri tanggapan dan bantu berdiskusi', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                                ],
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: _comments.map(
                                (c) => Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor: AppTheme.primarySurface,
                                            backgroundImage: c.authorPhoto != null ? NetworkImage(c.authorPhoto!) : null,
                                            child: c.authorPhoto == null ? const Icon(Icons.person, size: 14, color: AppTheme.primary) : null,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            c.authorName ?? 'Anonymous',
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        c.body,
                                        style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
                                      ),
                                    ],
                                  ),
                                ),
                              ).toList(),
                            ),
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                
                // Comment input
                Container(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: TextField(
                            controller: _commentCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Tulis balasan...',
                              hintStyle: TextStyle(fontSize: 14),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          onPressed: () async {
                            if (_commentCtrl.text.isEmpty) return;
                            final postId = _post!.id;
                            await CommunityService.addComment(postId, {
                              'body': _commentCtrl.text.trim(),
                            });
                            _commentCtrl.clear();
                            _load(postId);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
