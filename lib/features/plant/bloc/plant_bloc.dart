import 'package:flutter_bloc/flutter_bloc.dart';
import '../model/plant_model.dart';
import '../service/plant_service.dart';

// ─── Events ─────────────────────────────────────────────────────────

abstract class PlantEvent {}

class LoadPlantData extends PlantEvent {}

class LoadCategories extends PlantEvent {}

class LoadTypesByCategory extends PlantEvent {
  final String categoryId;
  LoadTypesByCategory(this.categoryId);
}

class LoadVarietiesByType extends PlantEvent {
  final String plantTypeId;
  LoadVarietiesByType(this.plantTypeId);
}

class LoadPlantDetail extends PlantEvent {
  final String plantId;
  LoadPlantDetail(this.plantId);
}

class AddPlant extends PlantEvent {
  final String? plantTypeId;
  final String? varietyId;
  final String customName;
  final String plantedAt;
  final String mediaType;
  final String? locationDesc;
  final double? areaSize;
  final String? areaSizeUnit;
  final String? notes;

  AddPlant({
    this.plantTypeId,
    this.varietyId,
    required this.customName,
    required this.plantedAt,
    required this.mediaType,
    this.locationDesc,
    this.areaSize,
    this.areaSizeUnit,
    this.notes,
  });
}

class DeletePlant extends PlantEvent {
  final String plantId;
  DeletePlant(this.plantId);
}

class LoadGrowthLogs extends PlantEvent {
  final String plantId;
  LoadGrowthLogs(this.plantId);
}

class AddGrowthLog extends PlantEvent {
  final String plantId;
  final Map<String, dynamic> data;
  AddGrowthLog({required this.plantId, required this.data});
}

class DeleteGrowthLog extends PlantEvent {
  final String plantId;
  final String logId;
  DeleteGrowthLog({required this.plantId, required this.logId});
}

class LoadSchedules extends PlantEvent {
  final String plantId;
  LoadSchedules(this.plantId);
}

class CreateSchedule extends PlantEvent {
  final String plantId;
  final Map<String, dynamic> data;
  CreateSchedule({required this.plantId, required this.data});
}

class DeleteSchedule extends PlantEvent {
  final String plantId;
  final String scheduleId;
  DeleteSchedule({required this.plantId, required this.scheduleId});
}

class MarkScheduleDone extends PlantEvent {
  final String plantId;
  final String scheduleId;
  MarkScheduleDone({required this.plantId, required this.scheduleId});
}

class GenerateSchedules extends PlantEvent {
  final String plantId;
  GenerateSchedules(this.plantId);
}

class LoadPlantStats extends PlantEvent {
  final String plantId;
  LoadPlantStats(this.plantId);
}

// ─── States ─────────────────────────────────────────────────────────

abstract class PlantState {}

class PlantInitial extends PlantState {}

class PlantLoading extends PlantState {}

class PlantLoaded extends PlantState {
  final List<UserPlantModel> plants;
  final List<PlantTypeModel> plantTypes;
  final PlantSummaryModel summary;
  final List<PlantCategoryModel> categories;

  PlantLoaded({
    this.plants = const [],
    this.plantTypes = const [],
    PlantSummaryModel? summary,
    this.categories = const [],
  }) : summary = summary ?? PlantSummaryModel();
}

class CategoriesLoaded extends PlantState {
  final List<PlantCategoryModel> categories;
  CategoriesLoaded(this.categories);
}

class TypesLoaded extends PlantState {
  final List<PlantTypeModel> types;
  TypesLoaded(this.types);
}

class VarietiesLoaded extends PlantState {
  final List<PlantVarietyModel> varieties;
  VarietiesLoaded(this.varieties);
}

class PlantDetailLoaded extends PlantState {
  final UserPlantModel plant;
  PlantDetailLoaded(this.plant);
}

class GrowthLogsLoaded extends PlantState {
  final List<GrowthLogModel> logs;
  GrowthLogsLoaded(this.logs);
}

class SchedulesLoaded extends PlantState {
  final List<CareScheduleModel> schedules;
  SchedulesLoaded(this.schedules);
}

class PlantStatsLoaded extends PlantState {
  final PlantStatsModel stats;
  PlantStatsLoaded(this.stats);
}

class PlantError extends PlantState {
  final String message;
  PlantError(this.message);
}

class PlantActionSuccess extends PlantState {
  final String message;
  PlantActionSuccess(this.message);
}

// ─── Bloc ───────────────────────────────────────────────────────────

class PlantBloc extends Bloc<PlantEvent, PlantState> {
  PlantBloc() : super(PlantInitial()) {
    on<LoadPlantData>(_onLoadPlantData);
    on<LoadCategories>(_onLoadCategories);
    on<LoadTypesByCategory>(_onLoadTypesByCategory);
    on<LoadVarietiesByType>(_onLoadVarietiesByType);
    on<LoadPlantDetail>(_onLoadPlantDetail);
    on<AddPlant>(_onAddPlant);
    on<DeletePlant>(_onDeletePlant);
    on<LoadGrowthLogs>(_onLoadGrowthLogs);
    on<AddGrowthLog>(_onAddGrowthLog);
    on<DeleteGrowthLog>(_onDeleteGrowthLog);
    on<LoadSchedules>(_onLoadSchedules);
    on<CreateSchedule>(_onCreateSchedule);
    on<DeleteSchedule>(_onDeleteSchedule);
    on<MarkScheduleDone>(_onMarkScheduleDone);
    on<GenerateSchedules>(_onGenerateSchedules);
    on<LoadPlantStats>(_onLoadPlantStats);
  }

  Future<void> _onLoadPlantData(LoadPlantData event, Emitter<PlantState> emit) async {
    emit(PlantLoading());
    try {
      final results = await Future.wait([
        PlantService.getUserPlants(),
        PlantService.getPlantTypes(),
        PlantService.getPlantSummary(),
        PlantService.getCategories(),
      ]);
      emit(PlantLoaded(
        plants: results[0] as List<UserPlantModel>,
        plantTypes: results[1] as List<PlantTypeModel>,
        summary: results[2] as PlantSummaryModel,
        categories: results[3] as List<PlantCategoryModel>,
      ));
    } catch (e) {
      emit(PlantError('Gagal memuat data: $e'));
    }
  }

  Future<void> _onLoadCategories(LoadCategories event, Emitter<PlantState> emit) async {
    emit(PlantLoading());
    try {
      final categories = await PlantService.getCategories();
      emit(CategoriesLoaded(categories));
    } catch (e) {
      emit(PlantError('Gagal memuat kategori: $e'));
    }
  }

  Future<void> _onLoadTypesByCategory(LoadTypesByCategory event, Emitter<PlantState> emit) async {
    emit(PlantLoading());
    try {
      final types = await PlantService.getTypesByCategory(event.categoryId);
      emit(TypesLoaded(types));
    } catch (e) {
      emit(PlantError('Gagal memuat tipe tanaman: $e'));
    }
  }

  Future<void> _onLoadVarietiesByType(LoadVarietiesByType event, Emitter<PlantState> emit) async {
    emit(PlantLoading());
    try {
      final varieties = await PlantService.getVarieties(event.plantTypeId);
      emit(VarietiesLoaded(varieties));
    } catch (e) {
      emit(PlantError('Gagal memuat varietas: $e'));
    }
  }

  Future<void> _onLoadPlantDetail(LoadPlantDetail event, Emitter<PlantState> emit) async {
    emit(PlantLoading());
    try {
      final plant = await PlantService.getPlantDetail(event.plantId);
      if (plant != null) {
        emit(PlantDetailLoaded(plant));
      } else {
        emit(PlantError('Tanaman tidak ditemukan.'));
      }
    } catch (e) {
      emit(PlantError('Gagal memuat detail: $e'));
    }
  }

  Future<void> _onAddPlant(AddPlant event, Emitter<PlantState> emit) async {
    try {
      await PlantService.addPlant(
        plantTypeId: event.plantTypeId,
        varietyId: event.varietyId,
        customName: event.customName,
        plantedAt: event.plantedAt,
        mediaType: event.mediaType,
        locationDesc: event.locationDesc,
        areaSize: event.areaSize,
        areaSizeUnit: event.areaSizeUnit,
        notes: event.notes,
      );
      emit(PlantActionSuccess('Tanaman berhasil ditambahkan!'));
      add(LoadPlantData());
    } catch (e) {
      emit(PlantError('Gagal menambahkan tanaman: $e'));
    }
  }

  Future<void> _onDeletePlant(DeletePlant event, Emitter<PlantState> emit) async {
    try {
      await PlantService.deletePlant(event.plantId);
      emit(PlantActionSuccess('Tanaman berhasil dihapus.'));
      add(LoadPlantData());
    } catch (e) {
      emit(PlantError('Gagal menghapus tanaman: $e'));
    }
  }

  Future<void> _onLoadGrowthLogs(LoadGrowthLogs event, Emitter<PlantState> emit) async {
    emit(PlantLoading());
    try {
      final logs = await PlantService.getGrowthLogs(event.plantId);
      emit(GrowthLogsLoaded(logs));
    } catch (e) {
      emit(PlantError('Gagal memuat logs: $e'));
    }
  }

  Future<void> _onAddGrowthLog(AddGrowthLog event, Emitter<PlantState> emit) async {
    try {
      await PlantService.addGrowthLog(event.plantId, event.data);
      emit(PlantActionSuccess('Log pertumbuhan berhasil disimpan!'));
      add(LoadGrowthLogs(event.plantId));
    } catch (e) {
      emit(PlantError('Gagal menyimpan log: $e'));
    }
  }

  Future<void> _onDeleteGrowthLog(DeleteGrowthLog event, Emitter<PlantState> emit) async {
    try {
      await PlantService.deleteGrowthLog(event.plantId, event.logId);
      emit(PlantActionSuccess('Log berhasil dihapus.'));
      add(LoadGrowthLogs(event.plantId));
    } catch (e) {
      emit(PlantError('Gagal menghapus log: $e'));
    }
  }

  Future<void> _onLoadSchedules(LoadSchedules event, Emitter<PlantState> emit) async {
    emit(PlantLoading());
    try {
      final schedules = await PlantService.getSchedules(event.plantId);
      emit(SchedulesLoaded(schedules));
    } catch (e) {
      emit(PlantError('Gagal memuat jadwal: $e'));
    }
  }

  Future<void> _onCreateSchedule(CreateSchedule event, Emitter<PlantState> emit) async {
    try {
      await PlantService.createSchedule(event.plantId, event.data);
      emit(PlantActionSuccess('Jadwal berhasil dibuat!'));
      add(LoadSchedules(event.plantId));
    } catch (e) {
      emit(PlantError('Gagal membuat jadwal: $e'));
    }
  }

  Future<void> _onDeleteSchedule(DeleteSchedule event, Emitter<PlantState> emit) async {
    try {
      await PlantService.deleteSchedule(event.plantId, event.scheduleId);
      emit(PlantActionSuccess('Jadwal berhasil dihapus.'));
      add(LoadSchedules(event.plantId));
    } catch (e) {
      emit(PlantError('Gagal menghapus jadwal: $e'));
    }
  }

  Future<void> _onMarkScheduleDone(MarkScheduleDone event, Emitter<PlantState> emit) async {
    try {
      await PlantService.markScheduleDone(event.plantId, event.scheduleId);
      emit(PlantActionSuccess('Jadwal ditandai selesai!'));
      add(LoadSchedules(event.plantId));
    } catch (e) {
      emit(PlantError('Gagal menandai jadwal: $e'));
    }
  }

  Future<void> _onGenerateSchedules(GenerateSchedules event, Emitter<PlantState> emit) async {
    try {
      await PlantService.generateSchedules(event.plantId);
      emit(PlantActionSuccess('Jadwal berhasil digenerate!'));
      add(LoadSchedules(event.plantId));
    } catch (e) {
      emit(PlantError('Gagal generate jadwal: $e'));
    }
  }

  Future<void> _onLoadPlantStats(LoadPlantStats event, Emitter<PlantState> emit) async {
    emit(PlantLoading());
    try {
      final stats = await PlantService.getPlantStats(event.plantId);
      if (stats != null) {
        emit(PlantStatsLoaded(stats));
      } else {
        emit(PlantError('Stats tidak ditemukan.'));
      }
    } catch (e) {
      emit(PlantError('Gagal memuat stats: $e'));
    }
  }
}
