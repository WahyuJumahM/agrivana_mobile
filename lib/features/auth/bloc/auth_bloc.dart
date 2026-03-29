// Location: agrivana\lib\features\auth\bloc\auth_bloc.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../model/user_model.dart';
import '../service/auth_service.dart';
import '../service/user_service.dart';
import '../../../services/api_service.dart';
import '../../../utils/dialogs.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<AuthCheckSession>(_onCheckSession);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthVerifyOtpRequested>(_onVerifyOtp);
    on<AuthResendOtpRequested>(_onResendOtp);
    on<AuthForgotPasswordRequested>(_onForgotPassword);
    on<AuthResetPasswordRequested>(_onResetPassword);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthEnterAsGuest>(_onEnterAsGuest);
    on<AuthFetchProfile>(_onFetchProfile);
  }

  Future<void> _onCheckSession(AuthCheckSession event, Emitter<AuthState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wasLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      await ApiService.loadTokens();

      if (wasLoggedIn && ApiService.isLoggedIn) {
        final cachedName = prefs.getString('userName') ?? 'Pengguna';
        final cachedId = prefs.getString('userId') ?? '';
        final cachedPremium = prefs.getBool('isPremium') ?? false;
        emit(AuthAuthenticated(
          user: UserModel(id: cachedId, name: cachedName, isPremium: cachedPremium),
          isPremium: cachedPremium,
        ));
        // Fetch fresh profile in background
        add(AuthFetchProfile());
      } else {
        if (!wasLoggedIn) {
          try { await ApiService.clearTokens(); } catch (_) {}
        }
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      debugPrint('AuthBloc._onCheckSession error: $e');
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await AuthService.login(event.identifier, event.password);

    if (result.success && result.data != null) {
      final auth = AuthResponse.fromJson(result.data);
      await ApiService.saveTokens(auth.accessToken, auth.refreshToken);

      const secureStore = FlutterSecureStorage();
      await secureStore.write(key: 'userId', value: auth.userId);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userId', auth.userId);
      await prefs.setString('userName', auth.name);
      await prefs.setString('userRole', auth.role);
      await prefs.setBool('isPremium', auth.isPremium);

      emit(AuthAuthenticated(
        user: UserModel(
          id: auth.userId, name: auth.name, role: auth.role, isPremium: auth.isPremium,
        ),
        isPremium: auth.isPremium,
      ));
      AppDialogs.showSuccess('Selamat datang, ${auth.name}!');
    } else {
      AppDialogs.showError(result.message);
      emit(AuthError(result.message));
    }
  }

  Future<void> _onRegister(AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await AuthService.register(event.name, event.email, event.phone, event.password);

    if (result.success) {
      AppDialogs.showSuccess('Pendaftaran berhasil! Silakan login.');
      emit(AuthRegisterSuccess('Pendaftaran berhasil! Silakan login.'));
    } else {
      AppDialogs.showError(result.message);
      emit(AuthError(result.message));
    }
  }

  Future<void> _onVerifyOtp(AuthVerifyOtpRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await AuthService.verifyOtp(event.identifier, event.otp, event.otpType);

    if (result.success) {
      AppDialogs.showSuccess(result.message);
      emit(AuthOtpVerified(result.message));
    } else {
      AppDialogs.showError(result.message);
      emit(AuthError(result.message));
    }
  }

  Future<void> _onResendOtp(AuthResendOtpRequested event, Emitter<AuthState> emit) async {
    final result = await AuthService.resendOtp(event.identifier);
    if (result.success) {
      AppDialogs.showSuccess('OTP baru telah dikirim.');
      emit(AuthOtpSent('OTP baru telah dikirim.'));
    } else {
      AppDialogs.showError(result.message);
    }
  }

  Future<void> _onForgotPassword(AuthForgotPasswordRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await AuthService.forgotPassword(event.identifier);

    if (result.success) {
      AppDialogs.showSuccess(result.message);
      emit(AuthOtpSent(result.message));
    } else {
      AppDialogs.showError(result.message);
      emit(AuthError(result.message));
    }
  }

  Future<void> _onResetPassword(AuthResetPasswordRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await AuthService.resetPassword(event.identifier, event.otp, event.newPassword);

    if (result.success) {
      AppDialogs.showSuccess(result.message);
      emit(AuthPasswordResetSuccess(result.message));
    } else {
      AppDialogs.showError(result.message);
      emit(AuthError(result.message));
    }
  }

  Future<void> _onLogout(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    final confirmed = await AppDialogs.showConfirmDialog(
      title: 'Keluar dari Akun',
      message: 'Apakah Anda yakin ingin keluar?',
      confirmText: 'Keluar',
      confirmColor: const Color(0xFFD32F2F),
      icon: Icons.logout_rounded,
    );
    if (!confirmed) return;

    AppDialogs.showLoading(message: 'Sedang logout...');
    try { await AuthService.logout(); } catch (_) {}
    try { await ApiService.clearTokens(); } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('userId');
      await prefs.remove('userName');
      await prefs.remove('userRole');
      await prefs.remove('isPremium');
    } catch (_) {}

    AppDialogs.hideLoading();
    emit(AuthUnauthenticated());
  }

  Future<void> _onEnterAsGuest(AuthEnterAsGuest event, Emitter<AuthState> emit) async {
    emit(AuthGuest());
  }

  Future<void> _onFetchProfile(AuthFetchProfile event, Emitter<AuthState> emit) async {
    if (state is! AuthAuthenticated) return;
    try {
      final result = await UserService.getProfile();
      if (result.success && result.data != null) {
        final user = UserModel.fromJson(result.data);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userName', user.name);
        await prefs.setBool('isPremium', user.isPremium);
        emit(AuthAuthenticated(
          user: user,
          isPremium: user.isPremium,
          hasStore: user.hasStore,
        ));
      }
    } catch (e) {
      debugPrint('fetchProfile error: $e');
    }
  }
}
