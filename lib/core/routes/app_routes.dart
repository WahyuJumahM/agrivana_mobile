// Location: agrivana\lib\core\routes\app_routes.dart
import 'package:flutter/material.dart';
import '../../features/auth/view/splash_screen.dart';
import '../../features/auth/view/onboarding_screen.dart';
import '../../features/auth/view/login_screen.dart';
import '../../features/auth/view/register_screen.dart';
import '../../features/auth/view/otp_screen.dart';
import '../../features/auth/view/forgot_password_screen.dart';
import '../../features/home/view/main_wrapper.dart';
import '../../features/shop/view/product_detail_screen.dart';
import '../../features/education/view/article_detail_screen.dart';
import '../../features/education/view/article_bookmarks_screen.dart';
import '../../features/community/view/post_detail_screen.dart';
import '../../features/community/view/create_post_screen.dart';
import '../../features/community/view/community_screen.dart';
import '../../features/shop/view/checkout_screen.dart';
import '../../features/shop/view/order_list_screen.dart';
import '../../features/profile/view/edit_profile_screen.dart';
import '../../features/profile/view/address_screen.dart';
import '../../features/shop/view/wishlist_screen.dart';
import '../../features/profile/view/notification_screen.dart';
import '../../features/profile/view/change_password_screen.dart';
import '../../features/chatbot/view/chatbot_screen.dart';
import '../../features/plant/view/plant_tracking_screen.dart';
import '../../features/plant/view/ai_scan_screen.dart';
import '../../features/profile/view/subscription_screen.dart';
import '../../features/profile/view/seller_dashboard_screen.dart';
import '../../features/shop/view/chat_list_screen.dart';
import '../../features/shop/view/chat_conversation_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const otp = '/otp';
  static const forgotPassword = '/forgot-password';
  static const main = '/main';
  static const productDetail = '/product-detail';
  static const articleDetail = '/article-detail';
  static const articleBookmarks = '/article-bookmarks';
  static const postDetail = '/post-detail';
  static const checkout = '/checkout';
  static const orderList = '/orders';
  static const editProfile = '/edit-profile';
  static const addresses = '/addresses';
  static const wishlist = '/wishlist';
  static const notifications = '/notifications';
  static const changePassword = '/change-password';
  static const chatbot = '/chatbot';
  static const plantTracking = '/plant-tracking';
  static const aiScan = '/ai-scan';
  static const subscription = '/subscription';
  static const sellerDashboard = '/seller-dashboard';
  static const chatList = '/chat-list';
  static const chatConversation = '/chat-conversation';

  static const createPost = '/create-post';
  static const community = '/community';

  static Map<String, WidgetBuilder> get routes => {
        splash: (_) => const SplashScreen(),
        onboarding: (_) => const OnboardingScreen(),
        login: (_) => const LoginScreen(),
        register: (_) => const RegisterScreen(),
        otp: (_) => const OtpScreen(),
        forgotPassword: (_) => const ForgotPasswordScreen(),
        main: (_) => const MainWrapper(),
        productDetail: (_) => const ProductDetailScreen(),
        articleDetail: (_) => const ArticleDetailScreen(),
        articleBookmarks: (_) => const ArticleBookmarksScreen(),
        postDetail: (_) => const PostDetailScreen(),
        createPost: (_) => const CreatePostScreen(),
        community: (_) => const CommunityScreen(),
        checkout: (_) => const CheckoutScreen(),
        orderList: (_) => const OrderListScreen(),
        editProfile: (_) => const EditProfileScreen(),
        addresses: (_) => const AddressScreen(),
        wishlist: (_) => const WishlistScreen(),
        notifications: (_) => const NotificationScreen(),
        changePassword: (_) => const ChangePasswordScreen(),
        chatbot: (_) => const ChatbotScreen(),
        plantTracking: (_) => const PlantTrackingScreen(),
        aiScan: (_) => const AiScanScreen(),
        subscription: (_) => const SubscriptionScreen(),
        sellerDashboard: (_) => const SellerDashboardScreen(),
        chatList: (_) => const ChatListScreen(),
        chatConversation: (_) => const ChatConversationScreen(),
      };
}
