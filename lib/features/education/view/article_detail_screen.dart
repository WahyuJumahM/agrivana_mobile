// Location: agrivana\lib\features\education\view\article_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../services/api_service.dart';
import '../model/article_model.dart';
import '../service/article_service.dart';

class ArticleDetailScreen extends StatefulWidget {
  const ArticleDetailScreen({super.key});
  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  ArticleModel? _article;
  bool _loading = true;
  bool _error = false;
  List<ArticleModel> _relatedArticles = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final slug = args?['slug']?.toString() ?? '';
    if (slug.isNotEmpty && _article == null && _loading) _loadArticle(slug);
  }

  Future<void> _loadArticle(String slug) async {
    final result = await ArticleService.getArticleBySlug(slug);
    if (result.success && result.data != null && mounted) {
      final article = ArticleModel.fromDetailJson(result.data);
      setState(() {
        _article = article;
        _loading = false;
      });
      // Fire and forget: load related articles
      _loadRelated(article);
    } else if (mounted) {
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  Future<void> _loadRelated(ArticleModel article) async {
    // Fetch same category, exclude current article
    final result = await ArticleService.getArticles(query: {
      if (article.categoryName != null) 'search': article.categoryName!,
      'pageSize': '4',
    });
    if (result.success && result.data != null && mounted) {
      final items = result.data['items'] ?? result.data;
      if (items is List) {
        final related = items
            .map<ArticleModel>((j) => ArticleModel.fromJson(j))
            .where((a) => a.id != article.id)
            .take(3)
            .toList();
        setState(() => _relatedArticles = related);
      }
    }
  }

  Future<void> _toggleBookmark() async {
    if (!ApiService.isLoggedIn) {
      _showLoginPrompt();
      return;
    }
    if (_article == null) return;

    // Optimistic update
    setState(() {
      _article = _article!.copyWith(isBookmarked: !_article!.isBookmarked);
    });

    final result = await ArticleService.toggleBookmark(_article!.id);
    if (!result.success && mounted) {
      // Rollback
      setState(() {
        _article = _article!.copyWith(isBookmarked: !_article!.isBookmarked);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.error,
        ),
      );
    } else if (result.success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_article!.isBookmarked
              ? 'Artikel disimpan'
              : 'Bookmark dihapus'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.primary,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _shareArticle() {
    if (_article == null) return;
    Share.share(
      '${_article!.title}\n\nBaca selengkapnya di Agrivana!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error || _article == null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.article_outlined,
                    size: 48, color: AppTheme.error),
              ),
              const SizedBox(height: 16),
              const Text('Artikel tidak tersedia',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Artikel mungkin sudah dihapus atau tidak ditemukan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14, color: AppTheme.textSecondary)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Kembali'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final article = _article!;
    final dateStr = article.publishedAt != null
        ? DateFormat('d MMMM yyyy', 'id').format(article.publishedAt!)
        : '';

    return CustomScrollView(
      slivers: [
        // ─── Hero AppBar with Cover Image ──────────────────────────────
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.white,
          leading: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
          actions: [
            // Share button
            GestureDetector(
              onTap: _shareArticle,
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.share_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
            // Bookmark button
            GestureDetector(
              onTap: _toggleBookmark,
              child: Container(
                margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  article.isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: article.isBookmarked
                      ? AppTheme.warning
                      : Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                article.coverImage != null && article.coverImage!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: article.coverImage!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                            color: AppTheme.primary.withValues(alpha: 0.1)),
                        errorWidget: (_, __, ___) => Container(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            child: const Icon(Icons.image_not_supported_rounded,
                                color: AppTheme.primary, size: 48)),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                        ),
                        child: const Center(
                          child: Icon(Icons.article_rounded,
                              size: 64, color: Colors.white54),
                        ),
                      ),
                // Gradient overlay for text readability
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ─── Article Content ───────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category + Premium badge
                Row(
                  children: [
                    if (article.categoryName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(article.categoryName!,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary)),
                      ),
                    if (article.isPremium) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: AppTheme.premiumGradient,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.workspace_premium_rounded,
                                size: 13, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Premium',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                    if (article.difficulty != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _difficultyColor(article.difficulty!)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _difficultyLabel(article.difficulty!),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _difficultyColor(article.difficulty!),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  article.title,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      height: 1.3),
                ),
                const SizedBox(height: 14),

                // Author + meta
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            AppTheme.primary.withValues(alpha: 0.15),
                        child: Text(
                          (article.authorName ?? 'A')[0].toUpperCase(),
                          style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(article.authorName ?? 'Admin',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary)),
                            Text(dateStr,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.schedule_rounded,
                                size: 14, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text('${article.readTimeMin ?? 5} min',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.visibility_outlined,
                                size: 14, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text(_formatViews(article.viewCount),
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Plant tags
                if (article.plantTags != null &&
                    article.plantTags!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: article.plantTags!
                        .map((tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text('🌱 $tag',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.primaryDark)),
                            ))
                        .toList(),
                  ),
                ],

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),

                // ─── Premium Lock ─────────────────────────────────────────
                if (article.truncated == true) ...[
                  _buildPremiumLock(),
                  const SizedBox(height: 16),
                ],

                // ─── Article Body (HTML) ──────────────────────────────────
                HtmlWidget(
                  article.body ?? '',
                  textStyle: const TextStyle(
                    fontSize: 15,
                    height: 1.8,
                    color: AppTheme.textPrimary,
                  ),
                ),

                // ─── Related Articles ─────────────────────────────────────
                if (_relatedArticles.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text('Artikel Terkait',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 12),
                  ..._relatedArticles.map((r) => _buildRelatedCard(r)),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Premium Lock Widget ────────────────────────────────────────────────

  Widget _buildPremiumLock() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.premiumGold.withValues(alpha: 0.08),
            AppTheme.premiumGold.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
            color: AppTheme.premiumGold.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_rounded,
              size: 32, color: AppTheme.premiumGold),
          const SizedBox(height: 12),
          const Text('Konten Premium',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.premiumGold)),
          const SizedBox(height: 6),
          const Text(
            'Upgrade ke Premium untuk membaca artikel ini secara lengkap',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.subscription),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.premiumGold,
              foregroundColor: Colors.white,
              minimumSize: const Size(200, 44),
            ),
            child: const Text('Lihat Paket Premium'),
          ),
        ],
      ),
    );
  }

  // ─── Related Article Card ───────────────────────────────────────────────

  Widget _buildRelatedCard(ArticleModel article) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.articleDetail,
          arguments: {'slug': article.slug},
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: article.coverImage != null &&
                      article.coverImage!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: article.coverImage!,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 70,
                      height: 70,
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      child: const Icon(Icons.article_rounded,
                          color: AppTheme.primary, size: 28),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Text(
                    '${article.readTimeMin ?? 5} menit baca',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textHint, size: 20),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────

  Color _difficultyColor(String diff) {
    switch (diff.toLowerCase()) {
      case 'beginner':
        return AppTheme.success;
      case 'intermediate':
        return AppTheme.warning;
      case 'advanced':
        return AppTheme.error;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _difficultyLabel(String diff) {
    switch (diff.toLowerCase()) {
      case 'beginner':
        return 'Pemula';
      case 'intermediate':
        return 'Menengah';
      case 'advanced':
        return 'Mahir';
      default:
        return diff;
    }
  }

  String _formatViews(int views) {
    if (views >= 1000) return '${(views / 1000).toStringAsFixed(1)}k';
    return views.toString();
  }

  void _showLoginPrompt() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bookmark_rounded,
                size: 40, color: AppTheme.primary),
            const SizedBox(height: 16),
            const Text('Login untuk menyimpan artikel',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.login);
              },
              child: const Text('Login'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Nanti saja',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}
