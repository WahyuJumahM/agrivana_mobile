import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/api_config.dart';
import '../model/plant_model.dart';
import '../service/plant_service.dart';

class AiScanScreen extends StatefulWidget {
  const AiScanScreen({super.key});
  @override
  State<AiScanScreen> createState() => _AiScanScreenState();
}

class _AiScanScreenState extends State<AiScanScreen> with SingleTickerProviderStateMixin {
  late AnimationController _scannerController;
  late Animation<double> _scannerAnimation;
  final ImagePicker _picker = ImagePicker();

  List<ScanAvailablePlantModel> _availablePlants = [];
  ScanAvailablePlantModel? _selectedPlant;
  File? _imageFile;
  bool _loading = true;
  bool _scanning = false;
  Map<String, dynamic>? _result;

  static const List<Map<String, dynamic>> _scannerPlants = [
    {'id': 'hort_tomat', 'name': 'Tomat', 'icon': '🍅', 'description': 'Sayuran buah populer'},
    {'id': 'hort_bayam', 'name': 'Bayam', 'icon': '🥬', 'description': 'Sayuran hijau bergizi'},
    {'id': 'hort_cabai', 'name': 'Cabai', 'icon': '🌶️', 'description': 'Bumbu dapur utama'},
    {'id': 'hort_terong', 'name': 'Terong', 'icon': '🍆', 'description': 'Sayuran serbaguna'},
    {'id': 'hort_timun', 'name': 'Timun', 'icon': '🥒', 'description': 'Sayuran segar'},
    {'id': 'hort_selada', 'name': 'Selada', 'icon': '🥬', 'description': 'Sayuran daun hijau'},
    {'id': 'hort_kangkung', 'name': 'Kangkung', 'icon': '🌿', 'description': 'Sayuran air populer'},
    {'id': 'hort_sawi', 'name': 'Sawi', 'icon': '🥬', 'description': 'Sayuran hijau serbaguna'},
    {'id': 'hort_brokoli', 'name': 'Brokoli', 'icon': '🥦', 'description': 'Sayuran tinggi nutrisi'},
    {'id': 'hort_wortel', 'name': 'Wortel', 'icon': '🥕', 'description': 'Sayuran umbi kaya vitamin A'},
    {'id': 'hort_bawang_merah', 'name': 'Bawang Merah', 'icon': '🧅', 'description': 'Bumbu dapur esensial'},
    {'id': 'hort_bawang_putih', 'name': 'Bawang Putih', 'icon': '🧄', 'description': 'Bumbu aromatik'},
    {'id': 'hort_paprika', 'name': 'Paprika', 'icon': '🫑', 'description': 'Sayuran buah berwarna'},
    {'id': 'hort_stroberi', 'name': 'Stroberi', 'icon': '🍓', 'description': 'Buah manis segar'},
    {'id': 'hort_semangka', 'name': 'Semangka', 'icon': '🍉', 'description': 'Buah besar menyegarkan'},
    {'id': 'hort_melon', 'name': 'Melon', 'icon': '🍈', 'description': 'Buah manis harum'},
    {'id': 'hort_labu', 'name': 'Labu', 'icon': '🎃', 'description': 'Sayuran buah serbaguna'},
    {'id': 'hort_kacang_panjang', 'name': 'Kacang Panjang', 'icon': '🫘', 'description': 'Sayuran polong'},
    {'id': 'hort_pare', 'name': 'Pare', 'icon': '🥒', 'description': 'Sayuran pahit sehat'},
    {'id': 'hort_jagung', 'name': 'Jagung Manis', 'icon': '🌽', 'description': 'Tanaman serealia manis'},
    {'id': 'hort_kentang', 'name': 'Kentang', 'icon': '🥔', 'description': 'Sayuran umbi populer'},
    {'id': 'hort_lobak', 'name': 'Lobak', 'icon': '🌿', 'description': 'Sayuran umbi segar'},
    {'id': 'hort_seledri', 'name': 'Seledri', 'icon': '🌿', 'description': 'Sayuran aromatik'},
    {'id': 'hort_kemangi', 'name': 'Kemangi', 'icon': '🌿', 'description': 'Herba aromatik'},
    {'id': 'hort_mint', 'name': 'Mint', 'icon': '🌿', 'description': 'Herba segar'},
    {'id': 'hort_rosemary', 'name': 'Rosemary', 'icon': '🌿', 'description': 'Herba aromatik Mediterania'},
    {'id': 'hort_basil', 'name': 'Basil', 'icon': '🌿', 'description': 'Herba masakan Italia'},
    {'id': 'hort_jahe', 'name': 'Jahe', 'icon': '🫚', 'description': 'Rempah berkhasiat'},
    {'id': 'hort_kunyit', 'name': 'Kunyit', 'icon': '🫚', 'description': 'Rempah pewarna alami'},
    {'id': 'hort_lengkuas', 'name': 'Lengkuas', 'icon': '🫚', 'description': 'Rempah bumbu masak'},
    {'id': 'hort_mawar', 'name': 'Mawar', 'icon': '🌹', 'description': 'Bunga hias populer'},
    {'id': 'hort_anggrek', 'name': 'Anggrek', 'icon': '🌸', 'description': 'Bunga hias eksotis'},
    {'id': 'hort_melati', 'name': 'Melati', 'icon': '🌼', 'description': 'Bunga harum khas'},
    {'id': 'hort_krisan', 'name': 'Krisan', 'icon': '🌼', 'description': 'Bunga hias beragam warna'},
    {'id': 'hort_bunga_matahari', 'name': 'Bunga Matahari', 'icon': '🌻', 'description': 'Bunga cerah tinggi'},
    {'id': 'hort_lavender', 'name': 'Lavender', 'icon': '💜', 'description': 'Bunga aromatik ungu'},
    {'id': 'hort_adenium', 'name': 'Adenium', 'icon': '🌺', 'description': 'Bunga kamboja Jepang'},
    {'id': 'hort_lidah_buaya', 'name': 'Lidah Buaya', 'icon': '🌿', 'description': 'Tanaman hias berkhasiat'},
  ];

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _scannerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scannerController, curve: Curves.easeInOutSine),
    );
    _loadAvailablePlants();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailablePlants() async {
    setState(() => _loading = true);
    
    // Fetch data from backend so scanning works with valid IDs
    final backendPlants = await AiScanService.getAvailablePlants();
    
    final List<ScanAvailablePlantModel> reorderedPlants = [];
    
    for (final plantMap in _scannerPlants) {
      final nameStr = plantMap['name'].toString().toLowerCase();
      
      ScanAvailablePlantModel? backendMatch;
      try {
        backendMatch = backendPlants.firstWhere((p) => p.name.toLowerCase() == nameStr);
      } catch (_) {
        backendMatch = null;
      }
      
      final isFree = plantMap['id'] == 'hort_tomat' || 
                     plantMap['id'] == 'hort_bayam' || 
                     plantMap['id'] == 'hort_cabai';
                     
      if (backendMatch != null) {
        reorderedPlants.add(ScanAvailablePlantModel(
          id: backendMatch.id, // Gunakan ID asli dari backend agar scan tidak error
          name: backendMatch.name,
          icon: backendMatch.icon ?? plantMap['icon'] as String,
          accessTier: isFree ? 'free' : 'premium',
          isAccessible: isFree,
          lockMessage: isFree ? null : 'Upgrade ke Premium untuk scan tanaman ${backendMatch.name}.',
          modelStatus: backendMatch.modelStatus,
          modelAccuracy: backendMatch.modelAccuracy,
          diseases: backendMatch.diseases,
        ));
      } else {
        reorderedPlants.add(ScanAvailablePlantModel(
          id: plantMap['id'] as String,
          name: plantMap['name'] as String,
          icon: plantMap['icon'] as String,
          accessTier: isFree ? 'free' : 'premium',
          isAccessible: isFree,
          lockMessage: isFree ? null : 'Upgrade ke Premium untuk scan tanaman ${plantMap['name']}.',
          modelStatus: isFree ? 'ready' : 'in_development',
          modelAccuracy: isFree ? 'Akurasi 95%' : 'Segera Hadir',
          diseases: isFree ? ['Penyakit Daun', 'Hama'] : [],
        ));
      }
    }
    
    _availablePlants = reorderedPlants;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('AI Scan Tanaman', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white)),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF2E7D32)),
                  const SizedBox(height: 12),
                  Text('Memuat data...', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                ],
              ),
            )
          : _result != null
              ? _buildResult()
              : _selectedPlant == null
                  ? _buildPlantSelection()
                  : _buildScanView(),
    );
  }

  // ─── Plant Selection Grid ────────────────────────────────────────
  Widget _buildPlantSelection() {
    final freePlants = _availablePlants.where((p) => p.isAccessible).toList();
    final premiumPlants = _availablePlants.where((p) => !p.isAccessible).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilih tanaman untuk di-scan',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'AI akan menganalisis kesehatan tanaman dari foto',
                        style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {}, // Already on Scan Foto
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B5E20),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: const Color(0xFF1B5E20).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: const Center(
                          child: Text('Scan Foto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.info_outline_rounded, color: Colors.white),
                                SizedBox(width: 10),
                                Expanded(child: Text('Fitur Scan Real Time akan segera tersedia!')),
                              ],
                            ),
                            backgroundColor: const Color(0xFF1B5E20),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('Scan Real Time', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (freePlants.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('🆓 Gratis', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1B5E20))),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.72),
              delegate: SliverChildBuilderDelegate(
                (_, i) => _buildPlantTile(freePlants[i]),
                childCount: freePlants.length,
              ),
            ),
          ),
        ],
        if (premiumPlants.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('👑 Premium', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFF57F17))),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.72),
              delegate: SliverChildBuilderDelegate(
                (_, i) => _buildPlantTile(premiumPlants[i]),
                childCount: premiumPlants.length,
              ),
            ),
          ),
        ],
        const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
      ],
    );
  }

  Widget _buildPlantTile(ScanAvailablePlantModel plant) {
    final isLocked = !plant.isAccessible;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isLocked
            ? () => _showPremiumDialog(plant)
            : () => setState(() => _selectedPlant = plant),
        child: Container(
          decoration: BoxDecoration(
            color: isLocked ? Colors.grey[50] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isLocked ? Colors.grey[200]! : const Color(0xFFE8F5E9)),
            boxShadow: isLocked ? null : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isLocked ? Colors.grey[100] : const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(plant.icon ?? '🌱', style: TextStyle(fontSize: 22, color: isLocked ? Colors.grey : null)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        plant.name,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isLocked ? Colors.grey : Colors.black87),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (plant.modelAccuracy != null)
                        Text(plant.modelAccuracy!, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: isLocked ? Colors.grey : const Color(0xFF2E7D32))),
                      if (plant.modelStatus == 'in_development')
                        Container(
                          margin: const EdgeInsets.only(top: 3),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Text('Dev', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w600, color: Colors.orange)),
                        ),
                    ],
                  ),
                ),
              ),
              if (isLocked)
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.lock_rounded, size: 12, color: Colors.grey[400]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Scan View ───────────────────────────────────────────────────
  Widget _buildScanView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(_selectedPlant!.icon ?? '🌱', style: const TextStyle(fontSize: 24))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Scan ${_selectedPlant!.name}', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1B5E20))),
                      if (_selectedPlant!.diseases.isNotEmpty)
                        Text('Deteksi: ${_selectedPlant!.diseases.take(3).join(', ')}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() { _selectedPlant = null; _imageFile = null; }),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    backgroundColor: Colors.white.withOpacity(0.6),
                  ),
                  child: const Text('Ganti', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // ── Photo container with scanner animation overlay ──
          GestureDetector(
            onTap: _scanning ? null : _pickImage,
            child: Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: _imageFile == null
                    ? Border.all(color: const Color(0xFF2E7D32).withOpacity(0.25), width: 2, strokeAlign: BorderSide.strokeAlignInside)
                    : null,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(_imageFile != null ? 0.10 : 0.04), blurRadius: 20, offset: const Offset(0, 6)),
                ],
              ),
              child: _imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Photo
                          Image.file(_imageFile!, fit: BoxFit.cover),

                          // Dark vignette overlay while scanning
                          if (_scanning)
                            Container(
                              color: Colors.black.withOpacity(0.35),
                            ),

                          // Animated scanner beam
                          if (_scanning)
                            AnimatedBuilder(
                              animation: _scannerAnimation,
                              builder: (context, child) {
                                return Positioned(
                                  top: _scannerAnimation.value * 260,
                                  left: 0,
                                  right: 0,
                                  child: Column(
                                    children: [
                                      // Gradient glow above
                                      Container(
                                        height: 40,
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Color(0x4400FF88),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // The main laser line
                                      Container(
                                        height: 3,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              Color(0xFF00E676),
                                              Color(0xFF69F0AE),
                                              Color(0xFF00E676),
                                              Colors.transparent,
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(color: const Color(0xFF00E676).withOpacity(0.8), blurRadius: 12, spreadRadius: 2),
                                          ],
                                        ),
                                      ),
                                      // Gradient glow below
                                      Container(
                                        height: 40,
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Color(0x4400FF88),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                          // Corner scan brackets
                          if (_scanning) ...[
                            Positioned(top: 14, left: 14, child: _scanCorner(false, false)),
                            Positioned(top: 14, right: 14, child: _scanCorner(false, true)),
                            Positioned(bottom: 14, left: 14, child: _scanCorner(true, false)),
                            Positioned(bottom: 14, right: 14, child: _scanCorner(true, true)),
                          ],

                          // Scanning label
                          if (_scanning)
                            Positioned(
                              bottom: 18,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.55),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    '🔬 AI sedang menganalisis...',
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ),

                          // Edit button (only when not scanning)
                          if (!_scanning)
                            Positioned(
                              top: 12, right: 12,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                              ),
                            ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                            ),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.15)),
                          ),
                          child: const Icon(Icons.add_photo_alternate_rounded, size: 46, color: Color(0xFF2E7D32)),
                        ),
                        const SizedBox(height: 18),
                        const Text('Tap untuk memilih foto', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1B5E20))),
                        const SizedBox(height: 5),
                        Text('Pilih dari galeri atau ambil dari kamera', style: TextStyle(fontSize: 12.5, color: Colors.grey[500])),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _sourceButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Galeri',
                  onTap: () => _pickFromSource(ImageSource.gallery),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _sourceButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Kamera',
                  onTap: () => _pickFromSource(ImageSource.camera),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _imageFile != null && !_scanning ? _doScan : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[200],
                disabledForegroundColor: Colors.grey[400],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: _imageFile != null ? 3 : 0,
                shadowColor: const Color(0xFF2E7D32).withOpacity(0.3),
              ),
              child: _scanning
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        SizedBox(width: 10),
                        Text('Menganalisis...', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_rounded, size: 22),
                        SizedBox(width: 8),
                        Text('Mulai Scan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sourceButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8F5E9)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: const Color(0xFF2E7D32)),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2E7D32))),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Result View ─────────────────────────────────────────────────
  Widget _buildResult() {
    final isHealthy = _result?['isHealthy'] == true ||
        _result?['diseaseName'] == null ||
        _result?['diseaseName'] == 'Sehat' ||
        _result?['diseaseName'] == 'Healthy';
    final statusColor = isHealthy ? const Color(0xFF2E7D32) : const Color(0xFFE65100);
    final statusBgLight = isHealthy ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ─── Status Banner ─────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isHealthy
                    ? [const Color(0xFF2E7D32), const Color(0xFF43A047)]
                    : [const Color(0xFFE65100), const Color(0xFFF57C00)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Icon(
                  isHealthy ? Icons.check_circle_rounded : Icons.warning_rounded,
                  color: Colors.white, size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  _result?['diseaseName'] ?? 'Sehat',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                if (_result?['confidence'] != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Keyakinan: ${_result!['confidence']}%',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ─── Image Preview ─────────────────────────────────────────
          if (_imageFile != null)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(color: Colors.white),
              child: Column(
                children: [
                  ClipRRect(
                    child: Image.file(_imageFile!, height: 180, width: double.infinity, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text('Foto yang dianalisis', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                  ),
                ],
              ),
            ),

          // ─── Catatan Utama (Message) ───────────────────────────────
          if (_result?['message'] != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusBgLight,
                border: Border(top: BorderSide(color: Colors.grey[200]!, width: 0.5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isHealthy ? Icons.eco_rounded : Icons.report_rounded,
                    size: 20, color: statusColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📋 Catatan',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: statusColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _result!['message'],
                          style: TextStyle(fontSize: 13, height: 1.5, color: statusColor.withOpacity(0.85)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // ─── Deskripsi Kondisi ──────────────────────────────────────
          if (_result?['description'] != null)
            _buildInfoCard(
              icon: Icons.visibility_rounded,
              title: 'Hasil Pengamatan',
              content: _result!['description'],
              iconColor: const Color(0xFF5E35B1),
              showDivider: true,
            ),

          // ─── Penanganan / Tips Perawatan ────────────────────────────
          if (_result?['treatment'] != null)
            _buildInfoCard(
              icon: isHealthy ? Icons.tips_and_updates_rounded : Icons.medical_services_rounded,
              title: isHealthy ? '💡 Tips Perawatan' : '💊 Cara Penanganan',
              content: _result!['treatment'],
              iconColor: isHealthy ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
              showDivider: true,
            ),

          // ─── Pencegahan ────────────────────────────────────────────
          if (_result?['prevention'] != null)
            _buildInfoCard(
              icon: Icons.shield_rounded,
              title: '🛡️ Pencegahan',
              content: _result!['prevention'],
              iconColor: const Color(0xFF1565C0),
              showDivider: false,
              isLast: true,
            ),

          // If no detail cards at all, show a basic close card
          if (_result?['description'] == null && _result?['treatment'] == null && _result?['prevention'] == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Text(
                'Coba ambil foto dengan pencahayaan yang lebih baik dan arahkan kamera ke bagian daun atau buah secara dekat untuk hasil analisis yang lebih detail.',
                style: TextStyle(fontSize: 12, color: Colors.grey[500], height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () => setState(() { _result = null; _imageFile = null; _selectedPlant = null; }),
              style: ElevatedButton.styleFrom(
                backgroundColor: statusColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Scan Lagi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required Color iconColor,
    bool showDivider = true,
    bool isLast = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(20)) : null,
        border: showDivider ? Border(top: BorderSide(color: Colors.grey[200]!, width: 0.5)) : null,
        boxShadow: isLast ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: iconColor)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF424242)),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final action = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Text('Pilih Sumber Foto', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF2E7D32)),
                ),
                title: const Text('Kamera'),
                subtitle: const Text('Ambil foto langsung', style: TextStyle(fontSize: 12)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF1565C0)),
                ),
                title: const Text('Galeri'),
                subtitle: const Text('Pilih dari galeri foto', style: TextStyle(fontSize: 12)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (action != null) _pickFromSource(action);
  }

  Future<void> _pickFromSource(ImageSource source) async {
    final xf = await _picker.pickImage(source: source, maxWidth: 1024, imageQuality: 85);
    if (xf != null) setState(() => _imageFile = File(xf.path));
  }

  // ─── Corner bracket widget for scan overlay ────────────────────
  Widget _scanCorner(bool flipV, bool flipH) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..scale(flipH ? -1.0 : 1.0, flipV ? -1.0 : 1.0),
      child: CustomPaint(
        size: const Size(22, 22),
        painter: _CornerPainter(),
      ),
    );
  }

  Future<void> _doScan() async {
    if (_imageFile == null || _selectedPlant == null) return;
    setState(() => _scanning = true);
    _scannerController.repeat(reverse: true);

    try {
      // Convert image to base64
      final bytes = await _imageFile!.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Call scan API with base64 image directly
      final result = await AiScanService.scan(
        plantTypeId: _selectedPlant!.id,
        imageBase64: base64Image,
        source: 'camera',
      );

      setState(() {
        _result = result.success ? (result.data as Map<String, dynamic>?) : null;
        _scanning = false;
      });
      _scannerController.stop();
      _scannerController.reset();

      if (!result.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.statusCode == 403 ? Colors.orange : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      _scannerController.stop();
      _scannerController.reset();
      setState(() => _scanning = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _showPremiumDialog(ScanAvailablePlantModel plant) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [Text('👑 ', style: TextStyle(fontSize: 24)), Text('Premium Only', style: TextStyle(fontWeight: FontWeight.w700))]),
        content: Text(plant.lockMessage ?? 'Upgrade ke Premium untuk scan tanaman ini.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to subscription screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF57F17),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Upgrade', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─── Corner Bracket Painter ───────────────────────────────────────────────────
class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00E676)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const l = 14.0;
    canvas.drawLine(const Offset(0, 0), Offset(0, l), paint);
    canvas.drawLine(const Offset(0, 0), Offset(l, 0), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
