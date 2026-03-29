// Location: agrivana\lib\main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'utils/dialogs.dart';
import 'services/api_service.dart';

// BLoCs
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/home/bloc/home_bloc.dart';
import 'features/shop/bloc/shop_bloc.dart';
import 'features/plant/bloc/plant_bloc.dart';
import 'features/education/bloc/education_bloc.dart';
import 'features/profile/bloc/profile_bloc.dart';
import 'features/community/bloc/community_bloc.dart';
import 'features/chatbot/bloc/chatbot_bloc.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const AgrivanaApp());
}

class AgrivanaApp extends StatefulWidget {
  const AgrivanaApp({super.key});
  @override
  State<AgrivanaApp> createState() => _AgrivanaAppState();
}

class _AgrivanaAppState extends State<AgrivanaApp> {
  late StreamSubscription _sessionSub;

  @override
  void initState() {
    super.initState();
    // Listen for session expiry from ApiService
    _sessionSub = ApiService.onSessionExpired.stream.listen((_) {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
    });
  }

  @override
  void dispose() {
    _sessionSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => AuthBloc()..add(AuthCheckSession())),
        BlocProvider<HomeBloc>(create: (_) => HomeBloc()),
        BlocProvider<ShopBloc>(create: (_) => ShopBloc()),
        BlocProvider<ProductDetailBloc>(create: (_) => ProductDetailBloc()),
        BlocProvider<OrderBloc>(create: (_) => OrderBloc()),
        BlocProvider<PlantBloc>(create: (_) => PlantBloc()),
        BlocProvider<EducationBloc>(create: (_) => EducationBloc()),
        BlocProvider<ProfileBloc>(create: (ctx) => ProfileBloc(authBloc: ctx.read<AuthBloc>())),
        BlocProvider<SellerBloc>(create: (_) => SellerBloc()),
        BlocProvider<CommunityBloc>(create: (_) => CommunityBloc()),
        BlocProvider<ChatbotBloc>(create: (_) => ChatbotBloc()),
      ],
      child: MaterialApp(
        title: 'Agrivana',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        navigatorKey: navigatorKey,
        initialRoute: AppRoutes.splash,
        routes: AppRoutes.routes,
      ),
    );
  }
}
