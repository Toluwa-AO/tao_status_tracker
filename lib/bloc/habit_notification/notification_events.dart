import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class NotificationReceived extends NotificationEvent {
  final String message;

  NotificationReceived(this.message);

  @override
  List<Object> get props => [message];
}

class NotificationDismissed extends NotificationEvent {
  final String notificationId;

  NotificationDismissed(this.notificationId);

  @override
  List<Object> get props => [notificationId];
}
