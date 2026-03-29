// Location: agrivana\lib\features\home\bloc\home_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_event_state.dart';
import '../model/banner_model.dart';
import '../../shop/model/product_model.dart';
import '../../education/model/article_model.dart';
import '../../shop/service/marketplace_service.dart';
import '../../education/service/article_service.dart';
import '../../profile/service/profile_services.dart';
import '../../plant/model/plant_model.dart';
import '../../plant/service/plant_service.dart';
import '../../community/model/community_model.dart';
import '../../community/service/community_service.dart';
import '../../../services/api_service.dart';
import '../../../services/api_config.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeInitial()) {
    on<HomeLoadDashboard>(_onLoad);
  }

  Future<void> _onLoad(HomeLoadDashboard event, Emitter<HomeState> emit) async {
    emit(HomeLoading());

    List<BannerModel> banners = [];
    List<ProductModel> products = [];
    List<ArticleModel> articles = [];
    List<UserPlantModel> plants = [];
    List<CommunityPost> communityPosts = [];
    List<CareScheduleModel> todaySchedules = [];

    await Future.wait([
      _loadBanners().then((v) => banners = v),
      _loadProducts().then((v) => products = v),
      _loadArticles().then((v) => articles = v),
      _loadPlants().then((v) => plants = v),
      _loadCommunityPosts().then((v) => communityPosts = v),
      _loadTodaySchedules().then((v) => todaySchedules = v),
    ]);

    emit(HomeLoaded(
      banners: banners,
      products: products,
      articles: articles,
      plants: plants,
      communityPosts: communityPosts,
      todaySchedules: todaySchedules,
    ));
  }

  Future<List<BannerModel>> _loadBanners() async {
    final result = await BannerService.getActiveBanners();
    if (result.success && result.data != null) {
      final list = result.data is List ? result.data : [];
      return list.map<BannerModel>((j) => BannerModel.fromJson(j)).toList();
    }
    return [];
  }

  Future<List<ProductModel>> _loadProducts() async {
    final result = await MarketplaceService.getProducts(query: {'sort': 'terlaris', 'pageSize': '5'});
    if (result.success && result.data != null) {
      final items = result.data['items'] ?? result.data;
      if (items is List) {
        return items.map<ProductModel>((j) => ProductModel.fromJson(j)).toList();
      }
    }
    return [];
  }

  Future<List<ArticleModel>> _loadArticles() async {
    final result = await ArticleService.getArticles(query: {'pageSize': '5'});
    if (result.success && result.data != null) {
      final items = result.data['items'] ?? result.data;
      if (items is List) {
        return items.map<ArticleModel>((j) => ArticleModel.fromJson(j)).toList();
      }
    }
    return [];
  }

  Future<List<UserPlantModel>> _loadPlants() async {
    try {
      return await PlantService.getUserPlants();
    } catch (_) {
      return [];
    }
  }

  Future<List<CommunityPost>> _loadCommunityPosts() async {
    try {
      final result = await CommunityService.getPosts(query: {'pageSize': '3'});
      if (result.success && result.data != null) {
        final items = result.data['items'] ?? result.data;
        if (items is List) {
          return items.map<CommunityPost>((j) => CommunityPost.fromJson(j)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  Future<List<CareScheduleModel>> _loadTodaySchedules() async {
    try {
      final result = await ApiService.get(ApiConfig.todaySchedules, auth: true);
      if (result.success && result.data != null) {
        final items = result.data is List ? result.data : (result.data['items'] ?? []);
        if (items is List) {
          return items.map<CareScheduleModel>((j) => CareScheduleModel.fromJson(j)).toList();
        }
      }
    } catch (_) {}
    return [];
  }
}
