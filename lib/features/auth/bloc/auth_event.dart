// Location: agrivana\lib\features\auth\bloc\auth_event.dart
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthCheckSession extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String identifier;
  final String password;
  const AuthLoginRequested({required this.identifier, required this.password});
  @override
  List<Object?> get props => [identifier, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String phone;
  final String password;
  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
  });
  @override
  List<Object?> get props => [name, email, phone, password];
}

class AuthVerifyOtpRequested extends AuthEvent {
  final String identifier;
  final String otp;
  final String otpType;
  const AuthVerifyOtpRequested({
    required this.identifier,
    required this.otp,
    required this.otpType,
  });
  @override
  List<Object?> get props => [identifier, otp, otpType];
}

class AuthResendOtpRequested extends AuthEvent {
  final String identifier;
  const AuthResendOtpRequested({required this.identifier});
  @override
  List<Object?> get props => [identifier];
}

class AuthForgotPasswordRequested extends AuthEvent {
  final String identifier;
  const AuthForgotPasswordRequested({required this.identifier});
  @override
  List<Object?> get props => [identifier];
}

class AuthResetPasswordRequested extends AuthEvent {
  final String identifier;
  final String otp;
  final String newPassword;
  const AuthResetPasswordRequested({
    required this.identifier,
    required this.otp,
    required this.newPassword,
  });
  @override
  List<Object?> get props => [identifier, otp, newPassword];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthEnterAsGuest extends AuthEvent {}

class AuthFetchProfile extends AuthEvent {}
