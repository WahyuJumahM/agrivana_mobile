import 'package:flutter/material.dart';
import '../model/plant_model.dart';
import '../service/plant_service.dart';

class AddPlantScreen extends StatefulWidget {
  const AddPlantScreen({super.key});
  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  int _step = 0; // 0=category, 1=type, 2=variety, 3=details
  bool _isCustom = false; // true if user chose "Tanaman Custom"

  List<PlantCategoryModel> _categories = [];
  List<PlantTypeModel> _types = [];
  List<PlantVarietyModel> _varieties = [];
  bool _loading = true;

  PlantCategoryModel? _selectedCategory;
  PlantTypeModel? _selectedType;
  PlantVarietyModel? _selectedVariety;

  final _nameCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _mediaType = 'pot';
  DateTime _plantedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _loading = true);
    _categories = await PlantService.getCategories();
    setState(() => _loading = false);
  }

  Future<void> _loadTypes(String categoryId) async {
    setState(() => _loading = true);
    _types = await PlantService.getTypesByCategory(categoryId);
    setState(() => _loading = false);
  }

  Future<void> _loadVarieties(String typeId) async {
    setState(() => _loading = true);
    _varieties = await PlantService.getVarieties(typeId);
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _stepTitle,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            if (_step > 0) {
              if (_isCustom && _step == 3) {
                setState(() {
                  _step = 0;
                  _isCustom = false;
                });
              } else {
                setState(() => _step--);
              }
            } else {
              Navigator.pop(context);
            }
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildStepIndicator(),
        ),
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
          : _buildStep(),
    );
  }

  // ─── Step Indicator ───────────────────────────────────────────────
  Widget _buildStepIndicator() {
    final labels = ['Kategori', 'Jenis', 'Varietas', 'Detail'];
    final currentStep = _isCustom && _step == 3 ? 3 : _step;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: List.generate(4, (i) {
          final isActive = i == currentStep;
          final isDone = i < currentStep;
          return Expanded(
            child: Row(
              children: [
                if (i > 0) Expanded(
                  child: Container(
                    height: 2,
                    color: isDone ? Colors.white : Colors.white.withOpacity(0.25),
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? Colors.white
                        : isDone
                            ? Colors.white.withOpacity(0.8)
                            : Colors.white.withOpacity(0.2),
                    border: isActive ? Border.all(color: Colors.white, width: 2) : null,
                  ),
                  child: Center(
                    child: isDone
                        ? Icon(Icons.check_rounded, size: 16, color: const Color(0xFF1B5E20))
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isActive ? const Color(0xFF1B5E20) : Colors.white.withOpacity(0.6),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  String get _stepTitle {
    if (_isCustom && _step == 3) return 'Tanaman Custom';
    switch (_step) {
      case 0:
        return 'Pilih Kategori';
      case 1:
        return 'Pilih Jenis Tanaman';
      case 2:
        return 'Pilih Varietas';
      case 3:
        return 'Detail Tanaman';
      default:
        return '';
    }
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildCategoryStep();
      case 1:
        return _buildTypeStep();
      case 2:
        return _buildVarietyStep();
      case 3:
        return _buildDetailsStep();
      default:
        return const SizedBox();
    }
  }

  // ─── Step 0: Category ────────────────────────────────────────────
  Widget _buildCategoryStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ─── Custom Plant Card (top) ─────────────────
        GestureDetector(
          onTap: () {
            setState(() {
              _isCustom = true;
              _selectedCategory = null;
              _selectedType = null;
              _selectedVariety = null;
              _nameCtrl.clear();
              _step = 3;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2E7D32), Color(0xFF43A047), Color(0xFF66BB6A)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text('✏️', style: TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tanaman Custom',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Buat tanaman sendiri tanpa pilih kategori',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // ─── Divider ─────────────────────────────────
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey[300])),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('atau pilih kategori', style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
            ),
            Expanded(child: Divider(color: Colors.grey[300])),
          ],
        ),
        const SizedBox(height: 16),

        // ─── Category Cards ──────────────────────────
        ...List.generate(_categories.length, (i) {
          final cat = _categories[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  _isCustom = false;
                  _selectedCategory = cat;
                  _loadTypes(cat.id);
                  setState(() => _step = 1);
                },
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE8F5E9)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(child: Text(cat.icon ?? '🌿', style: const TextStyle(fontSize: 26))),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (cat.description != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  cat.description!,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ─── Step 1: Plant Type ──────────────────────────────────────────
  Widget _buildTypeStep() {
    if (_types.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('🌿', style: TextStyle(fontSize: 48)),
            ),
            const SizedBox(height: 16),
            const Text('Tidak ada jenis tanaman', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Kategori ini belum memiliki jenis', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isCustom = true;
                  _selectedType = null;
                  _selectedVariety = null;
                  _nameCtrl.clear();
                  _step = 3;
                });
              },
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('Buat Tanaman Custom'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: _types.length,
      itemBuilder: (_, i) {
        final type = _types[i];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              _selectedType = type;
              _nameCtrl.text = type.name;
              _loadVarieties(type.id);
              setState(() => _step = 2);
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8F5E9)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: Text(type.icon ?? '🌱', style: const TextStyle(fontSize: 24))),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    type.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Step 2: Variety ─────────────────────────────────────────────
  Widget _buildVarietyStep() {
    return Column(
      children: [
        if (_varieties.isNotEmpty)
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _varieties.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final v = _varieties[i];
                final isSelected = _selectedVariety?.id == v.id;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => setState(() {
                      _selectedVariety = v;
                      _nameCtrl.text = v.name;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFFE0E0E0),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFC8E6C9) : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(child: Text(v.icon ?? '🌿', style: const TextStyle(fontSize: 20))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  v.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? const Color(0xFF1B5E20) : Colors.black87,
                                  ),
                                ),
                                if (v.description != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Text(
                                      v.description!,
                                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF2E7D32),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        else
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('🌿', style: TextStyle(fontSize: 48)),
                  ),
                  const SizedBox(height: 16),
                  const Text('Tidak ada varietas tersedia', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text('Lanjutkan ke detail tanaman', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => setState(() => _step = 3),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(
                _selectedVariety != null ? 'Lanjutkan' : 'Lewati & Lanjutkan',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Step 3: Details ─────────────────────────────────────────────
  Widget _buildDetailsStep() {
    final mediaOptions = ['pot', 'ground', 'hydroponic', 'grow_bag', 'polybag', 'tanah_sawah'];
    final mediaLabels = {
      'pot': 'Pot',
      'ground': 'Tanah Langsung',
      'hydroponic': 'Hidroponik',
      'grow_bag': 'Grow Bag',
      'polybag': 'Polybag',
      'tanah_sawah': 'Tanah Sawah',
    };

    InputDecoration inputDeco(String label, IconData icon, {String? hint}) => InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
      filled: true,
      fillColor: const Color(0xFFF5F8F5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isCustom ? [const Color(0xFFF1F8E9), const Color(0xFFE8F5E9)] : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
              ),
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
                  child: Center(
                    child: Text(
                      _isCustom ? '✏️' : (_selectedType?.icon ?? '🌱'),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isCustom
                            ? 'Tanaman Custom'
                            : '${_selectedCategory?.name ?? ''} › ${_selectedType?.name ?? ''}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1B5E20),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (!_isCustom && _selectedVariety != null)
                        Text(
                          _selectedVariety!.name,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      if (_isCustom)
                        Text(
                          'Isi nama dan detail tanaman kamu sendiri',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _nameCtrl,
            decoration: inputDeco('Nama Tanaman *', Icons.local_florist_rounded, hint: _isCustom ? 'Contoh: Cabai Rawit Merah' : null),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _mediaType,
            decoration: inputDeco('Media Tanam', Icons.eco_rounded),
            items: mediaOptions
                .map((m) => DropdownMenuItem(value: m, child: Text(mediaLabels[m] ?? m)))
                .toList(),
            onChanged: (v) => setState(() => _mediaType = v!),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _plantedAt,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (d != null) setState(() => _plantedAt = d);
            },
            child: InputDecorator(
              decoration: inputDeco('Tanggal Tanam', Icons.calendar_today_rounded),
              child: Text(
                '${_plantedAt.day}/${_plantedAt.month}/${_plantedAt.year}',
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _locCtrl,
            decoration: inputDeco('Lokasi (opsional)', Icons.location_on_rounded, hint: 'Contoh: Halaman belakang'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _areaCtrl,
            decoration: inputDeco('Luas Area (m²) - Opsional', Icons.straighten_rounded),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesCtrl,
            decoration: inputDeco('Catatan (opsional)', Icons.notes_rounded, hint: 'Info tambahan tentang tanaman'),
            maxLines: 3,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                shadowColor: const Color(0xFF2E7D32).withOpacity(0.3),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Tambah Tanaman',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Nama tanaman wajib diisi'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    final result = await PlantService.addPlant(
      plantTypeId: _selectedType?.id,
      varietyId: _selectedVariety?.id,
      customName: _nameCtrl.text,
      plantedAt:
          '${_plantedAt.year}-${_plantedAt.month.toString().padLeft(2, '0')}-${_plantedAt.day.toString().padLeft(2, '0')}',
      mediaType: _mediaType,
      locationDesc: _locCtrl.text.isNotEmpty ? _locCtrl.text : null,
      areaSize: _areaCtrl.text.isNotEmpty
          ? double.tryParse(_areaCtrl.text)
          : null,
      areaSizeUnit: _areaCtrl.text.isNotEmpty ? 'm2' : null,
      notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message.isNotEmpty
                ? result.message
                : 'Tanaman berhasil ditambahkan!',
          ),
          backgroundColor: result.success ? const Color(0xFF2E7D32) : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      if (result.success) Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locCtrl.dispose();
    _areaCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }
}
