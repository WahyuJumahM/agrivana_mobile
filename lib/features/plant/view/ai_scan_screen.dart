import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/cloudinary_service.dart';
import '../../../services/api_config.dart';
import '../model/plant_model.dart';
import '../service/plant_service.dart';

class AiScanScreen extends StatefulWidget {
  const AiScanScreen({super.key});
  @override
  State<AiScanScreen> createState() => _AiScanScreenState();
}

class _AiScanScreenState extends State<AiScanScreen> {
  final ImagePicker _picker = ImagePicker();

  List<ScanAvailablePlantModel> _availablePlants = [];
  ScanAvailablePlantModel? _selectedPlant;
  File? _imageFile;
  bool _loading = true;
  bool _scanning = false;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _loadAvailablePlants();
  }

  Future<void> _loadAvailablePlants() async {
    setState(() => _loading = true);
    _availablePlants = await AiScanService.getAvailablePlants();
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
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.82),
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
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.82),
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
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 280,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: _imageFile == null
                    ? Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3), width: 2, strokeAlign: BorderSide.strokeAlignInside)
                    : null,
                boxShadow: _imageFile != null
                    ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))]
                    : null,
              ),
              child: _imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(_imageFile!, fit: BoxFit.cover),
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
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 40, color: Color(0xFF2E7D32)),
                        ),
                        const SizedBox(height: 16),
                        const Text('Tap untuk mengambil foto', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF424242))),
                        const SizedBox(height: 4),
                        Text('Ambil foto daun atau tanaman', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
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
    final isHealthy = _result?['diseaseName'] == null || _result?['diseaseName'] == 'Sehat' || _result?['diseaseName'] == 'Healthy';
    final statusColor = isHealthy ? const Color(0xFF2E7D32) : const Color(0xFFE65100);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Status banner
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
                      'Confidence: ${_result!['confidence']}%',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Image preview
          if (_imageFile != null)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: Column(
                children: [
                  ClipRRect(
                    child: Image.file(_imageFile!, height: 200, width: double.infinity, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text('Foto yang dianalisis', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ),
                ],
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

  Future<void> _doScan() async {
    if (_imageFile == null || _selectedPlant == null) return;
    setState(() => _scanning = true);

    try {
      // Upload to Cloudinary first
      final imageUrl = await CloudinaryService.uploadImage(
        _imageFile!,
        preset: ApiConfig.otherPreset,
      );

      if (imageUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Gagal upload gambar'),
              backgroundColor: Colors.red[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        setState(() => _scanning = false);
        return;
      }

      // Call scan API
      final result = await AiScanService.scan(
        plantTypeId: _selectedPlant!.id,
        imageBase64: imageUrl,
        source: 'camera',
      );

      setState(() {
        _result = result.success ? (result.data as Map<String, dynamic>?) : null;
        _scanning = false;
      });

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
