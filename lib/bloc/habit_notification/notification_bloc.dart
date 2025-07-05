import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tao_status_tracker/core/services/in_app_notification_service.dart';
import 'package:tao_status_tracker/models/habit.dart';
import 'notification_events.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final InAppNotificationService _notificationService;
  late StreamSubscription<Map<String, dynamic>> _notificationSubscription;

  NotificationBloc({InAppNotificationService? notificationService}) 
      : _notificationService = notificationService ?? InAppNotificationService(),
        super(NotificationInitial()) {
    on<InitializeNotifications>(_onInitializeNotifications);
    on<RequestNotificationPermission>(_onRequestNotificationPermission);
    on<ScheduleHabitNotification>(_onScheduleHabitNotification);
    on<UpdateHabitNotification>(_onUpdateHabitNotification);
    on<CancelHabitNotification>(_onCancelHabitNotification);
    on<NotificationReceived>(_onNotificationReceived);
    on<NotificationActionPerformed>(_onNotificationActionPerformed);
    on<NotificationDismissed>(_onNotificationDismissed);
    
    // Listen to notification service stream
    _notificationSubscription = _notificationService.notificationStream.listen(_handleNotificationEvent);
  }

  Future<void> _onInitializeNotifications(
    InitializeNotifications event, 
    Emitter<NotificationState> emit
  ) async {
    emit(NotificationInitial());
  }

  Future<void> _onRequestNotificationPermission(
    RequestNotificationPermission event, 
    Emitter<NotificationState> emit
  ) async {
    emit(NotificationPermissionGranted());
  }

  Future<void> _onScheduleHabitNotification(
    ScheduleHabitNotification event, 
    Emitter<NotificationState> emit
  ) async {
    // For now, just show an immediate in-app notification for testing
    _notificationService.showHabitReminder(event.habit);
    emit(NotificationScheduled(event.habit.id));
  }

  Future<void> _onUpdateHabitNotification(
    UpdateHabitNotification event, 
    Emitter<NotificationState> emit
  ) async {
    emit(NotificationUpdated(event.habit.id));
  }

  Future<void> _onCancelHabitNotification(
    CancelHabitNotification event, 
    Emitter<NotificationState> emit
  ) async {
    emit(NotificationCancelled(event.habitId));
  }

  void _onNotificationReceived(
    NotificationReceived event, 
    Emitter<NotificationState> emit
  ) {
    emit(NotificationActive(
      notificationId: event.notificationId,
      title: event.title,
      message: event.message,
      payload: event.payload,
    ));
  }

  void _onNotificationActionPerformed(
    NotificationActionPerformed event, 
    Emitter<NotificationState> emit
  ) {
    if (event.actionId == 'MARK_AS_DONE') {
      _notificationService.markHabitAsDone(event.habitId);
    } else if (event.actionId == 'SNOOZE') {
      _notificationService.snoozeHabit(event.habitId);
    }
    
    emit(NotificationActionHandled(
      notificationId: event.notificationId,
      actionId: event.actionId,
      habitId: event.habitId,
    ));
  }

  void _onNotificationDismissed(
    NotificationDismissed event, 
    Emitter<NotificationState> emit
  ) {
    emit(NotificationDismissedState(notificationId: event.notificationId));
  }

  void _handleNotificationEvent(Map<String, dynamic> event) {
    final String type = event['type'] as String;
    
    switch (type) {
      case 'reminder':
        final Habit habit = event['habit'] as Habit;
        add(NotificationReceived(
          notificationId: habit.id,
          title: habit.title,
          message: habit.description,
          payload: {'habitId': habit.id},
        ));
        break;
      
      case 'markAsDone':
        final String habitId = event['habitId'] as String;
        add(NotificationActionPerformed(
          notificationId: habitId,
          actionId: 'MARK_AS_DONE',
          habitId: habitId,
        ));
        break;
      
      case 'snooze':
        final String habitId = event['habitId'] as String;
        add(NotificationActionPerformed(
          notificationId: habitId,
          actionId: 'SNOOZE',
          habitId: habitId,
        ));
        break;
    }
  }

  @override
  Future<void> close() {
    _notificationSubscription.cancel();
    return super.close();
  }
}