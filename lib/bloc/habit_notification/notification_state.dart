import 'package:equatable/equatable.dart';

abstract class NotificationState extends Equatable {
  @override
  List<Object> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationActive extends NotificationState {
  final String message;

  NotificationActive(this.message);

  @override
  List<Object> get props => [message];
}

class NotificationDismissedState extends NotificationState {}
