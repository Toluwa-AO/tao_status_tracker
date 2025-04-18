import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tao_status_tracker/bloc/login/login_events.dart';

abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object> get props => [];
}

class LoginInitial extends LoginState {
  const LoginInitial();
}

class LoginLoading extends LoginState {
  const LoginLoading();
}

class LoginSuccess extends LoginState {
  final String? userId;
  final User? user;

  const LoginSuccess({this.userId, this.user});

  @override
  List<Object> get props => [
    if (userId != null) userId!,
    if (user != null) user!,
  ];
}

class LoginFailure extends LoginState {
  final String error;

  const LoginFailure({required this.error});

  @override
  List<Object> get props => [error];
}

class GoogleLoginRequested extends LoginEvent {}
