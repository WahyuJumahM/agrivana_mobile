// Location: agrivana\lib\features\home\view\home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../services/weather_service.dart';

import '../bloc/home_bloc.dart';
import '../bloc/home_event_state.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../plant/view/plant_detail_screen.dart';
import '../../plant/model/plant_model.dart';
import '../../shop/model/product_model.dart';
import '../../education/model/article_model.dart';
import '../../community/model/community_model.dart';
import 'main_wrapper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _weatherData;
  int _bannerIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(HomeLoadDashboard());
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      ).timeout(const Duration(seconds: 5));
      final data = await WeatherService.getCurrentWeather(
        pos.latitude,
        pos.longitude,
      );
      if (data != null && mounted) {
        setState(() => _weatherData = data);
      }
    } catch (_) {}
  }

  void _switchTab(int index) {
    MainWrapperScope.of(context)?.switchTab(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () async {
            context.read<HomeBloc>().add(HomeLoadDashboard());
            _fetchWeather();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                // ─── 1. HEADER ───────────────────────────────────
                _buildHeader(),
                const SizedBox(height: 4),
                // ─── Greeting ────────────────────────────────────
                _buildGreeting(),
                const SizedBox(height: 16),
                // ─── 2. SEARCH BAR ───────────────────────────────
                _buildSearchBar(),
                const SizedBox(height: 16),
                // ─── 3. STATUS CARDS ─────────────────────────────
                _buildStatusCards(),
                const SizedBox(height: 20),
                // ─── 4. FEATURE MENU ─────────────────────────────
                _buildFeatureMenu(),
                const SizedBox(height: 24),
                // ─── 5. TANAMAN ANDA ─────────────────────────────
                _buildSectionHeader('Tanaman Anda', () {
                  _switchTab(2);
                }),
                const SizedBox(height: 12),
                _buildPlantsSection(),
                const SizedBox(height: 24),
                // ─── 6. INFO TERBARU (CAROUSEL) ──────────────────
                _buildSectionHeaderNoPad('Info Terbaru', null),
                const SizedBox(height: 12),
                _buildBannerCarousel(),
                const SizedBox(height: 24),
                // ─── 7. PENUHI SEGALA KEBUTUHANMU ────────────────
                _buildSectionHeader('Penuhi Segala Kebutuhanmu', () {
                  _switchTab(1);
                }),
                const SizedBox(height: 12),
                _buildProductsSection(),
                const SizedBox(height: 24),
                // ─── 8. EDUKASI TERBARU ──────────────────────────
                _buildSectionHeader('Edukasi Terbaru', () {
                  _switchTab(3);
                }),
                const SizedBox(height: 12),
                _buildEducationSection(),
                const SizedBox(height: 24),
                // ─── 9. FORUM DISKUSI ────────────────────────────
                _buildSectionHeader('Forum diskusi Terkini Komunitas', () {
                  Navigator.of(context).pushNamed(AppRoutes.community);
                }),
                const SizedBox(height: 12),
                _buildForumSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 1. HEADER
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Image.asset(
            'assets/images/main_feature/logo-home.png',
            height: 48,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.eco_rounded,
              color: AppTheme.primary,
              size: 32,
            ),
          ),
          const Spacer(),
          // Notification bell
          GestureDetector(
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.notifications),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: AppTheme.textPrimary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Profile avatar
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final photoUrl = state is AuthAuthenticated
                  ? state.user.profilePhoto
                  : null;
              return GestureDetector(
                onTap: () => _switchTab(4),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                  backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                      ? CachedNetworkImageProvider(photoUrl)
                      : null,
                  child: photoUrl == null || photoUrl.isEmpty
                      ? const Icon(
                          Icons.person,
                          size: 20,
                          color: AppTheme.primary,
                        )
                      : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // GREETING
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildGreeting() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final name = state is AuthAuthenticated
              ? state.user.name
              : 'Pengguna';
          return Text(
            'Selamat datang, $name 👋',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 2. SEARCH BAR
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => _switchTab(1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFEEEEEE),
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: AppTheme.textHint, size: 20),
              SizedBox(width: 10),
              Text(
                'Cari produk',
                style: TextStyle(fontSize: 14, color: AppTheme.textHint),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 3. STATUS CARDS
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildStatusCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Plant status card
          Expanded(
            child: BlocBuilder<HomeBloc, HomeState>(
              builder: (context, state) {
                String statusText = 'Memuat...';
                if (state is HomeLoaded) {
                  if (state.todaySchedules.isNotEmpty) {
                    final s = state.todaySchedules.first;
                    statusText =
                        '${s.careTypeIcon} ${s.careTypeLabel} ${s.plantName ?? ''}';
                  } else if (state.plants.isNotEmpty) {
                    statusText = '${state.plants.length} tanaman aktif';
                  } else {
                    statusText = 'Tidak ada aktivitas';
                  }
                }
                return _statusCard(
                  icon: Icons.eco_rounded,
                  label: 'Status Tumbuhan',
                  value: statusText,
                  bgColor: const Color(0xFFE8F5E9),
                  iconColor: AppTheme.primary,
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          // Weather card
          Expanded(
            child: _statusCard(
              icon: Icons.wb_sunny_rounded,
              label: _weatherData != null
                  ? 'Cuaca - ${_weatherData!['name'] ?? ''}'
                  : 'Cuaca',
              value: _weatherData != null
                  ? '$_weatherDescription ${_weatherTemp.toStringAsFixed(0)}° C'
                  : 'Memuat...',
              bgColor: const Color(0xFFE3F2FD),
              iconColor: const Color(0xFF1976D2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCard({
    required IconData icon,
    required String label,
    required String value,
    required Color bgColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 4. FEATURE MENU
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildFeatureMenu() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _featureItem(
            Icons.document_scanner_rounded,
            'Scan\nTanaman',
            const Color(0xFFE8F5E9),
            AppTheme.primary,
            () => Navigator.of(context).pushNamed(AppRoutes.aiScan),
          ),
          _featureItem(
            Icons.track_changes_rounded,
            'Tracking\nTanaman',
            const Color(0xFFE3F2FD),
            const Color(0xFF1976D2),
            () => _switchTab(2),
          ),
          _featureItem(
            Icons.storefront_rounded,
            'Jual\nTanaman',
            const Color(0xFFFFF3E0),
            const Color(0xFFE65100),
            () => Navigator.of(context).pushNamed(AppRoutes.sellerDashboard),
          ),
          _featureItem(
            Icons.groups_rounded,
            'Komunitas\nTanaman',
            const Color(0xFFF3E5F5),
            const Color(0xFF7B1FA2),
            () => Navigator.of(context).pushNamed(AppRoutes.community),
          ),
        ],
      ),
    );
  }

  Widget _featureItem(
    IconData icon,
    String label,
    Color bg,
    Color fg,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 26, color: fg),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 5. TANAMAN ANDA
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildPlantsSection() {
    return SizedBox(
      height: 180,
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) return _shimmerHorizontalList();
          if (state is HomeLoaded && state.plants.isNotEmpty) {
            return ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: state.plants.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _plantCard(state.plants[i]),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                image: const DecorationImage(
                  image: AssetImage('assets/images/main_feature/banner-1.png'),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.95),
                      const Color(0xFF1B5E20).withValues(alpha: 0.85),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('🪴', style: TextStyle(fontSize: 34)),
                          ),
                        ),
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFCA28),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFFCA28,
                                  ).withValues(alpha: 0.5),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'MULAI BERTANI!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Ayo Tanam Pertamamu!',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'pemula? Jangan takut!',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _switchTab(2),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Mulai Tracking',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF2E7D32,
                                      ).withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 10,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _plantCard(UserPlantModel plant) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PlantDetailScreen(plantId: plant.id)),
      ),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: AppTheme.softShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              plant.coverPhoto != null
                  ? CachedNetworkImage(
                      imageUrl: plant.coverPhoto!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        child: Center(
                          child: Text(
                            plant.plantIcon ?? '🌱',
                            style: const TextStyle(fontSize: 36),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      child: Center(
                        child: Text(
                          plant.plantIcon ?? '🌱',
                          style: const TextStyle(fontSize: 36),
                        ),
                      ),
                    ),
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
              // Bottom content
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      plant.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Health badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.eco,
                                size: 12,
                                color: Colors.greenAccent,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                plant.health == 'healthy'
                                    ? '100%'
                                    : plant.health == 'needs_attention'
                                    ? '60%'
                                    : '30%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 6. BANNER CAROUSEL
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildBannerCarousel() {
    final bannerAssets = [
      'assets/images/main_feature/banner-1.png',
      'assets/images/main_feature/banner-2.png',
      'assets/images/main_feature/banner-3.png',
    ];

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: bannerAssets.length,
          options: CarouselOptions(
            height: 160,
            viewportFraction: 0.92,
            enlargeCenterPage: true,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 600),
            onPageChanged: (index, _) {
              setState(() => _bannerIndex = index);
            },
          ),
          itemBuilder: (context, index, _) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                boxShadow: AppTheme.softShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: Image.asset(
                  bannerAssets[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(
                        Icons.image,
                        size: 40,
                        color: AppTheme.textHint,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        // Dot indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            bannerAssets.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _bannerIndex == i ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _bannerIndex == i
                    ? AppTheme.primary
                    : const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 7. PRODUCTS SECTION
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildProductsSection() {
    return SizedBox(
      height: 230,
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) return _shimmerHorizontalList();
          if (state is HomeLoaded && state.products.isNotEmpty) {
            final shown = state.products.take(5).toList();
            return ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: shown.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _productCard(shown[i]),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: const Center(
                child: Text(
                  'Belum ada produk',
                  style: TextStyle(color: AppTheme.textHint),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _productCard(ProductModel product) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(
        AppRoutes.productDetail,
        arguments: {'productId': product.id},
      ),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusMd),
                topRight: Radius.circular(AppTheme.radiusMd),
              ),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: product.allImageUrls.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.allImageUrls.first,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: Colors.grey[100],
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.grey[100],
                          child: const Icon(
                            Icons.image,
                            color: AppTheme.textHint,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[100],
                        child: const Center(
                          child: Icon(
                            Icons.shopping_bag_outlined,
                            size: 36,
                            color: AppTheme.textHint,
                          ),
                        ),
                      ),
              ),
            ),
            // Product info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (product.storeName != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.storefront,
                            size: 10,
                            color: AppTheme.textHint,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              product.storeName!,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.textHint,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 12,
                          color: AppTheme.warning,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        if (product.city != null) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.location_on_outlined,
                            size: 11,
                            color: AppTheme.textHint,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              product.city!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppTheme.textHint,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp. ${_formatPrice(product.price)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 8. EDUKASI SECTION
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildEducationSection() {
    return SizedBox(
      height: 130,
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) return _shimmerHorizontalList(height: 130);
          if (state is HomeLoaded && state.articles.isNotEmpty) {
            final shown = state.articles.take(5).toList();
            return ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: shown.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _educationCard(shown[i]),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _educationCard(ArticleModel article) {
    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).pushNamed(AppRoutes.articleDetail, arguments: {'slug': article.slug}),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: AppTheme.softShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Cover image
              article.coverImage != null
                  ? CachedNetworkImage(
                      imageUrl: article.coverImage!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: Colors.grey[200]),
                      errorWidget: (_, __, ___) => Container(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        child: const Icon(
                          Icons.article,
                          color: AppTheme.primary,
                        ),
                      ),
                    )
                  : Container(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      child: const Icon(Icons.article, color: AppTheme.primary),
                    ),
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),
              // Title
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Text(
                  article.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // 9. FORUM SECTION
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildForumSection() {
    return SizedBox(
      height: 200,
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) return _shimmerHorizontalList(height: 200);
          if (state is HomeLoaded && state.communityPosts.isNotEmpty) {
            return ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: state.communityPosts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _forumCard(state.communityPosts[i]),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: const Center(
                child: Text(
                  'Belum ada diskusi',
                  style: TextStyle(color: AppTheme.textHint, fontSize: 13),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _forumCard(CommunityPost post) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(AppRoutes.postDetail, arguments: {'postId': post.id}),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                  backgroundImage: post.authorPhoto != null ? CachedNetworkImageProvider(post.authorPhoto!) : null,
                  child: post.authorPhoto == null ? const Icon(Icons.person, size: 14, color: AppTheme.primary) : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    post.authorName ?? 'Anonim',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (post.channelName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      post.channelName!,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primary),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              post.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary, height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (post.body.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                post.body,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const Spacer(),
            if (post.plantTags != null && post.plantTags!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: post.plantTags!.take(3).map((tag) => Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tag.startsWith('#') ? tag : '#$tag',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF616161), fontWeight: FontWeight.w500),
                    ),
                  )).toList(),
                ),
              ),
            Row(
              children: [
                Icon(Icons.thumb_up_alt_rounded, size: 13, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text('${post.likeCount}', style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                Icon(Icons.chat_bubble_rounded, size: 13, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text('${post.commentCount}', style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                Icon(Icons.visibility_rounded, size: 13, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text('${post.viewCount}', style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                const Spacer(),
                if (post.isAnswered)
                  const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.success),
                      SizedBox(width: 4),
                      Text('Terjawab', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.success)),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SECTION HEADERS
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildSectionHeader(String title, VoidCallback? onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: const Text(
                'Lihat Semua',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeaderNoPad(String title, VoidCallback? onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SHIMMER PLACEHOLDERS
  // ═══════════════════════════════════════════════════════════════════
  Widget _shimmerHorizontalList({double height = 180}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => Container(
          width: 140,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // WEATHER HELPERS
  // ═══════════════════════════════════════════════════════════════════
  String get _weatherDescription {
    if (_weatherData == null) return '';
    final main = (_weatherData!['weather']?[0]?['main'] ?? '')
        .toString()
        .toLowerCase();
    if (main.contains('clear')) return 'Cerah ☀️';
    if (main.contains('cloud')) return 'Berawan ⛅';
    if (main.contains('rain') || main.contains('drizzle')) return 'Hujan 🌧';
    if (main.contains('thunder')) return 'Badai ⛈';
    if (main.contains('snow')) return 'Salju ❄️';
    return 'Cerah 🌤';
  }

  double get _weatherTemp =>
      (_weatherData?['main']?['temp'] as num?)?.toDouble() ?? 0;

  // ═══════════════════════════════════════════════════════════════════
  // PRICE FORMATTER
  // ═══════════════════════════════════════════════════════════════════
  String _formatPrice(double price) {
    final s = price.toStringAsFixed(0);
    final chars = s.split('').reversed.toList();
    final result = <String>[];
    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) result.add('.');
      result.add(chars[i]);
    }
    return result.reversed.join();
  }
}
