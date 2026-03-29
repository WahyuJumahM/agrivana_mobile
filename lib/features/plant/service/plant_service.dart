// import 'dart:convert';
import '../../../services/api_service.dart';
import '../../../services/api_config.dart';
import '../model/plant_model.dart';

class PlantService {
  // ─── Categories & Hierarchy ───────────────────────────────────────

  static Future<List<PlantCategoryModel>> getCategories() async {
    final res = await ApiService.get(ApiConfig.plantCategories);
    if (res.success && res.data is List) {
      return (res.data as List).map((e) => PlantCategoryModel.fromJson(e)).toList();
    }
    return [];
  }

  static Future<List<PlantTypeModel>> getTypesByCategory(String categoryId) async {
    final res = await ApiService.get('${ApiConfig.plantCategories}/$categoryId/types');
    if (res.success && res.data is List) {
      return (res.data as List).map((e) => PlantTypeModel.fromJson(e)).toList();
    }
    return [];
  }

  static Future<List<PlantVarietyModel>> getVarieties(String plantTypeId) async {
    final res = await ApiService.get('/api/plant-types/$plantTypeId/varieties');
    if (res.success && res.data is List) {
      return (res.data as List).map((e) => PlantVarietyModel.fromJson(e)).toList();
    }
    return [];
  }

  // ─── Plant Types (all) ────────────────────────────────────────────

  static Future<List<PlantTypeModel>> getPlantTypes() async {
    final res = await ApiService.get(ApiConfig.plantTypes);
    if (res.success && res.data is List) {
      return (res.data as List).map((e) => PlantTypeModel.fromJson(e)).toList();
    }
    return [];
  }

  // ─── Plants CRUD ──────────────────────────────────────────────────

  static Future<List<UserPlantModel>> getUserPlants({String? categoryId}) async {
    final endpoint = categoryId != null
        ? '${ApiConfig.plants}?categoryId=$categoryId'
        : ApiConfig.plants;
    final res = await ApiService.get(endpoint, auth: true);
    if (res.success && res.data is List) {
      return (res.data as List).map((e) => UserPlantModel.fromJson(e)).toList();
    }
    return [];
  }

  static Future<ApiResult> addPlant({
    String? plantTypeId,
    String? varietyId,
    required String customName,
    required String plantedAt,
    required String mediaType,
    String? locationDesc,
    double? areaSize,
    String? areaSizeUnit,
    String? notes,
  }) {
    return ApiService.post(ApiConfig.plants, auth: true, body: {
      'customName': customName,
      'plantedAt': plantedAt,
      'mediaType': mediaType,
      if (plantTypeId != null) 'plantTypeId': plantTypeId,
      if (varietyId != null) 'varietyId': varietyId,
      if (locationDesc != null) 'locationDesc': locationDesc,
      if (areaSize != null) 'areaSize': areaSize,
      if (areaSizeUnit != null) 'areaSizeUnit': areaSizeUnit,
      if (notes != null) 'notes': notes,
    });
  }

  static Future<UserPlantModel?> getPlantDetail(String plantId) async {
    final res = await ApiService.get('${ApiConfig.plants}/$plantId', auth: true);
    if (res.success && res.data != null) {
      return UserPlantModel.fromJson(res.data);
    }
    return null;
  }

  static Future<ApiResult> updatePlant(String plantId, Map<String, dynamic> data) {
    return ApiService.put('${ApiConfig.plants}/$plantId', auth: true, body: data);
  }

  static Future<ApiResult> deletePlant(String plantId) {
    return ApiService.delete('${ApiConfig.plants}/$plantId', auth: true);
  }

  // ─── Growth Logs ──────────────────────────────────────────────────

  static Future<List<GrowthLogModel>> getGrowthLogs(String plantId) async {
    final res = await ApiService.get('${ApiConfig.plants}/$plantId/logs', auth: true);
    if (res.success && res.data is List) {
      return (res.data as List).map((e) => GrowthLogModel.fromJson(e)).toList();
    }
    return [];
  }

  static Future<ApiResult> addGrowthLog(String plantId, Map<String, dynamic> data) {
    return ApiService.post('${ApiConfig.plants}/$plantId/logs', auth: true, body: data);
  }

  static Future<ApiResult> updateGrowthLog(String plantId, String logId, Map<String, dynamic> data) {
    return ApiService.put('${ApiConfig.plants}/$plantId/logs/$logId', auth: true, body: data);
  }

  static Future<ApiResult> deleteGrowthLog(String plantId, String logId) {
    return ApiService.delete('${ApiConfig.plants}/$plantId/logs/$logId', auth: true);
  }

  // ─── Plant Stats & Summary ────────────────────────────────────────

  static Future<PlantStatsModel?> getPlantStats(String plantId) async {
    final res = await ApiService.get('${ApiConfig.plants}/$plantId/stats', auth: true);
    if (res.success && res.data != null) {
      return PlantStatsModel.fromJson(res.data);
    }
    return null;
  }

  static Future<PlantSummaryModel> getPlantSummary() async {
    final res = await ApiService.get(ApiConfig.plantSummary, auth: true);
    if (res.success && res.data != null) {
      return PlantSummaryModel.fromJson(res.data);
    }
    return PlantSummaryModel();
  }

  // ─── Schedules ────────────────────────────────────────────────────

  static Future<List<CareScheduleModel>> getSchedules(String plantId) async {
    final res = await ApiService.get('${ApiConfig.plants}/$plantId/schedules', auth: true);
    if (res.success && res.data is List) {
      return (res.data as List).map((e) => CareScheduleModel.fromJson(e)).toList();
    }
    return [];
  }

  static Future<ApiResult> createSchedule(String plantId, Map<String, dynamic> data) {
    return ApiService.post('${ApiConfig.plants}/$plantId/schedules', auth: true, body: data);
  }

  static Future<ApiResult> updateSchedule(String plantId, String scheduleId, Map<String, dynamic> data) {
    return ApiService.put('${ApiConfig.plants}/$plantId/schedules/$scheduleId', auth: true, body: data);
  }

  static Future<ApiResult> deleteSchedule(String plantId, String scheduleId) {
    return ApiService.delete('${ApiConfig.plants}/$plantId/schedules/$scheduleId', auth: true);
  }

  static Future<ApiResult> markScheduleDone(String plantId, String scheduleId) {
    return ApiService.post('${ApiConfig.plants}/$plantId/schedules/$scheduleId/done', auth: true);
  }

  static Future<ApiResult> generateSchedules(String plantId) {
    return ApiService.post('${ApiConfig.plants}/$plantId/schedules/generate', auth: true);
  }

  static Future<String?> exportSchedulesCsv(String plantId) async {
    final res = await ApiService.get('${ApiConfig.plants}/$plantId/schedules/export', auth: true);
    if (res.success && res.data != null) {
      return res.data.toString();
    }
    return null;
  }

  // ─── Today Schedules ──────────────────────────────────────────────

  static Future<List<CareScheduleModel>> getTodaySchedules() async {
    final res = await ApiService.get(ApiConfig.todaySchedules, auth: true);
    if (res.success && res.data is List) {
      return (res.data as List).map((e) => CareScheduleModel.fromJson(e)).toList();
    }
    return [];
  }
}

// ─── AI Scan Service ────────────────────────────────────────────────

class AiScanService {
  static Future<List<ScanAvailablePlantModel>> getAvailablePlants() async {
    // This endpoint supports both auth and non-auth
    final res = await ApiService.get(ApiConfig.scanAvailablePlants, auth: ApiService.isLoggedIn);
    if (res.success && res.data is List) {
      return (res.data as List).map((e) => ScanAvailablePlantModel.fromJson(e)).toList();
    }
    return [];
  }

  static Future<ApiResult> scan({
    required String plantTypeId,
    required String imageBase64,
    String source = 'camera',
    String? userPlantId,
  }) {
    return ApiService.post(ApiConfig.scan, auth: true, body: {
      'plantTypeId': plantTypeId,
      'imageBase64': imageBase64,
      'source': source,
      if (userPlantId != null) 'userPlantId': userPlantId,
    });
  }

  static Future<ApiResult> getScanDetail(String scanId) {
    return ApiService.get('${ApiConfig.scan}/$scanId', auth: true);
  }

  static Future<ApiResult> submitFeedback(String scanId, String feedback) {
    return ApiService.post('${ApiConfig.scan}/$scanId/feedback', auth: true, body: {
      'feedback': feedback,
    });
  }

  static Future<List<dynamic>> getScanHistory({int page = 1}) async {
    final res = await ApiService.get('${ApiConfig.scanHistory}?page=$page', auth: true);
    if (res.success && res.data is List) return res.data as List;
    return [];
  }
}
