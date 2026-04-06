import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../model/plant_model.dart';
import '../service/plant_service.dart';
import '../../../services/cloudinary_service.dart';
import '../../../services/weather_service.dart';
import '../../chatbot/view/chatbot_screen.dart';

class PlantDetailScreen extends StatefulWidget {
  final String plantId;
  const PlantDetailScreen({super.key, required this.plantId});
  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  UserPlantModel? _plant;
  List<GrowthLogModel> _logs = [];
  List<CareScheduleModel> _schedules = [];
  PlantStatsModel? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        PlantService.getPlantDetail(widget.plantId),
        PlantService.getGrowthLogs(widget.plantId),
        PlantService.getSchedules(widget.plantId),
        PlantService.getPlantStats(widget.plantId),
      ]);
      setState(() {
        _plant = results[0] as UserPlantModel?;
        _logs = results[1] as List<GrowthLogModel>;
        _schedules = results[2] as List<CareScheduleModel>;
        _stats = results[3] as PlantStatsModel?;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Detail Tanaman', style: TextStyle(color: Colors.white)), 
          backgroundColor: const Color(0xFF2E7D32), 
          foregroundColor: Colors.white
        ),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
      );
    }
    if (_plant == null) {
      return Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Detail Tanaman', style: TextStyle(color: Colors.white)), 
          backgroundColor: const Color(0xFF2E7D32), 
          foregroundColor: Colors.white
        ),
        body: const Center(child: Text('Tanaman tidak ditemukan')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: const Color(0xFF1B5E20),
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _plant!.coverPhoto != null
                      ? Image.network(_plant!.coverPhoto!, fit: BoxFit.cover)
                      : Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF1B5E20), Color(0xFF388E3C), Color(0xFF66BB6A)],
                            ),
                          ),
                          child: Center(child: Text(_plant!.plantIcon ?? '🌱', style: const TextStyle(fontSize: 72))),
                        ),
                  // Gradient overlay for text legibility
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 56,
                    right: 16,
                    child: GestureDetector(
                      onTap: _pickCoverPhoto,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withOpacity(0.4)),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 22),
                tooltip: 'Edit Tanaman',
                onPressed: _showEditPlantDialog,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (val) async {
                  if (val == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text('Hapus Tanaman?'),
                        content: const Text('Tanaman akan dihapus dari kebun Anda.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && mounted) {
                      await PlantService.deletePlant(widget.plantId);
                      if (mounted) Navigator.pop(context, true);
                    }
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: Colors.red, size: 18), SizedBox(width: 8), Text('Hapus Tanaman')])),
                ],
              ),
            ],
          ),
          SliverToBoxAdapter(child: _buildInfoCard()),
          if (_stats != null) SliverToBoxAdapter(child: _buildStatsRow()),
          SliverPersistentHeader(
            delegate: _TabBarDelegate(TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF1B5E20),
              unselectedLabelColor: Colors.grey[400],
              indicatorColor: const Color(0xFF2E7D32),
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: const [
                Tab(icon: Icon(Icons.timeline_rounded, size: 20), text: 'Log'),
                Tab(icon: Icon(Icons.schedule_rounded, size: 20), text: 'Jadwal'),
                Tab(icon: Icon(Icons.bar_chart_rounded, size: 20), text: 'Statistik'),
              ],
            )),
            pinned: true,
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildLogsTab(),
            _buildSchedulesTab(),
            _buildStatsTab(),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'chatbot',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatbotScreen())),
            backgroundColor: const Color(0xFF1565C0),
            elevation: 4,
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: _showAddMenu,
            backgroundColor: const Color(0xFF2E7D32),
            elevation: 6,
            child: const Icon(Icons.add_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ─── Cover Photo Upload ─────────────────────────────────────────
  Future<void> _pickCoverPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
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
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF1565C0)),
                ),
                title: const Text('Galeri'),
                subtitle: const Text('Pilih dari galeri foto', style: TextStyle(fontSize: 12)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 1200, imageQuality: 85);
    if (picked == null) return;

    _showSnack('Mengupload foto...', isLoading: true);
    final url = await CloudinaryService.uploadPlantPhoto(File(picked.path));
    if (url != null && mounted) {
      await PlantService.updatePlant(widget.plantId, {'coverPhoto': url});
      ScaffoldMessenger.of(context).clearSnackBars();
      _showSnack('Foto berhasil diperbarui!');
      _loadAll();
    } else if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      _showSnack('Gagal mengupload foto', isError: true);
    }
  }

  // ─── Edit Plant Dialog ──────────────────────────────────────────
  void _showEditPlantDialog() {
    final nameCtrl = TextEditingController(text: _plant!.name);
    final locCtrl = TextEditingController(text: _plant!.locationDesc ?? '');
    final areaCtrl = TextEditingController(text: _plant!.areaSize?.toString() ?? '');
    final notesCtrl = TextEditingController(text: _plant!.notes ?? '');
    String mediaType = _plant!.mediaType ?? 'pot';
    final mediaOptions = ['pot', 'ground', 'hydroponic', 'grow_bag', 'polybag', 'tanah_sawah'];
    final mediaLabels = {
      'pot': 'Pot', 'ground': 'Tanah Langsung', 'hydroponic': 'Hidroponik',
      'grow_bag': 'Grow Bag', 'polybag': 'Polybag', 'tanah_sawah': 'Tanah Sawah',
    };
    final inputDecoration = (String label, IconData icon) => InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
      filled: true,
      fillColor: const Color(0xFFF5F8F5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.edit_rounded, color: Color(0xFF2E7D32), size: 22),
                    SizedBox(width: 8),
                    Text('Edit Tanaman', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(controller: nameCtrl, decoration: inputDecoration('Nama Tanaman', Icons.local_florist_rounded)),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: mediaOptions.contains(mediaType) ? mediaType : 'pot',
                  decoration: inputDecoration('Media Tanam', Icons.eco_rounded),
                  items: mediaOptions.map((m) => DropdownMenuItem(value: m, child: Text(mediaLabels[m] ?? m))).toList(),
                  onChanged: (v) => setModalState(() => mediaType = v!),
                ),
                const SizedBox(height: 14),
                TextField(controller: locCtrl, decoration: inputDecoration('Lokasi', Icons.location_on_rounded)),
                const SizedBox(height: 14),
                TextField(controller: areaCtrl, decoration: inputDecoration('Luas Area (m²)', Icons.straighten_rounded), keyboardType: TextInputType.number),
                const SizedBox(height: 14),
                TextField(controller: notesCtrl, decoration: inputDecoration('Catatan', Icons.notes_rounded), maxLines: 3),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final data = <String, dynamic>{
                        'customName': nameCtrl.text,
                        'mediaType': mediaType,
                      };
                      if (locCtrl.text.isNotEmpty) data['locationDesc'] = locCtrl.text;
                      if (areaCtrl.text.isNotEmpty) {
                        data['areaSize'] = double.tryParse(areaCtrl.text);
                        data['areaSizeUnit'] = 'm2';
                      }
                      if (notesCtrl.text.isNotEmpty) data['notes'] = notesCtrl.text;
                      await PlantService.updatePlant(widget.plantId, data);
                      _loadAll();
                      _showSnack('Tanaman berhasil diperbarui!');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('Simpan Perubahan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Info Card ──────────────────────────────────────────────────
  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8F5E9)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _plant!.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _plant!.health == 'healthy' ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _plant!.health == 'healthy' ? Icons.favorite_rounded : Icons.warning_amber_rounded,
                      size: 13,
                      color: _plant!.health == 'healthy' ? Colors.green[700] : Colors.orange[700],
                    ),
                    const SizedBox(width: 4),
                    Text(_plant!.healthLabel, style: TextStyle(
                      fontSize: 11,
                      color: _plant!.health == 'healthy' ? Colors.green[700] : Colors.orange[700],
                      fontWeight: FontWeight.w600,
                    )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (_plant!.categoryName != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${_plant!.categoryIcon ?? ''} ${_plant!.categoryName}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF1B5E20), fontWeight: FontWeight.w600)),
                ),
              if (_plant!.categoryName != null && _plant!.plantType != null)
                const SizedBox(width: 8),
              if (_plant!.plantType != null)
                Text('${_plant!.plantType}${_plant!.varietyName != null ? ' • ${_plant!.varietyName}' : ''}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF424242))),
            ],
          ),
          if (_plant!.scientificName != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(_plant!.scientificName!, style: TextStyle(fontSize: 12, color: Colors.grey[400], fontStyle: FontStyle.italic)),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _infoChip('📅', _plant!.phaseLabel),
              _infoChip('🏡', _plant!.mediaType ?? 'pot'),
              if (_plant!.areaSize != null) _infoChip('📐', '${_plant!.areaSize} ${_plant!.areaSizeUnit ?? 'm²'}'),
              _infoChip('🌱', '${_plant!.daysSincePlanted} hari'),
            ],
          ),
          if (_plant!.locationDesc != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.location_on_rounded, size: 15, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(child: Text(_plant!.locationDesc!, style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
              ],
            ),
          ],
          if (_plant!.notes != null && _plant!.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notes_rounded, size: 15, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(child: Text(_plant!.notes!, style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoChip(String emoji, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          _statCard('📊', '${_stats!.totalLogs}', 'Total Log', const Color(0xFF2E7D32)),
          const SizedBox(width: 8),
          _statCard('📅', '${_stats!.daysSincePlanted}', 'Hari', const Color(0xFF1565C0)),
          const SizedBox(width: 8),
          _statCard('📋', '${_stats!.pendingSchedules}', 'Jadwal', const Color(0xFFE65100)),
          if (_stats!.latestHealthScore != null) ...[
            const SizedBox(width: 8),
            _statCard('❤️', '${_stats!.latestHealthScore}', 'Kesehatan', const Color(0xFFC62828)),
          ],
        ],
      ),
    );
  }

  Widget _statCard(String emoji, String value, String label, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withOpacity(0.15)),
          boxShadow: [BoxShadow(color: accent.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: accent)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // ─── Logs Tab ───────────────────────────────────────────────────
  Widget _buildLogsTab() {
    if (_logs.isEmpty) {
      return const Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Text('📝', style: TextStyle(fontSize: 40)), SizedBox(height: 8), Text('Belum ada log pertumbuhan')],
      ));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _logs.length,
      itemBuilder: (_, i) {
        final log = _logs[i];
        return Dismissible(
          key: Key(log.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) async {
            return await showDialog<bool>(context: context, builder: (_) => AlertDialog(
              title: const Text('Hapus Log?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
              ],
            ));
          },
          onDismissed: (_) async {
            await PlantService.deleteGrowthLog(widget.plantId, log.id);
            _loadAll();
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.delete, color: Colors.red),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(6)),
                      child: Text(log.phaseLabel, style: const TextStyle(fontSize: 11, color: Color(0xFF2E7D32), fontWeight: FontWeight.w500)),
                    ),
                    if (log.healthScore != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: (log.healthScore! >= 7 ? Colors.green : log.healthScore! >= 4 ? Colors.orange : Colors.red).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('❤️ ${log.healthScore}/10', style: const TextStyle(fontSize: 10)),
                      ),
                    ],
                    const Spacer(),
                    Text(_formatDate(log.logDate), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  ],
                ),
                if (log.note != null && log.note!.isNotEmpty) ...[const SizedBox(height: 8), Text(log.note!, style: const TextStyle(fontSize: 13))],
                if (log.heightCm != null || log.leafCount != null || log.weather != null || log.temperatureCelsius != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (log.heightCm != null) _infoChip('📏', '${log.heightCm} cm'),
                      if (log.leafCount != null) _infoChip('🍃', '${log.leafCount} daun'),
                      if (log.weather != null) _infoChip(_weatherIcon(log.weather!), '${log.weather}'),
                      if (log.temperatureCelsius != null) _infoChip('🌡', '${log.temperatureCelsius}°C'),
                    ],
                  ),
                ],
                if (log.issues != null && log.issues!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: log.issues!.map((issue) => Chip(
                      label: Text(issue, style: const TextStyle(fontSize: 10)),
                      backgroundColor: Colors.red.withOpacity(0.1),
                      labelStyle: const TextStyle(color: Colors.red),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    )).toList(),
                  ),
                ],
                if (log.photos.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: log.photos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, pi) => GestureDetector(
                        onTap: () => _showFullImage(log.photos[pi].url),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(log.photos[pi].url, width: 80, height: 80, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Schedules Tab ──────────────────────────────────────────────
  Widget _buildSchedulesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await PlantService.generateSchedules(widget.plantId);
                    _loadAll();
                    _showSnack('Jadwal berhasil digenerate!');
                  },
                  icon: const Icon(Icons.auto_fix_high, size: 16),
                  label: const Text('Auto Generate', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D32),
                    side: const BorderSide(color: Color(0xFF2E7D32)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _showAddScheduleDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Tambah', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D32),
                  side: const BorderSide(color: Color(0xFF2E7D32)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _schedules.isEmpty
              ? const Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Text('📋', style: TextStyle(fontSize: 40)), SizedBox(height: 8), Text('Belum ada jadwal')],
                ))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _schedules.length,
                  itemBuilder: (_, i) {
                    final s = _schedules[i];
                    return Dismissible(
                      key: Key(s.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) async {
                        return await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                          title: const Text('Hapus Jadwal?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
                          ],
                        ));
                      },
                      onDismissed: (_) async {
                        await PlantService.deleteSchedule(widget.plantId, s.id);
                        _loadAll();
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.delete, color: Colors.red),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: s.isDone ? Border.all(color: Colors.green.withOpacity(0.3)) : null,
                        ),
                        child: ListTile(
                          leading: Text(s.careTypeIcon, style: const TextStyle(fontSize: 24)),
                          title: Text(s.title ?? s.careTypeLabel, style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            decoration: s.isDone ? TextDecoration.lineThrough : null,
                          )),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDateTime(s.scheduledAt),
                                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                              ),
                              if (s.frequency != null)
                                Text(
                                  '🔄 ${_frequencyLabel(s.frequency!)}',
                                  style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                                ),
                            ],
                          ),
                          trailing: s.isDone
                              ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                              : IconButton(
                                  icon: const Icon(Icons.check_circle_outline, color: Colors.grey, size: 20),
                                  onPressed: () async {
                                    await PlantService.markScheduleDone(widget.plantId, s.id);
                                    _loadAll();
                                    _showSnack('Jadwal ditandai selesai!');
                                  },
                                ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ─── Stats Tab ──────────────────────────────────────────────────
  Widget _buildStatsTab() {
    if (_stats == null) return const Center(child: Text('Belum ada data statistik'));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Grafik Tinggi Tanaman', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (_stats!.heightProgression.isEmpty)
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text('Belum ada data tinggi', style: TextStyle(color: Colors.grey))),
            )
          else
            Container(
              height: 180,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: _buildSimpleChart(),
            ),
        ],
      ),
    );
  }

  Widget _buildSimpleChart() {
    final data = _stats!.heightProgression;
    if (data.isEmpty) return const SizedBox();
    final maxH = data.map((e) => e.height).reduce((a, b) => a > b ? a : b);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((d) {
        final h = maxH > 0 ? (d.height / maxH) * 130 : 10.0;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('${d.height}', style: const TextStyle(fontSize: 8, color: Color(0xFF2E7D32))),
                Container(
                  height: h,
                  decoration: BoxDecoration(
                    color: const Color(0xFF43A047),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(d.date.length >= 10 ? d.date.substring(5) : d.date, style: const TextStyle(fontSize: 7, color: Colors.grey)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Add Menu (choose log or schedule) ──────────────────────────
  void _showAddMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Text('Tambah Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              _addMenuTile(
                icon: Icons.timeline_rounded,
                iconColor: const Color(0xFF2E7D32),
                bgColor: const Color(0xFFE8F5E9),
                title: 'Log Pertumbuhan',
                subtitle: 'Catat perkembangan tanaman',
                onTap: () { Navigator.pop(ctx); _showAddLogDialog(); },
              ),
              const SizedBox(height: 10),
              _addMenuTile(
                icon: Icons.event_note_rounded,
                iconColor: const Color(0xFF1565C0),
                bgColor: const Color(0xFFE3F2FD),
                title: 'Jadwal Perawatan',
                subtitle: 'Buat jadwal siram, pupuk, dll',
                onTap: () { Navigator.pop(ctx); _showAddScheduleDialog(); },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addMenuTile({required IconData icon, required Color iconColor, required Color bgColor, required String title, required String subtitle, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: bgColor),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Fetch weather for auto-fill ───────────────────────────────
  Future<Map<String, dynamic>?> _fetchCurrentWeather() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return null;
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low).timeout(const Duration(seconds: 5));
      final data = await WeatherService.getCurrentWeather(pos.latitude, pos.longitude);
      if (data == null) return null;
      // Parse OWM response
      final main = data['weather']?[0]?['main'] ?? '';
      final temp = (data['main']?['temp'] as num?)?.toDouble();
      String weather = 'sunny';
      final mainLower = main.toString().toLowerCase();
      if (mainLower.contains('cloud')) weather = 'cloudy';
      if (mainLower.contains('rain') || mainLower.contains('drizzle')) weather = 'rainy';
      if (mainLower.contains('thunder')) weather = 'stormy';
      if (mainLower.contains('wind') || mainLower.contains('squall')) weather = 'windy';
      return {'weather': weather, 'temp': temp};
    } catch (_) {
      return null;
    }
  }

  // ─── Add Growth Log Dialog ──────────────────────────────────────
  void _showAddLogDialog() {
    final noteCtrl = TextEditingController();
    final heightCtrl = TextEditingController();
    final leafCtrl = TextEditingController();
    final tempCtrl = TextEditingController();
    String selectedPhase = _plant?.phase ?? 'seedling';
    int healthScore = 7;
    String? selectedWeather;
    DateTime logDate = DateTime.now();
    List<File> selectedPhotos = [];
    final phases = ['seedling', 'sprouting', 'seedling_growth', 'vegetative', 'flowering', 'fruiting', 'harvesting', 'done'];
    final phaseLabels = {
      'seedling': 'Bibit', 'sprouting': 'Tumbuh', 'seedling_growth': 'Pertumbuhan Bibit',
      'vegetative': 'Vegetatif', 'flowering': 'Berbunga', 'fruiting': 'Berbuah',
      'harvesting': 'Panen', 'done': 'Selesai',
    };
    final weatherOptions = ['sunny', 'cloudy', 'rainy', 'stormy', 'windy'];
    final weatherLabels = {'sunny': '☀️ Cerah', 'cloudy': '☁️ Berawan', 'rainy': '🌧 Hujan', 'stormy': '⛈ Badai', 'windy': '💨 Berangin'};
    List<String> selectedIssues = [];
    final issueOptions = ['Hama', 'Penyakit', 'Kuning', 'Layu', 'Bercak', 'Busuk', 'Kerdil'];

    // Auto-fetch weather flag
    bool weatherFetched = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (sheetCtx, setModalState) {
          // Auto-fetch weather once
          if (!weatherFetched) {
            weatherFetched = true;
            _fetchCurrentWeather().then((w) {
              if (w != null && sheetCtx.mounted) {
                setModalState(() {
                  selectedWeather = w['weather'];
                  if (w['temp'] != null) tempCtrl.text = w['temp'].toStringAsFixed(1);
                });
              }
            });
          }
          return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(sheetCtx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tambah Log Pertumbuhan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                // Phase
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Fase Pertumbuhan', border: OutlineInputBorder(), prefixIcon: Icon(Icons.spa), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedPhase,
                      isExpanded: true,
                      items: phases.map((p) => DropdownMenuItem(value: p, child: Text(phaseLabels[p] ?? p))).toList(),
                      onChanged: (v) => setModalState(() => selectedPhase = v!),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Date
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(context: sheetCtx, initialDate: logDate, firstDate: DateTime(2020), lastDate: DateTime.now());
                    if (d != null) setModalState(() => logDate = d);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Tanggal', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today)),
                    child: Text('${logDate.day}/${logDate.month}/${logDate.year}'),
                  ),
                ),
                const SizedBox(height: 12),
                // Height & Leaf count
                Row(
                  children: [
                    Expanded(child: TextField(controller: heightCtrl, decoration: const InputDecoration(labelText: 'Tinggi (cm)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.straighten)), keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: leafCtrl, decoration: const InputDecoration(labelText: 'Jumlah Daun', border: OutlineInputBorder(), prefixIcon: Icon(Icons.eco)), keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 12),
                // Health score slider
                Text('Skor Kesehatan: $healthScore/10', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                Slider(
                  value: healthScore.toDouble(),
                  min: 1, max: 10, divisions: 9,
                  activeColor: const Color(0xFF2E7D32),
                  label: '$healthScore',
                  onChanged: (v) => setModalState(() => healthScore = v.round()),
                ),
                const SizedBox(height: 8),
                // Weather & temperature
                Row(
                  children: [
                    Expanded(
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Cuaca', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: selectedWeather,
                            isExpanded: true,
                            isDense: true,
                            items: [const DropdownMenuItem<String?>(value: null, child: Text('-')), ...weatherOptions.map((w) => DropdownMenuItem<String?>(value: w, child: Text(weatherLabels[w] ?? w)))],
                            onChanged: (v) => setModalState(() => selectedWeather = v),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: tempCtrl, decoration: const InputDecoration(labelText: 'Suhu (°C)', border: OutlineInputBorder(), isDense: true), keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 12),
                // Issues chips
                const Text('Masalah (opsional):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: issueOptions.map((issue) => FilterChip(
                    label: Text(issue, style: const TextStyle(fontSize: 11)),
                    selected: selectedIssues.contains(issue),
                    selectedColor: Colors.red.withOpacity(0.15),
                    checkmarkColor: Colors.red,
                    onSelected: (sel) => setModalState(() {
                      sel ? selectedIssues.add(issue) : selectedIssues.remove(issue);
                    }),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                // Note
                TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Catatan', border: OutlineInputBorder(), prefixIcon: Icon(Icons.note)), maxLines: 2),
                const SizedBox(height: 12),
                // Photos
                Row(
                  children: [
                    const Text('Foto:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () async {
                        showModalBottomSheet(
                          context: ctx,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                          builder: (sheetCtx) => SafeArea(
                            child: Wrap(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.camera_alt, color: Color(0xFF2E7D32)),
                                  title: const Text('Kamera'),
                                  onTap: () async {
                                    Navigator.pop(sheetCtx);
                                    final picker = ImagePicker();
                                    final picked = await picker.pickImage(source: ImageSource.camera, maxWidth: 800, imageQuality: 80);
                                    if (picked != null) setModalState(() => selectedPhotos.add(File(picked.path)));
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.photo_library, color: Color(0xFF2E7D32)),
                                  title: const Text('Galeri'),
                                  onTap: () async {
                                    Navigator.pop(sheetCtx);
                                    final picker = ImagePicker();
                                    final pickedList = await picker.pickMultiImage(maxWidth: 800, imageQuality: 80);
                                    if (pickedList.isNotEmpty) {
                                      setModalState(() => selectedPhotos.addAll(pickedList.map((p) => File(p.path))));
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                        child: const Row(children: [Icon(Icons.add_a_photo, size: 16, color: Color(0xFF2E7D32)), SizedBox(width: 4), Text('Pilih Foto', style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32)))]),
                      ),
                    ),
                  ],
                ),
                if (selectedPhotos.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 70,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: selectedPhotos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => Stack(
                        children: [
                          ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(selectedPhotos[i], width: 70, height: 70, fit: BoxFit.cover)),
                          Positioned(
                            top: 0, right: 0,
                            child: GestureDetector(
                              onTap: () => setModalState(() => selectedPhotos.removeAt(i)),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // Submit
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      _showSnack('Menyimpan log...', isLoading: true);
                      // Upload photos first
                      List<String> photoUrls = [];
                      for (final photo in selectedPhotos) {
                        final url = await CloudinaryService.uploadPlantLogPhoto(photo);
                        if (url != null) photoUrls.add(url);
                      }
                      final data = <String, dynamic>{
                        'phase': selectedPhase,
                        'logDate': '${logDate.year}-${logDate.month.toString().padLeft(2, '0')}-${logDate.day.toString().padLeft(2, '0')}',
                        'healthScore': healthScore,
                      };
                      if (noteCtrl.text.isNotEmpty) data['note'] = noteCtrl.text;
                      if (heightCtrl.text.isNotEmpty) data['height'] = double.tryParse(heightCtrl.text);
                      if (leafCtrl.text.isNotEmpty) data['leafCount'] = int.tryParse(leafCtrl.text);
                      if (selectedWeather != null) data['weather'] = selectedWeather;
                      if (tempCtrl.text.isNotEmpty) data['temperatureCelsius'] = double.tryParse(tempCtrl.text);
                      if (selectedIssues.isNotEmpty) data['issues'] = selectedIssues;
                      if (photoUrls.isNotEmpty) data['photos'] = photoUrls;

                      await PlantService.addGrowthLog(widget.plantId, data);
                      if (mounted) ScaffoldMessenger.of(context).clearSnackBars();
                      _showSnack('Log pertumbuhan berhasil disimpan!');
                      _loadAll();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Simpan Log'),
                  ),
                ),
              ],
            ),
          ),
        );},
      ),
    );
  }

  // ─── Add Schedule Dialog ────────────────────────────────────────
  void _showAddScheduleDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedType = 'watering';
    String frequency = 'daily';
    DateTime startDate = DateTime.now();
    DateTime? endDate;
    int? customDays;
    bool reminderEnabled = true;
    final types = ['watering', 'fertilizing', 'pruning', 'pesticide', 'harvesting', 'custom', 'other'];
    final typeLabels = {
      'watering': '💧 Penyiraman', 'fertilizing': '🧪 Pemupukan', 'pruning': '✂️ Pemangkasan',
      'pesticide': '🛡️ Pestisida', 'harvesting': '🌾 Panen', 'custom': '📝 Kustom', 'other': '📋 Lainnya',
    };
    final freqOptions = ['daily', 'weekly', 'biweekly', 'monthly', 'custom'];
    final freqLabels = {'daily': 'Harian', 'weekly': 'Mingguan', 'biweekly': '2 Minggu', 'monthly': 'Bulanan', 'custom': 'Custom'};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tambah Jadwal Perawatan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                // Type
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Tipe Perawatan', border: OutlineInputBorder()),
                  items: types.map((t) => DropdownMenuItem(value: t, child: Text(typeLabels[t] ?? t))).toList(),
                  onChanged: (v) => setModalState(() => selectedType = v!),
                ),
                const SizedBox(height: 12),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Judul (opsional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.title))),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Deskripsi (opsional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description)), maxLines: 2),
                const SizedBox(height: 12),
                // Frequency
                DropdownButtonFormField<String>(
                  value: frequency,
                  decoration: const InputDecoration(labelText: 'Frekuensi', border: OutlineInputBorder()),
                  items: freqOptions.map((f) => DropdownMenuItem(value: f, child: Text(freqLabels[f] ?? f))).toList(),
                  onChanged: (v) => setModalState(() => frequency = v!),
                ),
                if (frequency == 'custom') ...[
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Interval (hari)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => customDays = int.tryParse(v),
                  ),
                ],
                const SizedBox(height: 12),
                // Start & End date
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final d = await showDatePicker(context: ctx, initialDate: startDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                          if (d != null) setModalState(() => startDate = d);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Mulai', border: OutlineInputBorder(), isDense: true),
                          child: Text('${startDate.day}/${startDate.month}/${startDate.year}', style: const TextStyle(fontSize: 13)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final d = await showDatePicker(context: ctx, initialDate: endDate ?? startDate.add(const Duration(days: 30)), firstDate: startDate, lastDate: startDate.add(const Duration(days: 365)));
                          if (d != null) setModalState(() => endDate = d);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Selesai', border: OutlineInputBorder(), isDense: true),
                          child: Text(endDate != null ? '${endDate!.day}/${endDate!.month}/${endDate!.year}' : '-', style: const TextStyle(fontSize: 13)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Reminder
                SwitchListTile(
                  title: const Text('Pengingat', style: TextStyle(fontSize: 14)),
                  value: reminderEnabled,
                  activeColor: const Color(0xFF2E7D32),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setModalState(() => reminderEnabled = v),
                ),
                const SizedBox(height: 8),
                // Submit
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final data = <String, dynamic>{
                        'type': selectedType,
                        'startDate': startDate.toIso8601String(),
                        'frequency': frequency,
                        'isReminderEnabled': reminderEnabled,
                      };
                      if (titleCtrl.text.isNotEmpty) data['title'] = titleCtrl.text;
                      if (descCtrl.text.isNotEmpty) data['description'] = descCtrl.text;
                      if (endDate != null) data['endDate'] = endDate!.toIso8601String();
                      if (frequency == 'custom' && customDays != null) data['customIntervalDays'] = customDays;
                      await PlantService.createSchedule(widget.plantId, data);
                      _loadAll();
                      _showSnack('Jadwal berhasil dibuat!');
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Simpan Jadwal'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────
  void _showSnack(String msg, {bool isError = false, bool isLoading = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        if (isLoading) ...[const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)), const SizedBox(width: 12)],
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: isError ? Colors.red : const Color(0xFF2E7D32),
      duration: isLoading ? const Duration(seconds: 30) : const Duration(seconds: 2),
    ));
  }

  void _showFullImage(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Stack(
          children: [
            InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)),
            Positioned(top: 8, right: 8, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context))),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    final d = DateTime.tryParse(dateStr);
    if (d == null) return dateStr;
    return '${d.day}/${d.month}/${d.year}';
  }

  String _formatDateTime(DateTime dt) => '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _weatherIcon(String weather) {
    const icons = {'sunny': '☀️', 'cloudy': '☁️', 'rainy': '🌧', 'stormy': '⛈', 'windy': '💨'};
    return icons[weather] ?? '🌤';
  }

  String _frequencyLabel(String freq) {
    const labels = {'daily': 'Harian', 'weekly': 'Mingguan', 'biweekly': '2 Minggu', 'monthly': 'Bulanan', 'custom': 'Custom'};
    return labels[freq] ?? freq;
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Colors.white, child: tabBar);
  }
  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}
