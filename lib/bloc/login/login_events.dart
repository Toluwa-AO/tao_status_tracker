import 'package:equatable/equatable.dart';

// Events
abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object> get props => [];
}

class LoginSubmitted extends LoginEvent {
  final String email;
  final String password;

  const LoginSubmitted({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class LoginWithGoogle extends LoginEvent {
  const LoginWithGoogle();
}

class LoginWithFacebook extends LoginEvent {
  const LoginWithFacebook();
}

class LoginWithApple extends LoginEvent {
  const LoginWithApple();
}

class LogoutRequested extends LoginEvent {
  const LogoutRequested();
}

class GoogleLoginRequested extends LoginEvent {}
