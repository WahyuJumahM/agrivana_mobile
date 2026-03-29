// Location: agrivana\lib\features\education\view\article_bookmarks_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../model/article_model.dart';
import '../service/article_service.dart';

class ArticleBookmarksScreen extends StatefulWidget {
  const ArticleBookmarksScreen({super.key});
  @override
  State<ArticleBookmarksScreen> createState() => _ArticleBookmarksScreenState();
}

class _ArticleBookmarksScreenState extends State<ArticleBookmarksScreen> {
  List<ArticleModel> _bookmarks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    setState(() => _loading = true);
    final result = await ArticleService.getBookmarks();
    if (result.success && result.data != null && mounted) {
      final items = result.data is List ? result.data : [];
      setState(() {
        _bookmarks =
            items.map<ArticleModel>((j) => ArticleModel.fromJson(j)).toList();
        _loading = false;
      });
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _unbookmark(String articleId) async {
    // Optimistic remove
    final idx = _bookmarks.indexWhere((a) => a.id == articleId);
    if (idx == -1) return;

    final removed = _bookmarks[idx];
    setState(() => _bookmarks.removeAt(idx));

    final result = await ArticleService.toggleBookmark(articleId);
    if (!result.success && mounted) {
      setState(() => _bookmarks.insert(idx, removed));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Artikel Tersimpan'),
        actions: [
          if (_bookmarks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_bookmarks.length} artikel',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? _buildSkeletonList()
          : _bookmarks.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: _loadBookmarks,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _bookmarks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _buildBookmarkCard(_bookmarks[i]),
                  ),
                ),
    );
  }

  Widget _buildBookmarkCard(ArticleModel article) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(
        AppRoutes.articleDetail,
        arguments: {'slug': article.slug},
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Cover image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppTheme.radiusMd)),
              child: article.coverImage != null &&
                      article.coverImage!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: article.coverImage!,
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 110,
                        height: 110,
                        color: AppTheme.primary.withValues(alpha: 0.08),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 110,
                        height: 110,
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        child: const Icon(Icons.image_not_supported_rounded,
                            color: AppTheme.primary),
                      ),
                    )
                  : Container(
                      width: 110,
                      height: 110,
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      child: const Icon(Icons.article_rounded,
                          color: AppTheme.primary, size: 32),
                    ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (article.isPremium)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: AppTheme.premiumGradient,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Premium',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    Text(article.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 13,
                            color: AppTheme.textHint.withValues(alpha: 0.6)),
                        const SizedBox(width: 4),
                        Text('${article.readTimeMin ?? 5} min',
                            style: TextStyle(
                                fontSize: 11,
                                color:
                                    AppTheme.textHint.withValues(alpha: 0.7))),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Remove bookmark button
            GestureDetector(
              onTap: () => _unbookmark(article.id),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(Icons.bookmark_remove_rounded,
                    color: AppTheme.error.withValues(alpha: 0.7), size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bookmark_border_rounded,
                size: 48,
                color: AppTheme.textHint.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 16),
          const Text('Belum ada artikel tersimpan',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Text('Ketuk ikon bookmark pada artikel untuk menyimpannya',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textHint.withValues(alpha: 0.7))),
        ],
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade50,
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
      ),
    );
  }
}
