part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserProfile user;

  const AuthAuthenticated({
    required this.user,
  });

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;

  const AuthError({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}

class AuthBiometricSetupSuccess extends AuthState {
  const AuthBiometricSetupSuccess();
}

class AuthBiometricSetupFailed extends AuthState {
  final String message;

  const AuthBiometricSetupFailed({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}
