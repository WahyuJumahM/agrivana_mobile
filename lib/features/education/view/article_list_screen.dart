// Location: agrivana\lib\features\education\view\article_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../services/api_service.dart';
import '../bloc/education_bloc.dart';
import '../model/article_model.dart';

class ArticleListScreen extends StatefulWidget {
  const ArticleListScreen({super.key});
  @override
  State<ArticleListScreen> createState() => _ArticleListScreenState();
}

class _ArticleListScreenState extends State<ArticleListScreen> {
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    context.read<EducationBloc>().add(EducationLoadData());
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<EducationBloc>().add(EducationLoadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildSearchBar(),
            const SizedBox(height: 12),
            _buildCategoryChips(),
            const SizedBox(height: 8),
            Expanded(child: _buildArticleList()),
          ],
        ),
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edukasi',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 2),
              Text('Pelajari teknik pertanian terbaik',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary.withValues(alpha: 0.8))),
            ],
          ),
          const Spacer(),
          // Bookmark icon to navigate to bookmarks screen
          GestureDetector(
            onTap: () {
              if (!ApiService.isLoggedIn) {
                _showLoginPrompt();
                return;
              }
              Navigator.of(context).pushNamed(AppRoutes.articleBookmarks);
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.1),
                    AppTheme.accent.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: const Icon(Icons.bookmark_rounded,
                  size: 22, color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Search Bar ─────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          focusNode: _searchFocus,
          onChanged: (v) =>
              context.read<EducationBloc>().add(EducationSearchChanged(v)),
          decoration: InputDecoration(
            hintText: 'Cari artikel...',
            hintStyle: TextStyle(
                fontSize: 14,
                color: AppTheme.textHint.withValues(alpha: 0.6)),
            prefixIcon: Icon(Icons.search_rounded,
                color: AppTheme.textHint.withValues(alpha: 0.5), size: 20),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      context
                          .read<EducationBloc>()
                          .add(const EducationSearchChanged(''));
                    },
                    child: const Icon(Icons.close_rounded,
                        size: 18, color: AppTheme.textHint),
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  // ─── Category Chips ─────────────────────────────────────────────────────

  Widget _buildCategoryChips() {
    return BlocBuilder<EducationBloc, EducationState>(
      buildWhen: (prev, curr) {
        if (prev is EducationLoaded && curr is EducationLoaded) {
          return prev.selectedCategoryId != curr.selectedCategoryId ||
              prev.categories != curr.categories;
        }
        return true;
      },
      builder: (context, state) {
        if (state is! EducationLoaded || state.categories.isEmpty) {
          return const SizedBox(height: 0);
        }

        final selectedId = state.selectedCategoryId;
        final categories = state.categories;

        return SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: categories.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final isAll = i == 0;
              final isSelected = isAll
                  ? selectedId == null
                  : categories[i - 1].id == selectedId;
              final label = isAll ? 'Semua' : categories[i - 1].name;
              final icon = isAll ? '📚' : (categories[i - 1].icon ?? '📄');

              return GestureDetector(
                onTap: () {
                  final catId = isAll ? null : categories[i - 1].id;
                  context
                      .read<EducationBloc>()
                      .add(EducationSelectCategory(catId));
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.divider.withValues(alpha: 0.6),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(icon, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ─── Article List ───────────────────────────────────────────────────────

  Widget _buildArticleList() {
    return BlocBuilder<EducationBloc, EducationState>(
      builder: (context, state) {
        if (state is EducationLoading) return _buildSkeletonList();

        if (state is EducationLoaded) {
          if (state.articles.isEmpty) return _buildEmptyState();

          return RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: () async {
              context.read<EducationBloc>().add(EducationRefresh());
              // Wait a bit for the state to update
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.separated(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              itemCount: state.articles.length + (state.isLoadingMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                if (i >= state.articles.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                return _buildArticleCard(state.articles[i]);
              },
            ),
          );
        }

        if (state is EducationError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_rounded,
                      size: 56,
                      color: AppTheme.textHint.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text(state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 14)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () =>
                        context.read<EducationBloc>().add(EducationLoadData()),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          );
        }

        return const SizedBox();
      },
    );
  }

  // ─── Article Card ───────────────────────────────────────────────────────

  Widget _buildArticleCard(ArticleModel article) {
    final dateStr = article.publishedAt != null
        ? DateFormat('d MMM yyyy', 'id').format(article.publishedAt!)
        : '';

    return GestureDetector(
      onTap: () => Navigator.of(context)
          .pushNamed(AppRoutes.articleDetail, arguments: {'slug': article.slug}),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusMd)),
              child: Stack(
                children: [
                  article.coverImage != null && article.coverImage!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: article.coverImage!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            height: 160,
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            child: const Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2)),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            height: 160,
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            child: const Icon(Icons.image_not_supported_rounded,
                                color: AppTheme.primary, size: 40),
                          ),
                        )
                      : Container(
                          height: 160,
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          child: Center(
                            child: Icon(Icons.article_rounded,
                                color:
                                    AppTheme.primary.withValues(alpha: 0.4),
                                size: 48),
                          ),
                        ),
                  // Premium badge
                  if (article.isPremium)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: AppTheme.premiumGradient,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.workspace_premium_rounded,
                                size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Premium',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  // Bookmark icon
                  if (ApiService.isLoggedIn)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => context
                            .read<EducationBloc>()
                            .add(EducationToggleBookmark(article.id)),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            article.isBookmarked
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            size: 18,
                            color: article.isBookmarked
                                ? AppTheme.warning
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  if (article.categoryName != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        article.categoryName!,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary),
                      ),
                    ),

                  // Title
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        height: 1.3),
                  ),
                  const SizedBox(height: 6),

                  // Excerpt
                  if (article.excerpt != null)
                    Text(
                      article.excerpt!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary.withValues(alpha: 0.8),
                          height: 1.4),
                    ),
                  const SizedBox(height: 10),

                  // Meta info
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 14,
                          color:
                              AppTheme.textHint.withValues(alpha: 0.6)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          article.authorName ?? 'Admin',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textHint
                                  .withValues(alpha: 0.7)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.schedule_rounded,
                          size: 14,
                          color:
                              AppTheme.textHint.withValues(alpha: 0.6)),
                      const SizedBox(width: 4),
                      Text(
                        '${article.readTimeMin ?? 5} menit baca',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textHint
                                .withValues(alpha: 0.7)),
                      ),
                      if (dateStr.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.calendar_today_rounded,
                            size: 13,
                            color: AppTheme.textHint
                                .withValues(alpha: 0.6)),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textHint
                                  .withValues(alpha: 0.7)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Empty State ────────────────────────────────────────────────────────

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
            child: Icon(Icons.article_outlined,
                size: 48,
                color: AppTheme.textHint.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 16),
          const Text('Belum ada artikel',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Text('Artikel terbaru akan muncul di sini',
              style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textHint.withValues(alpha: 0.7))),
        ],
      ),
    );
  }

  // ─── Skeleton Loader ────────────────────────────────────────────────────

  Widget _buildSkeletonList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => _buildSkeletonCard(),
    );
  }

  Widget _buildSkeletonCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusMd)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 20,
                    width: 80,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 18,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 14,
                    width: 200,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 12,
                    width: 150,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Login Prompt ───────────────────────────────────────────────────────

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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bookmark_rounded,
                  size: 32, color: AppTheme.primary),
            ),
            const SizedBox(height: 16),
            const Text('Login untuk menyimpan artikel',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Simpan artikel favorit agar bisa dibaca kapan saja',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
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
