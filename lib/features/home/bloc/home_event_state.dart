// Location: agrivana\lib\features\home\bloc\home_event_state.dart
import 'package:equatable/equatable.dart';
import '../model/banner_model.dart';
import '../../shop/model/product_model.dart';
import '../../education/model/article_model.dart';
import '../../plant/model/plant_model.dart';
import '../../community/model/community_model.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object?> get props => [];
}

class HomeLoadDashboard extends HomeEvent {}

// ─── States ────────────────────────────────────────────────────────────

abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}
class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<BannerModel> banners;
  final List<ProductModel> products;
  final List<ArticleModel> articles;
  final List<UserPlantModel> plants;
  final List<CommunityPost> communityPosts;
  final List<CareScheduleModel> todaySchedules;

  const HomeLoaded({
    this.banners = const [],
    this.products = const [],
    this.articles = const [],
    this.plants = const [],
    this.communityPosts = const [],
    this.todaySchedules = const [],
  });

  @override
  List<Object?> get props => [banners, products, articles, plants, communityPosts, todaySchedules];
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);
  @override
  List<Object?> get props => [message];
}
