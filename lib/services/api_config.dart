// Location: agrivana\lib\services\api_config.dart
class ApiConfig {
  static const String baseUrl = 'http://agrivana.runasp.net';

  //Cloudinary
  static const String cloudName = 'agrivana';
  static const String profilePreset = 'photo_profiles';
  static const String productPreset = 'products';
  static const String marketPreset = 'profiles_market';
  static const String plantPreset = 'plants';
  static const String plantLogPreset = 'plant_logs';
  static const String otherPreset = 'others';

  // ─── Auth (9 endpoints) ──────────────────────────────────────────
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String verifyOtp = '/api/auth/verify-otp';
  static const String resendOtp = '/api/auth/resend-otp';
  static const String refresh = '/api/auth/refresh';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String resetPassword = '/api/auth/reset-password';
  static const String logout = '/api/auth/logout';
  static const String logoutAll = '/api/auth/logout-all';

  // ─── User (12 endpoints) ─────────────────────────────────────────
  static const String userMe = '/api/users/me';
  static const String changePassword = '/api/users/me/change-password';
  static const String fcmToken = '/api/users/me/fcm-token';
  static const String addresses = '/api/users/me/addresses';
  static const String wishlist = '/api/users/me/wishlist';
  static const String notifications = '/api/users/me/notifications';
  static const String notificationsRead = '/api/users/me/notifications/read';
  static const String reviews = '/api/users/me/reviews';

  // ─── Marketplace (5 endpoints) ───────────────────────────────────
  static const String products = '/api/marketplace/products';
  static const String categories = '/api/marketplace/categories';
  static const String stores = '/api/marketplace/stores';

  // ─── Orders (5 endpoints) ────────────────────────────────────────
  static const String checkout = '/api/orders/checkout';
  static const String orders = '/api/orders';
  static const String shippingCost = '/api/orders/shipping-cost';

  // ─── OpenWeatherMap (1 endpoint) ─────────────────────────────────
  static const String openWeatherMapKey = '340f879d63b160eba8da8883970c42f9';

  // ─── Seller (8 endpoints) ────────────────────────────────────────
  static const String sellerStore = '/api/seller/store';
  static const String sellerStoreLocation = '/api/seller/store/location';
  static const String sellerOrders = '/api/seller/orders';
  static const String sellerProducts = '/api/seller/products';
  static const String sellerReports = '/api/seller/reports/summary';
  static const String sellerWithdraw = '/api/seller/withdraw';
  static const String sellerReviews = '/api/seller/reviews';

  // ─── Subscriptions (2 endpoints) ─────────────────────────────────
  static const String subscriptionPlans = '/api/subscriptions/plans';
  static const String subscriptionMy = '/api/subscriptions/my';

  // ─── Plant Categories & Hierarchy ────────────────────────────────
  static const String plantCategories = '/api/plant-categories';

  // ─── Plants (CRUD + Logs + Schedules) ────────────────────────────
  static const String plants = '/api/plants';
  static const String plantTypes = '/api/plants/types';
  static const String plantSummary = '/api/plants/summary';

  // ─── AI Scan (5 endpoints) ───────────────────────────────────────
  static const String scan = '/api/scan';
  static const String scanHistory = '/api/scan/history';
  static const String scanAvailablePlants = '/api/scan/available-plants';

  // ─── Chatbot (3 endpoints) ───────────────────────────────────────
  static const String chatMessage = '/api/chatbot/message';
  static const String chatHistory = '/api/chatbot/history';
  static const String chatClear = '/api/chatbot/session';

  // ─── Community (11 endpoints) ────────────────────────────────────
  static const String communityChannels = '/api/community/channels';
  static const String communityPosts = '/api/community/posts';
  static const String communityUsers = '/api/community/users';
  static const String communityReport = '/api/community/report';

  // ─── Articles (9 endpoints) ──────────────────────────────────────
  static const String articles = '/api/articles';
  static const String articleCategories = '/api/articles/categories';
  static const String articleBookmarks = '/api/articles/bookmarks';
  static const String learningPaths = '/api/articles/learning-paths';

  // ─── Banners (3 endpoints) ───────────────────────────────────────
  static const String bannersActive = '/api/banners/active';

  // ─── User Chat (4 endpoints) ─────────────────────────────────────
  static const String chatConversations = '/api/chat/conversations';

  // ─── Today Notifications ─────────────────────────────────────────
  static const String todaySchedules = '/api/notifications/today';
}
