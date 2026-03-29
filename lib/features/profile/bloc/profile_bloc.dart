// Location: agrivana\lib\features\profile\bloc\profile_bloc.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../auth/model/user_model.dart';
import '../../auth/service/user_service.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../service/profile_services.dart';
import '../../shop/service/marketplace_service.dart';
import '../../../utils/dialogs.dart';

// ═══════════════════════════════════════════════════════════════
// PROFILE BLOC
// ═══════════════════════════════════════════════════════════════

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class ProfileLoadRequested extends ProfileEvent {}

class ProfileUpdateRequested extends ProfileEvent {
  final Map<String, dynamic> data;
  const ProfileUpdateRequested(this.data);
  @override
  List<Object?> get props => [data];
}

class ProfileChangePassword extends ProfileEvent {
  final String current;
  final String newPassword;
  const ProfileChangePassword({required this.current, required this.newPassword});
  @override
  List<Object?> get props => [current, newPassword];
}

abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}
class ProfileLoading extends ProfileState {}
class ProfileLoaded extends ProfileState {
  final UserModel user;
  const ProfileLoaded(this.user);
  @override
  List<Object?> get props => [user];
}
class ProfileSuccess extends ProfileState {
  final String message;
  const ProfileSuccess(this.message);
  @override
  List<Object?> get props => [message];
}
class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);
  @override
  List<Object?> get props => [message];
}

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final AuthBloc? authBloc;

  ProfileBloc({this.authBloc}) : super(ProfileInitial()) {
    on<ProfileLoadRequested>(_onLoad);
    on<ProfileUpdateRequested>(_onUpdate);
    on<ProfileChangePassword>(_onChangePassword);
  }

  Future<void> _onLoad(ProfileLoadRequested event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    final result = await UserService.getProfile();
    if (result.success && result.data != null) {
      final user = UserModel.fromJson(result.data);
      emit(ProfileLoaded(user));
    } else {
      emit(ProfileError(result.message));
    }
  }

  Future<void> _onUpdate(ProfileUpdateRequested event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    final result = await UserService.updateProfile(event.data);
    if (result.success) {
      AppDialogs.showSuccess('Profil berhasil diperbarui');
      // Refresh global user data in AuthBloc
      authBloc?.add(AuthFetchProfile());
      emit(ProfileSuccess('Profil berhasil diperbarui'));
    } else {
      AppDialogs.showError(result.message);
      emit(ProfileError(result.message));
    }
  }

  Future<void> _onChangePassword(ProfileChangePassword event, Emitter<ProfileState> emit) async {
    final confirmed = await AppDialogs.showConfirmDialog(
      title: 'Ubah Password',
      message: 'Apakah Anda yakin ingin mengubah password?',
      confirmText: 'Ubah',
      icon: Icons.lock_outline,
    );
    if (!confirmed) return;

    emit(ProfileLoading());
    final result = await UserService.changePassword(event.current, event.newPassword);
    if (result.success) {
      AppDialogs.showSuccess('Password berhasil diubah');
      emit(ProfileSuccess('Password berhasil diubah'));
    } else {
      AppDialogs.showError(result.message);
      emit(ProfileError(result.message));
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// SELLER BLOC
// ═══════════════════════════════════════════════════════════════

abstract class SellerEvent extends Equatable {
  const SellerEvent();
  @override
  List<Object?> get props => [];
}

class SellerLoadData extends SellerEvent {}
class SellerCreateStore extends SellerEvent {
  final Map<String, dynamic> data;
  const SellerCreateStore(this.data);
  @override
  List<Object?> get props => [data];
}
class SellerUpdateStore extends SellerEvent {
  final Map<String, dynamic> data;
  const SellerUpdateStore(this.data);
  @override
  List<Object?> get props => [data];
}
class SellerUpdateStoreLocation extends SellerEvent {
  final Map<String, dynamic> data;
  const SellerUpdateStoreLocation(this.data);
  @override
  List<Object?> get props => [data];
}
class SellerDeleteStore extends SellerEvent {}
class SellerAddProduct extends SellerEvent {
  final Map<String, dynamic> data;
  const SellerAddProduct(this.data);
  @override
  List<Object?> get props => [data];
}
class SellerUpdateProduct extends SellerEvent {
  final String productId;
  final Map<String, dynamic> data;
  const SellerUpdateProduct(this.productId, this.data);
  @override
  List<Object?> get props => [productId, data];
}
class SellerDeleteProduct extends SellerEvent {
  final String productId;
  const SellerDeleteProduct(this.productId);
  @override
  List<Object?> get props => [productId];
}
class SellerProcessOrder extends SellerEvent {
  final String orderId;
  const SellerProcessOrder(this.orderId);
  @override
  List<Object?> get props => [orderId];
}
class SellerShipOrder extends SellerEvent {
  final String orderId;
  final String trackingNumber;
  const SellerShipOrder(this.orderId, this.trackingNumber);
  @override
  List<Object?> get props => [orderId, trackingNumber];
}
class SellerSelectStatus extends SellerEvent {
  final String status;
  const SellerSelectStatus(this.status);
  @override
  List<Object?> get props => [status];
}
class SellerWithdraw extends SellerEvent {
  final double amount;
  const SellerWithdraw(this.amount);
  @override
  List<Object?> get props => [amount];
}

abstract class SellerState extends Equatable {
  const SellerState();
  @override
  List<Object?> get props => [];
}

class SellerInitial extends SellerState {}
class SellerLoading extends SellerState {}

class SellerLoaded extends SellerState {
  final Map<String, dynamic>? storeInfo;
  final List<dynamic> orders;
  final List<dynamic> products;
  final List<dynamic> categories;
  final String selectedStatus;

  const SellerLoaded({
    this.storeInfo,
    this.orders = const [],
    this.products = const [],
    this.categories = const [],
    this.selectedStatus = 'payment_confirmed',
  });

  @override
  List<Object?> get props => [storeInfo, orders, products, categories, selectedStatus];
}

class SellerError extends SellerState {
  final String message;
  const SellerError(this.message);
  @override
  List<Object?> get props => [message];
}

class SellerBloc extends Bloc<SellerEvent, SellerState> {
  SellerBloc() : super(SellerInitial()) {
    on<SellerLoadData>(_onLoad);
    on<SellerCreateStore>(_onCreateStore);
    on<SellerUpdateStore>(_onUpdateStore);
    on<SellerUpdateStoreLocation>(_onUpdateStoreLocation);
    on<SellerDeleteStore>(_onDeleteStore);
    on<SellerAddProduct>(_onAddProduct);
    on<SellerUpdateProduct>(_onUpdateProduct);
    on<SellerDeleteProduct>(_onDeleteProduct);
    on<SellerProcessOrder>(_onProcessOrder);
    on<SellerShipOrder>(_onShipOrder);
    on<SellerSelectStatus>(_onSelectStatus);
    on<SellerWithdraw>(_onWithdraw);
  }

  String _selectedStatus = 'payment_confirmed';

  Future<void> _onLoad(SellerLoadData event, Emitter<SellerState> emit) async {
    emit(SellerLoading());
    Map<String, dynamic>? storeInfo;
    List<dynamic> orders = [];
    List<dynamic> products = [];
    List<dynamic> categories = [];

    final storeResult = await SellerService.getStoreInfo();
    if (storeResult.success && storeResult.data != null) {
      storeInfo = storeResult.data is Map<String, dynamic> ? storeResult.data : null;
    }

    final ordersResult = await SellerService.getSellerOrders(query: {'status': _selectedStatus});
    if (ordersResult.success && ordersResult.data != null) {
      final items = ordersResult.data is List ? ordersResult.data : (ordersResult.data['items'] ?? []);
      orders = items is List ? items : [];
    }

    final prodResult = await SellerService.getMyProducts();
    if (prodResult.success && prodResult.data != null) {
      products = prodResult.data is List ? prodResult.data : [];
    }

    final catResult = await MarketplaceService.getCategories();
    if (catResult.success && catResult.data != null) {
      categories = catResult.data is List ? catResult.data : [];
    }

    emit(SellerLoaded(
        storeInfo: storeInfo, orders: orders, products: products,
        categories: categories, selectedStatus: _selectedStatus));
  }

  Future<void> _onCreateStore(SellerCreateStore event, Emitter<SellerState> emit) async {
    final confirmed = await AppDialogs.showConfirmDialog(
      title: 'Buat Toko', message: 'Apakah data toko sudah benar?',
      confirmText: 'Ya, Buat Toko', icon: Icons.storefront_rounded,
    );
    if (!confirmed) return;

    final result = await MarketplaceService.createStore(event.data);
    if (result.success) {
      AppDialogs.showSuccess('Toko berhasil dibuat!');
      add(SellerLoadData());
    } else {
      AppDialogs.showError(result.message);
    }
  }

  Future<void> _onUpdateStore(SellerUpdateStore event, Emitter<SellerState> emit) async {
    final result = await SellerService.updateStore(event.data);
    if (result.success) {
      AppDialogs.showSuccess('Toko berhasil diperbarui!');
      add(SellerLoadData());
    } else {
      AppDialogs.showError(result.message);
    }
  }

  Future<void> _onUpdateStoreLocation(SellerUpdateStoreLocation event, Emitter<SellerState> emit) async {
    final result = await SellerService.updateStoreLocation(event.data);
    if (result.success) {
      AppDialogs.showSuccess('Lokasi toko berhasil diperbarui!');
      add(SellerLoadData());
    } else {
      AppDialogs.showError(result.message);
    }
  }

  Future<void> _onDeleteStore(SellerDeleteStore event, Emitter<SellerState> emit) async {
    final confirmed = await AppDialogs.showConfirmDialog(
      title: 'Hapus Toko', message: 'Yakin ingin menghapus toko? Semua produk juga akan dinonaktifkan.',
      confirmText: 'Ya, Hapus', icon: Icons.delete_forever_rounded,
    );
    if (!confirmed) return;

    final result = await SellerService.deleteStore();
    if (result.success) {
      AppDialogs.showSuccess('Toko berhasil dihapus.');
      add(SellerLoadData());
    } else {
      AppDialogs.showError(result.message);
    }
  }

  Future<void> _onAddProduct(SellerAddProduct event, Emitter<SellerState> emit) async {
    final confirmed = await AppDialogs.showConfirmDialog(
      title: 'Tambah Produk', message: 'Apakah data produk sudah benar?',
      confirmText: 'Ya, Tambahkan', icon: Icons.add_shopping_cart_rounded,
    );
    if (!confirmed) return;

    final result = await MarketplaceService.addProduct(event.data);
    if (result.success) {
      AppDialogs.showSuccess('Produk berhasil ditambahkan!');
      add(SellerLoadData());
    } else {
      AppDialogs.showError(result.message);
    }
  }

  Future<void> _onUpdateProduct(SellerUpdateProduct event, Emitter<SellerState> emit) async {
    final result = await SellerService.updateProduct(event.productId, event.data);
    if (result.success) {
      AppDialogs.showSuccess('Produk berhasil diperbarui!');
      add(SellerLoadData());
    } else {
      AppDialogs.showError(result.message);
    }
  }

  Future<void> _onDeleteProduct(SellerDeleteProduct event, Emitter<SellerState> emit) async {
    final confirmed = await AppDialogs.showConfirmDialog(
      title: 'Hapus Produk', message: 'Yakin ingin menghapus produk ini?',
      confirmText: 'Ya, Hapus', icon: Icons.delete_outline_rounded,
    );
    if (!confirmed) return;

    final result = await SellerService.deleteProduct(event.productId);
    if (result.success) {
      AppDialogs.showSuccess('Produk berhasil dihapus.');
      add(SellerLoadData());
    } else {
      AppDialogs.showError(result.message);
    }
  }

  Future<void> _onProcessOrder(SellerProcessOrder event, Emitter<SellerState> emit) async {
    final confirmed = await AppDialogs.showConfirmDialog(
      title: 'Proses Pesanan', message: 'Pesanan akan diproses. Lanjutkan?',
      confirmText: 'Ya, Proses', icon: Icons.inventory_2_rounded,
    );
    if (!confirmed) return;

    final result = await SellerService.processOrder(event.orderId);
    if (result.success) {
      AppDialogs.showSuccess('Pesanan sedang diproses');
      add(SellerLoadData());
    } else {
      AppDialogs.showError(result.message);
    }
  }

  Future<void> _onShipOrder(SellerShipOrder event, Emitter<SellerState> emit) async {
    final confirmed = await AppDialogs.showConfirmDialog(
      title: 'Kirim Pesanan', message: 'Pesanan akan dikirim dengan resi: ${event.trackingNumber}',
      confirmText: 'Ya, Kirim', icon: Icons.local_shipping_rounded,
    );
    if (!confirmed) return;

    final result = await SellerService.shipOrder(event.orderId, {'trackingNumber': event.trackingNumber});
    if (result.success) {
      AppDialogs.showSuccess('Pesanan telah dikirim');
      add(SellerLoadData());
    } else {
      AppDialogs.showError(result.message);
    }
  }

  void _onSelectStatus(SellerSelectStatus event, Emitter<SellerState> emit) {
    _selectedStatus = event.status;
    add(SellerLoadData());
  }

  Future<void> _onWithdraw(SellerWithdraw event, Emitter<SellerState> emit) async {
    final confirmed = await AppDialogs.showConfirmDialog(
      title: 'Penarikan Saldo', message: 'Tarik saldo Rp ${event.amount.toStringAsFixed(0)}?',
      confirmText: 'Ya, Tarik', icon: Icons.account_balance_wallet_rounded,
    );
    if (!confirmed) return;

    final result = await SellerService.requestWithdraw({'amount': event.amount});
    if (result.success) {
      AppDialogs.showSuccess('Penarikan berhasil diajukan!');
      add(SellerLoadData());
    } else {
      AppDialogs.showError(result.message);
    }
  }
}
