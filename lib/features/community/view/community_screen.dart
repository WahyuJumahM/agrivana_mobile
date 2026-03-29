import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/shimmer_widgets.dart';
import '../bloc/community_bloc.dart';
import '../model/community_model.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CommunityBloc>().add(CommunityLoadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: BlocBuilder<CommunityBloc, CommunityState>(
        builder: (context, state) {
          if (state is CommunityLoading) {
            return Scaffold(
              appBar: AppBar(title: const Text('Komunitas')),
              body: const ShimmerPostList(),
            );
          }
          if (state is CommunityLoaded) {
            return _buildContent(state);
          }
          return Scaffold(appBar: AppBar(title: const Text('Komunitas')), body: const SizedBox());
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.createPost).then((_) {
          if (mounted) context.read<CommunityBloc>().add(CommunityLoadData());
        }),
        backgroundColor: AppTheme.primary,
        elevation: 4,
        icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
        label: const Text('Buat Diskusi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildContent(CommunityLoaded state) {
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: () async {
        context.read<CommunityBloc>().add(CommunityLoadData());
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Header / SliverAppBar
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primary,
            elevation: 0,
            title: const Text('Komunitas', style: TextStyle(color: Colors.white)),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Icon(Icons.forum_rounded, size: 120, color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    const Positioned(
                      bottom: 24,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Komunitas Agrivana',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Temukan inspirasi dan saling membantu',
                            style: TextStyle(fontSize: 14, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Topics Header
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Eksplorasi Topik', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                ),
                const SizedBox(height: 12),
                // Topic Chips Horizontal List
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _chip('Semua', state.selectedChannelId == null, () => context.read<CommunityBloc>().add(const CommunitySelectChannel(null))),
                      ...state.channels.map((c) {
                        return _chip(c.name, state.selectedChannelId == c.id, () => context.read<CommunityBloc>().add(CommunitySelectChannel(c.id)));
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Content
                if (state.posts.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.people_alt_outlined, size: 48, color: AppTheme.primary),
                          ),
                          const SizedBox(height: 16),
                          const Text('Belum ada diskusi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          const SizedBox(height: 8),
                          Text('Jadilah yang pertama memulai topik diskusi di komunitas ini.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: state.posts.map((p) => _postCard(p)).toList(),
                    ),
                  ),
                const SizedBox(height: 80), // Fab spacing
              ],
            ),
          ),
        ],
      )
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppTheme.primary : Colors.grey.shade300),
          boxShadow: active ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))] : null,
        ),
        child: Text(
          label, 
          style: TextStyle(
            fontSize: 14, 
            fontWeight: active ? FontWeight.bold : FontWeight.w500, 
            color: active ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _postCard(CommunityPost post) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(AppRoutes.postDetail, arguments: {'postId': post.id}).then((_) {
        if (mounted) context.read<CommunityBloc>().add(CommunityLoadData());
      }),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Avatar + Info + Channel
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                  backgroundImage: post.authorPhoto != null ? NetworkImage(post.authorPhoto!) : null,
                  child: post.authorPhoto == null ? const Icon(Icons.person, size: 20, color: AppTheme.primary) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName ?? 'Anonymous', 
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      if (post.channelName != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            post.channelName!, 
                            style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Content
            Text(
              post.title, 
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.4, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              post.body, 
              maxLines: 3, 
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // Actions Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppTheme.textHint),
                      const SizedBox(width: 6),
                      Text(
                        '${post.commentCount} Balasan', 
                        style: const TextStyle(fontSize: 13, color: AppTheme.textHint, fontWeight: FontWeight.w500),
                      ),
                    ]
                  )
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: post.isLiked == true ? AppTheme.primary.withValues(alpha: 0.1) : Colors.grey.shade50, 
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.volunteer_activism_rounded, 
                        size: 16, 
                        color: post.isLiked == true ? AppTheme.primary : AppTheme.textHint,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${post.likeCount} Membantu', 
                        style: TextStyle(
                          fontSize: 13, 
                          color: post.isLiked == true ? AppTheme.primary : AppTheme.textHint, 
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ]
                  )
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
