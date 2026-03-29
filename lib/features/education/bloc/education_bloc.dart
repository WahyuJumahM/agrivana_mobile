// Location: agrivana\lib\features\education\bloc\education_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../model/article_model.dart';
import '../service/article_service.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class EducationEvent extends Equatable {
  const EducationEvent();
  @override
  List<Object?> get props => [];
}

class EducationLoadData extends EducationEvent {}

class EducationSelectCategory extends EducationEvent {
  final String? categoryId;
  const EducationSelectCategory(this.categoryId);
  @override
  List<Object?> get props => [categoryId];
}

class EducationSearchChanged extends EducationEvent {
  final String query;
  const EducationSearchChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class EducationLoadMore extends EducationEvent {}

class EducationToggleBookmark extends EducationEvent {
  final String articleId;
  const EducationToggleBookmark(this.articleId);
  @override
  List<Object?> get props => [articleId];
}

class EducationLoadBookmarks extends EducationEvent {}

class EducationRefresh extends EducationEvent {}

// ─── States ──────────────────────────────────────────────────────────────────

abstract class EducationState extends Equatable {
  const EducationState();
  @override
  List<Object?> get props => [];
}

class EducationInitial extends EducationState {}

class EducationLoading extends EducationState {}

class EducationLoaded extends EducationState {
  final List<ArticleModel> articles;
  final List<ContentCategoryModel> categories;
  final String? selectedCategoryId;
  final String searchQuery;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final List<ArticleModel> bookmarks;
  final bool isLoadingBookmarks;
  final String? errorMessage;

  const EducationLoaded({
    this.articles = const [],
    this.categories = const [],
    this.selectedCategoryId,
    this.searchQuery = '',
    this.currentPage = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.bookmarks = const [],
    this.isLoadingBookmarks = false,
    this.errorMessage,
  });

  EducationLoaded copyWith({
    List<ArticleModel>? articles,
    List<ContentCategoryModel>? categories,
    String? selectedCategoryId,
    bool clearCategory = false,
    String? searchQuery,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    List<ArticleModel>? bookmarks,
    bool? isLoadingBookmarks,
    String? errorMessage,
    bool clearError = false,
  }) {
    return EducationLoaded(
      articles: articles ?? this.articles,
      categories: categories ?? this.categories,
      selectedCategoryId: clearCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      bookmarks: bookmarks ?? this.bookmarks,
      isLoadingBookmarks: isLoadingBookmarks ?? this.isLoadingBookmarks,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        articles, categories, selectedCategoryId, searchQuery,
        currentPage, hasMore, isLoadingMore, bookmarks, isLoadingBookmarks, errorMessage,
      ];
}

class EducationError extends EducationState {
  final String message;
  const EducationError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── Bloc ────────────────────────────────────────────────────────────────────

class EducationBloc extends Bloc<EducationEvent, EducationState> {
  EducationBloc() : super(EducationInitial()) {
    on<EducationLoadData>(_onLoad);
    on<EducationSelectCategory>(_onSelectCategory);
    on<EducationSearchChanged>(_onSearchChanged);
    on<EducationLoadMore>(_onLoadMore);
    on<EducationToggleBookmark>(_onToggleBookmark);
    on<EducationLoadBookmarks>(_onLoadBookmarks);
    on<EducationRefresh>(_onRefresh);
  }

  List<ContentCategoryModel> _cachedCategories = [];
  Timer? _searchDebounce;
  static const int _pageSize = 10;

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }

  // ─── Load initial data ─────────────────────────────────────────────────

  Future<void> _onLoad(EducationLoadData event, Emitter<EducationState> emit) async {
    emit(EducationLoading());

    // Load categories (cache them)
    if (_cachedCategories.isEmpty) {
      final catResult = await ArticleService.getCategories();
      if (catResult.success && catResult.data != null) {
        final list = catResult.data is List ? catResult.data : [];
        _cachedCategories = list
            .map<ContentCategoryModel>((j) => ContentCategoryModel.fromJson(j))
            .toList();
      }
    }

    // Load first page of articles
    final articles = await _fetchArticles(page: 1);

    emit(EducationLoaded(
      articles: articles ?? [],
      categories: _cachedCategories,
      currentPage: 1,
      hasMore: (articles?.length ?? 0) >= _pageSize,
    ));
  }

  // ─── Select category ──────────────────────────────────────────────────

  Future<void> _onSelectCategory(
      EducationSelectCategory event, Emitter<EducationState> emit) async {
    final current = state;
    if (current is! EducationLoaded) return;

    emit(current.copyWith(
      selectedCategoryId: event.categoryId,
      clearCategory: event.categoryId == null,
      isLoadingMore: true,
      articles: [],
    ));

    final articles = await _fetchArticles(
      page: 1,
      categoryId: event.categoryId,
      search: current.searchQuery.isNotEmpty ? current.searchQuery : null,
    );

    emit(EducationLoaded(
      articles: articles ?? [],
      categories: _cachedCategories,
      selectedCategoryId: event.categoryId,
      searchQuery: current.searchQuery,
      currentPage: 1,
      hasMore: (articles?.length ?? 0) >= _pageSize,
    ));
  }

  // ─── Search with debounce ──────────────────────────────────────────────

  Future<void> _onSearchChanged(
      EducationSearchChanged event, Emitter<EducationState> emit) async {
    _searchDebounce?.cancel();

    final current = state;
    if (current is! EducationLoaded) return;

    final completer = Completer<void>();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      final articles = await _fetchArticles(
        page: 1,
        categoryId: current.selectedCategoryId,
        search: event.query.isNotEmpty ? event.query : null,
      );

      if (!emit.isDone) {
        emit(current.copyWith(
          articles: articles ?? [],
          searchQuery: event.query,
          currentPage: 1,
          hasMore: (articles?.length ?? 0) >= _pageSize,
          isLoadingMore: false,
        ));
      }
      completer.complete();
    });

    await completer.future;
  }

  // ─── Load more (infinite scroll) ───────────────────────────────────────

  Future<void> _onLoadMore(EducationLoadMore event, Emitter<EducationState> emit) async {
    final current = state;
    if (current is! EducationLoaded || current.isLoadingMore || !current.hasMore) return;

    emit(current.copyWith(isLoadingMore: true));

    final nextPage = current.currentPage + 1;
    final articles = await _fetchArticles(
      page: nextPage,
      categoryId: current.selectedCategoryId,
      search: current.searchQuery.isNotEmpty ? current.searchQuery : null,
    );

    emit(current.copyWith(
      articles: [...current.articles, ...(articles ?? [])],
      currentPage: nextPage,
      hasMore: (articles?.length ?? 0) >= _pageSize,
      isLoadingMore: false,
    ));
  }

  // ─── Bookmark toggle ──────────────────────────────────────────────────

  Future<void> _onToggleBookmark(
      EducationToggleBookmark event, Emitter<EducationState> emit) async {
    final current = state;
    if (current is! EducationLoaded) return;

    // Optimistic update
    final updatedArticles = current.articles.map((a) {
      if (a.id == event.articleId) {
        return a.copyWith(isBookmarked: !a.isBookmarked);
      }
      return a;
    }).toList();

    emit(current.copyWith(articles: updatedArticles));

    // Make API call
    final result = await ArticleService.toggleBookmark(event.articleId);

    if (!result.success) {
      // Rollback on failure
      emit(current.copyWith(
        articles: current.articles,
        errorMessage: result.message,
      ));
    }
  }

  // ─── Load bookmarks ───────────────────────────────────────────────────

  Future<void> _onLoadBookmarks(
      EducationLoadBookmarks event, Emitter<EducationState> emit) async {
    final current = state;
    if (current is EducationLoaded) {
      emit(current.copyWith(isLoadingBookmarks: true));
    }

    final result = await ArticleService.getBookmarks();
    List<ArticleModel> bookmarks = [];
    if (result.success && result.data != null) {
      final items = result.data is List ? result.data : [];
      bookmarks = items.map<ArticleModel>((j) => ArticleModel.fromJson(j)).toList();
    }

    if (current is EducationLoaded) {
      emit(current.copyWith(bookmarks: bookmarks, isLoadingBookmarks: false));
    }
  }

  // ─── Refresh ───────────────────────────────────────────────────────────

  Future<void> _onRefresh(EducationRefresh event, Emitter<EducationState> emit) async {
    final current = state;
    if (current is! EducationLoaded) return;

    final articles = await _fetchArticles(
      page: 1,
      categoryId: current.selectedCategoryId,
      search: current.searchQuery.isNotEmpty ? current.searchQuery : null,
    );

    emit(current.copyWith(
      articles: articles ?? [],
      currentPage: 1,
      hasMore: (articles?.length ?? 0) >= _pageSize,
    ));
  }

  // ─── Helper ────────────────────────────────────────────────────────────

  Future<List<ArticleModel>?> _fetchArticles({
    required int page,
    String? categoryId,
    String? search,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'pageSize': _pageSize.toString(),
    };
    if (categoryId != null) query['categoryId'] = categoryId;
    if (search != null && search.isNotEmpty) query['search'] = search;

    final result = await ArticleService.getArticles(query: query);
    if (result.success && result.data != null) {
      final data = result.data;
      List items;
      if (data is Map && data.containsKey('items')) {
        items = data['items'] ?? [];
      } else if (data is List) {
        items = data;
      } else {
        items = [];
      }
      return items.map<ArticleModel>((j) => ArticleModel.fromJson(j)).toList();
    }
    return null;
  }
}
