// Location: agrivana\lib\features\auth\bloc\auth_state.dart
import 'package:equatable/equatable.dart';
import '../model/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  final bool isPremium;
  final bool hasStore;

  const AuthAuthenticated({
    required this.user,
    this.isPremium = false,
    this.hasStore = false,
  });

  AuthAuthenticated copyWith({
    UserModel? user,
    bool? isPremium,
    bool? hasStore,
  }) {
    return AuthAuthenticated(
      user: user ?? this.user,
      isPremium: isPremium ?? this.isPremium,
      hasStore: hasStore ?? this.hasStore,
    );
  }

  @override
  List<Object?> get props => [user, isPremium, hasStore];
}

class AuthGuest extends AuthState {}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

class AuthRegisterSuccess extends AuthState {
  final String message;
  const AuthRegisterSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class AuthOtpSent extends AuthState {
  final String message;
  const AuthOtpSent(this.message);
  @override
  List<Object?> get props => [message];
}

class AuthOtpVerified extends AuthState {
  final String message;
  const AuthOtpVerified(this.message);
  @override
  List<Object?> get props => [message];
}

class AuthPasswordResetSuccess extends AuthState {
  final String message;
  const AuthPasswordResetSuccess(this.message);
  @override
  List<Object?> get props => [message];
}
