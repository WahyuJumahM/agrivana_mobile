// ─── Plant Category ─────────────────────────────────────────────────
class PlantCategoryModel {
  final String id;
  final String name;
  final String? icon;
  final String? description;

  PlantCategoryModel({
    required this.id,
    required this.name,
    this.icon,
    this.description,
  });

  factory PlantCategoryModel.fromJson(Map<String, dynamic> json) {
    return PlantCategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'],
      description: json['description'],
    );
  }
}

// ─── Plant Type ─────────────────────────────────────────────────────
class PlantTypeModel {
  final String id;
  final String name;
  final String? scientificName;
  final String? aiStatus;
  final String? description;
  final String? icon;
  final String accessTier; // free | premium
  final String? modelAccuracy;
  final String? categoryId;
  final String? categoryName;

  PlantTypeModel({
    required this.id,
    required this.name,
    this.scientificName,
    this.aiStatus,
    this.description,
    this.icon,
    this.accessTier = 'free',
    this.modelAccuracy,
    this.categoryId,
    this.categoryName,
  });

  bool get isFree => accessTier == 'free';
  bool get isPremium => accessTier == 'premium';

  factory PlantTypeModel.fromJson(Map<String, dynamic> json) {
    return PlantTypeModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      scientificName: json['scientificName'],
      aiStatus: json['aiStatus'],
      description: json['description'],
      icon: json['icon'],
      accessTier: json['accessTier'] ?? 'free',
      modelAccuracy: json['modelAccuracy'],
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
    );
  }
}

// ─── Plant Variety ──────────────────────────────────────────────────
class PlantVarietyModel {
  final String id;
  final String name;
  final String? description;
  final String? icon;

  PlantVarietyModel({
    required this.id,
    required this.name,
    this.description,
    this.icon,
  });

  factory PlantVarietyModel.fromJson(Map<String, dynamic> json) {
    return PlantVarietyModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      icon: json['icon'],
    );
  }
}

// ─── User Plant ─────────────────────────────────────────────────────
class UserPlantModel {
  final String id;
  final String name;
  final String phase;
  final String health;
  final String plantedAt;
  final String? coverPhoto;
  final String? plantType;
  final String? plantIcon;
  final String? varietyName;
  final double? areaSize;
  final String? areaSizeUnit;
  final String? categoryName;
  // Detail fields
  final String? mediaType;
  final String? locationDesc;
  final String? notes;
  final String? scientificName;
  final String? categoryIcon;

  UserPlantModel({
    required this.id,
    required this.name,
    required this.phase,
    required this.health,
    required this.plantedAt,
    this.coverPhoto,
    this.plantType,
    this.plantIcon,
    this.varietyName,
    this.areaSize,
    this.areaSizeUnit,
    this.categoryName,
    this.mediaType,
    this.locationDesc,
    this.notes,
    this.scientificName,
    this.categoryIcon,
  });

  int get daysSincePlanted {
    final date = DateTime.tryParse(plantedAt);
    if (date == null) return 0;
    return DateTime.now().difference(date).inDays;
  }

  String get phaseLabel {
    const labels = {
      'seedling': 'Bibit',
      'sprouting': 'Tumbuh',
      'seedling_growth': 'Pertumbuhan Bibit',
      'vegetative': 'Vegetatif',
      'flowering': 'Berbunga',
      'fruiting': 'Berbuah',
      'harvesting': 'Panen',
      'done': 'Selesai',
    };
    return labels[phase] ?? phase;
  }

  String get healthLabel {
    const labels = {
      'healthy': 'Sehat',
      'needs_attention': 'Perlu Perhatian',
      'sick': 'Sakit',
    };
    return labels[health] ?? health;
  }

  factory UserPlantModel.fromJson(Map<String, dynamic> json) {
    return UserPlantModel(
      id: json['id'] ?? '',
      name: json['customName'] ?? json['name'] ?? '',
      phase: json['currentPhase'] ?? json['phase'] ?? 'seedling',
      health: json['healthStatus'] ?? json['health'] ?? 'healthy',
      plantedAt: json['plantedAt'] ?? '',
      coverPhoto: json['coverPhoto'],
      plantType: json['plantTypeName'] ?? json['plantType'],
      plantIcon: json['plantTypeIcon'] ?? json['plantIcon'],
      varietyName: json['varietyName'],
      areaSize: json['areaSize'] != null ? (json['areaSize'] as num).toDouble() : null,
      areaSizeUnit: json['areaSizeUnit'],
      categoryName: json['categoryName'],
      mediaType: json['mediaType'],
      locationDesc: json['locationDesc'],
      notes: json['notes'],
      scientificName: json['scientificName'],
      categoryIcon: json['categoryIcon'],
    );
  }
}

// ─── Growth Log ─────────────────────────────────────────────────────
class GrowthLogModel {
  final String id;
  final String phase;
  final String? note;
  final String logDate;
  final double? heightCm;
  final int? leafCount;
  final int? healthScore;
  final String? weather;
  final double? temperatureCelsius;
  final List<String>? issues;
  final List<LogPhotoModel> photos;
  final String? createdAt;

  GrowthLogModel({
    required this.id,
    required this.phase,
    this.note,
    required this.logDate,
    this.heightCm,
    this.leafCount,
    this.healthScore,
    this.weather,
    this.temperatureCelsius,
    this.issues,
    this.photos = const [],
    this.createdAt,
  });

  String get phaseLabel {
    const labels = {
      'seedling': 'Bibit',
      'sprouting': 'Tumbuh',
      'seedling_growth': 'Pertumbuhan Bibit',
      'vegetative': 'Vegetatif',
      'flowering': 'Berbunga',
      'fruiting': 'Berbuah',
      'harvesting': 'Panen',
      'done': 'Selesai',
    };
    return labels[phase] ?? phase;
  }

  factory GrowthLogModel.fromJson(Map<String, dynamic> json) {
    return GrowthLogModel(
      id: json['id'] ?? '',
      phase: json['phase'] ?? 'seedling',
      note: json['note'],
      logDate: json['logDate'] ?? '',
      heightCm: json['heightCm'] != null ? (json['heightCm'] as num).toDouble() : null,
      leafCount: json['leafCount'],
      healthScore: json['healthScore'],
      weather: json['weather'],
      temperatureCelsius: json['temperatureCelsius'] != null
          ? (json['temperatureCelsius'] as num).toDouble()
          : null,
      issues: json['issues'] != null ? List<String>.from(json['issues']) : null,
      photos: json['photos'] != null
          ? (json['photos'] as List).map((p) => LogPhotoModel.fromJson(p)).toList()
          : [],
      createdAt: json['createdAt'],
    );
  }
}

class LogPhotoModel {
  final String id;
  final String url;
  final int sortOrder;

  LogPhotoModel({required this.id, required this.url, this.sortOrder = 0});

  factory LogPhotoModel.fromJson(Map<String, dynamic> json) {
    return LogPhotoModel(
      id: json['id'] ?? '',
      url: json['url'] ?? '',
      sortOrder: json['sortOrder'] ?? 0,
    );
  }
}

// ─── Care Schedule ──────────────────────────────────────────────────
class CareScheduleModel {
  final String id;
  final String careType;
  final String? title;
  final String? description;
  final DateTime scheduledAt;
  final bool isDone;
  final DateTime? doneAt;
  final String? notes;
  final String? frequency;
  final int? customIntervalDays;
  final String? reminderTime;
  final bool isReminderEnabled;
  // From today endpoint
  final String? plantName;
  final String? plantType;
  final String? plantIcon;

  CareScheduleModel({
    required this.id,
    required this.careType,
    this.title,
    this.description,
    required this.scheduledAt,
    this.isDone = false,
    this.doneAt,
    this.notes,
    this.frequency,
    this.customIntervalDays,
    this.reminderTime,
    this.isReminderEnabled = true,
    this.plantName,
    this.plantType,
    this.plantIcon,
  });

  String get careTypeLabel {
    const labels = {
      'watering': 'Penyiraman',
      'fertilizing': 'Pemupukan',
      'pruning': 'Pemangkasan',
      'pesticide': 'Pestisida',
      'harvesting': 'Panen',
      'custom': 'Kustom',
      'other': 'Lainnya',
    };
    return labels[careType] ?? careType;
  }

  String get careTypeIcon {
    const icons = {
      'watering': '💧',
      'fertilizing': '🧪',
      'pruning': '✂️',
      'pesticide': '🛡️',
      'harvesting': '🌾',
      'custom': '📝',
      'other': '📋',
    };
    return icons[careType] ?? '📋';
  }

  factory CareScheduleModel.fromJson(Map<String, dynamic> json) {
    return CareScheduleModel(
      id: json['id'] ?? '',
      careType: json['careType'] ?? 'other',
      title: json['title'],
      description: json['description'],
      scheduledAt: DateTime.tryParse(json['scheduledAt'] ?? '') ?? DateTime.now(),
      isDone: json['isDone'] ?? false,
      doneAt: json['doneAt'] != null ? DateTime.tryParse(json['doneAt']) : null,
      notes: json['notes'],
      frequency: json['frequency'],
      customIntervalDays: json['customIntervalDays'],
      reminderTime: json['reminderTime'],
      isReminderEnabled: json['isReminderEnabled'] ?? true,
      plantName: json['plantName'],
      plantType: json['plantType'],
      plantIcon: json['plantIcon'],
    );
  }
}

// ─── Scan Available Plant ───────────────────────────────────────────
class ScanAvailablePlantModel {
  final String id;
  final String name;
  final String? icon;
  final String accessTier;
  final bool isAccessible;
  final String? lockMessage;
  final String? modelStatus;
  final String? modelAccuracy;
  final List<String> diseases;

  ScanAvailablePlantModel({
    required this.id,
    required this.name,
    this.icon,
    required this.accessTier,
    required this.isAccessible,
    this.lockMessage,
    this.modelStatus,
    this.modelAccuracy,
    this.diseases = const [],
  });

  factory ScanAvailablePlantModel.fromJson(Map<String, dynamic> json) {
    return ScanAvailablePlantModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'],
      accessTier: json['accessTier'] ?? 'free',
      isAccessible: json['isAccessible'] ?? true,
      lockMessage: json['lockMessage'],
      modelStatus: json['modelStatus'],
      modelAccuracy: json['modelAccuracy'],
      diseases: json['diseases'] != null ? List<String>.from(json['diseases']) : [],
    );
  }
}

// ─── Plant Stats ────────────────────────────────────────────────────
class PlantStatsModel {
  final List<HeightDataPoint> heightProgression;
  final int? latestHealthScore;
  final int totalLogs;
  final int daysSincePlanted;
  final int pendingSchedules;

  PlantStatsModel({
    this.heightProgression = const [],
    this.latestHealthScore,
    this.totalLogs = 0,
    this.daysSincePlanted = 0,
    this.pendingSchedules = 0,
  });

  factory PlantStatsModel.fromJson(Map<String, dynamic> json) {
    return PlantStatsModel(
      heightProgression: json['heightProgression'] != null
          ? (json['heightProgression'] as List).map((h) => HeightDataPoint.fromJson(h)).toList()
          : [],
      latestHealthScore: json['latestHealthScore'],
      totalLogs: json['totalLogs'] ?? 0,
      daysSincePlanted: json['daysSincePlanted'] ?? 0,
      pendingSchedules: json['pendingSchedules'] ?? 0,
    );
  }
}

class HeightDataPoint {
  final String date;
  final double height;

  HeightDataPoint({required this.date, required this.height});

  factory HeightDataPoint.fromJson(Map<String, dynamic> json) {
    return HeightDataPoint(
      date: json['date'] ?? '',
      height: (json['height'] as num).toDouble(),
    );
  }
}

// ─── Plant Summary ──────────────────────────────────────────────────
class PlantSummaryModel {
  final int totalActivePlants;
  final int needsAttention;
  final int todayPendingSchedules;

  PlantSummaryModel({
    this.totalActivePlants = 0,
    this.needsAttention = 0,
    this.todayPendingSchedules = 0,
  });

  factory PlantSummaryModel.fromJson(Map<String, dynamic> json) {
    return PlantSummaryModel(
      totalActivePlants: json['totalActivePlants'] ?? 0,
      needsAttention: json['needsAttention'] ?? 0,
      todayPendingSchedules: json['todayPendingSchedules'] ?? 0,
    );
  }
}
