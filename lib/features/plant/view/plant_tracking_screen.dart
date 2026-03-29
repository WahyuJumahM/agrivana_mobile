//location : agrivana\lib\features\plant\view\plant_tracking_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../bloc/plant_bloc.dart';
import '../model/plant_model.dart';
import 'plant_detail_screen.dart';
import 'add_plant_screen.dart';
import 'ai_scan_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shimmer_widgets.dart';
import '../../../services/weather_service.dart';
import '../service/plant_service.dart';

class PlantTrackingScreen extends StatefulWidget {
  const PlantTrackingScreen({super.key});
  @override
  State<PlantTrackingScreen> createState() => _PlantTrackingScreenState();
}

class _PlantTrackingScreenState extends State<PlantTrackingScreen> {
  Map<String, dynamic>? _weatherData;
  List<CareScheduleModel> _todaySchedules = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    context.read<PlantBloc>().add(LoadPlantData());
    _fetchWeather();
    _fetchTodaySchedules();
  }

  Future<void> _fetchWeather() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever)
        return;
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
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

  Future<void> _fetchTodaySchedules() async {
    try {
      final schedules = await PlantService.getTodaySchedules();
      if (mounted) setState(() => _todaySchedules = schedules);
    } catch (_) {}
  }

  Future<void> _openAddPlant() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddPlantScreen()),
    );
    if (result == true && mounted) {
      context.read<PlantBloc>().add(LoadPlantData());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Tanya AI Button
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF81C784)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () => Navigator.pushNamed(context, '/chatbot'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Tanya AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 72,
            ), // Add Plant Button diturunkan/dihapus, SizedBox mempertahankan Tanya AI tetap di posisinya
          ],
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<PlantBloc, PlantState>(
          listener: (context, state) {
            if (state is PlantActionSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.success,
                ),
              );
            } else if (state is PlantError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.error,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is PlantLoading) {
              return const ShimmerProductGrid(itemCount: 4);
            }
            if (state is PlantLoaded) {
              return _buildContent(state);
            }
            return const Center(child: Text('Memuat kebun Anda...'));
          },
        ),
      ),
    );
  }

  Widget _buildContent(PlantLoaded state) {
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: () async {
        context.read<PlantBloc>().add(LoadPlantData());
        _fetchWeather();
        _fetchTodaySchedules();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: 16),

          // ─── Title ────────────────────────────────────
          const Center(
            child: Text(
              'Monitor Tanaman',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ─── Search Bar ────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(color: AppTheme.divider),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Cari tanaman Anda...',
                  hintStyle: const TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppTheme.textHint,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: const Icon(
                            Icons.close_rounded,
                            color: AppTheme.textHint,
                            size: 18,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ─── Weather Card ─────────────────────────────
          if (_weatherData != null) _buildWeatherCard(),

          // ─── Tanaman Anda ─────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tanaman Anda',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                GestureDetector(
                  onTap: _openAddPlant,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 16, color: AppTheme.primary),
                        SizedBox(width: 4),
                        Text(
                          'Tambah',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
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
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final filteredPlants = _searchQuery.isEmpty
                  ? state.plants
                  : state.plants
                        .where(
                          (p) => p.name.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ),
                        )
                        .toList();
              if (filteredPlants.isEmpty) {
                if (state.plants.isEmpty) return _buildEmptyPlants();
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 40),
                  child: Center(
                    child: Text(
                      'Tanaman tidak ditemukan',
                      style: TextStyle(color: AppTheme.textHint),
                    ),
                  ),
                );
              }
              return _buildPlantHorizontalList(filteredPlants);
            },
          ),

          // ─── Rekomendasi Hari Ini ─────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Rekomendasi Hari ini',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                if (_todaySchedules.isNotEmpty)
                  Text(
                    '${_todaySchedules.where((s) => !s.isDone).length} tugas',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textHint.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_todaySchedules.isEmpty)
            _buildEmptySchedules()
          else
            ..._todaySchedules.map((s) => _buildScheduleCard(s)),

          const SizedBox(height: 20),

          // ─── AI Scan Promo ────────────────────────────
          _buildAiScanBanner(),

          const SizedBox(height: 100), // Bottom padding for FAB/nav
        ],
      ),
    );
  }

  // ─── Weather Card ─────────────────────────────────────────────────
  Widget _buildWeatherCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _weatherCity.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_weatherTemp.toStringAsFixed(0)}°',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                          Text(
                            'C',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _weatherIcon,
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Condition badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _capitalize(_weatherDesc),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Tip row
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.12),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppTheme.radiusXl),
                  bottomRight: Radius.circular(AppTheme.radiusXl),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _weatherTip,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Plant Horizontal List ────────────────────────────────────────
  Widget _buildPlantHorizontalList(List<UserPlantModel> plants) {
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: plants.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _buildPlantCard(plants[i]),
      ),
    );
  }

  Widget _buildPlantCard(UserPlantModel plant) {
    final healthPercent = _healthToPercent(plant.health);
    final healthColor = plant.health == 'healthy'
        ? AppTheme.success
        : plant.health == 'needs_attention'
        ? AppTheme.warning
        : AppTheme.error;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlantDetailScreen(plantId: plant.id),
          ),
        );
        if (result == true && mounted) {
          context.read<PlantBloc>().add(LoadPlantData());
        }
      },
      child: SizedBox(
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image card with name overlay
            Expanded(
              child: Container(
                width: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  color: AppTheme.primarySurface,
                  boxShadow: AppTheme.softShadow,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image
                      if (plant.coverPhoto != null &&
                          plant.coverPhoto!.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: plant.coverPhoto!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppTheme.primarySurface,
                            child: Center(
                              child: Text(
                                plant.plantIcon ?? '🌱',
                                style: const TextStyle(fontSize: 36),
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppTheme.primarySurface,
                            child: Center(
                              child: Text(
                                plant.plantIcon ?? '🌱',
                                style: const TextStyle(fontSize: 36),
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          color: AppTheme.primarySurface,
                          child: Center(
                            child: Text(
                              plant.plantIcon ?? '🌱',
                              style: const TextStyle(fontSize: 36),
                            ),
                          ),
                        ),
                      // Gradient overlay at bottom
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(12, 24, 12, 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.6),
                              ],
                            ),
                          ),
                          child: Text(
                            plant.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Health percentage row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.water_drop_rounded,
                      size: 14,
                      color: healthColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$healthPercent%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: healthColor,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.primarySurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.north_east_rounded,
                    size: 14,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Schedule / Recommendation Cards ──────────────────────────────
  Widget _buildScheduleCard(CareScheduleModel schedule) {
    final time =
        '${schedule.scheduledAt.hour.toString().padLeft(2, '0')}:${schedule.scheduledAt.minute.toString().padLeft(2, '0')}';
    final subtitle =
        'Pukul $time${schedule.description != null ? ' • ${schedule.description}' : ''}';

    IconData iconData;
    Color iconBg;
    Color iconColor;
    switch (schedule.careType) {
      case 'watering':
        iconData = Icons.water_drop_rounded;
        iconBg = const Color(0xFFE3F2FD);
        iconColor = const Color(0xFF1565C0);
        break;
      case 'fertilizing':
        iconData = Icons.science_rounded;
        iconBg = const Color(0xFFFFF3E0);
        iconColor = const Color(0xFFE65100);
        break;
      case 'pruning':
        iconData = Icons.content_cut_rounded;
        iconBg = const Color(0xFFF3E5F5);
        iconColor = const Color(0xFF7B1FA2);
        break;
      case 'pesticide':
        iconData = Icons.shield_rounded;
        iconBg = const Color(0xFFE8F5E9);
        iconColor = AppTheme.primary;
        break;
      default:
        iconData = Icons.task_alt_rounded;
        iconBg = AppTheme.primarySurface;
        iconColor = AppTheme.primary;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(iconData, size: 22, color: iconColor),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.title ??
                        '${schedule.careTypeLabel} ${schedule.plantName ?? ''}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: schedule.isDone
                          ? AppTheme.textHint
                          : AppTheme.textPrimary,
                      decoration: schedule.isDone
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textHint.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: schedule.isDone ? AppTheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: schedule.isDone ? AppTheme.primary : AppTheme.divider,
                  width: 2,
                ),
              ),
              child: schedule.isDone
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ─── AI Scan Banner ───────────────────────────────────────────────
  Widget _buildAiScanBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AiScanScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF0F172A)],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.workspace_premium_rounded,
                      size: 12,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'PREMIUM',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fitur Baru: AI Scan',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Deteksi Penyakit Instan dengan AI Scan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.document_scanner_outlined,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.document_scanner_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Coba Sekarang',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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
  }

  // ─── Empty States ─────────────────────────────────────────────────
  Widget _buildEmptyPlants() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.divider.withValues(alpha: 0.6)),
        ),
        child: Column(
          children: [
            const Text('🌱', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            const Text(
              'Belum ada tanaman',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Mulai tambahkan tanaman untuk melacak pertumbuhannya',
              style: TextStyle(
                color: AppTheme.textHint.withValues(alpha: 0.7),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _openAddPlant,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah Tanaman'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySchedules() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primarySurface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: AppTheme.success,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Tidak ada jadwal hari ini 🎉',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Weather helpers ──────────────────────────────────────────────
  String get _weatherIcon {
    if (_weatherData == null) return '🌤';
    final main = (_weatherData!['weather']?[0]?['main'] ?? '')
        .toString()
        .toLowerCase();
    if (main.contains('clear')) return '☀️';
    if (main.contains('cloud')) return '☁️';
    if (main.contains('rain') || main.contains('drizzle')) return '🌧';
    if (main.contains('thunder')) return '⛈';
    if (main.contains('snow')) return '❄️';
    if (main.contains('mist') || main.contains('fog') || main.contains('haze'))
      return '🌫';
    return '🌤';
  }

  String get _weatherDesc {
    if (_weatherData == null) return '';
    return _weatherData!['weather']?[0]?['description'] ?? '';
  }

  double get _weatherTemp =>
      (_weatherData?['main']?['temp'] as num?)?.toDouble() ?? 0;
  int get _weatherHumidity =>
      (_weatherData?['main']?['humidity'] as num?)?.toInt() ?? 0;
  String get _weatherCity => _weatherData?['name'] ?? '';

  String get _weatherTip {
    final temp = _weatherTemp;
    final humidity = _weatherHumidity;
    if (temp > 33) return 'Cuaca panas! Pastikan tanaman cukup air.';
    if (humidity > 80) return 'Kelembapan tinggi, kurangi penyiraman.';
    final main = (_weatherData?['weather']?[0]?['main'] ?? '')
        .toString()
        .toLowerCase();
    if (main.contains('rain')) return 'Sedang hujan, tidak perlu menyiram.';
    return 'Hari ini cocok untuk penyiraman pagi.';
  }

  // ─── Utility helpers ──────────────────────────────────────────────
  int _healthToPercent(String health) {
    switch (health) {
      case 'healthy':
        return 95;
      case 'needs_attention':
        return 60;
      case 'sick':
        return 30;
      default:
        return 50;
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        )
        .join(' ');
  }
}
