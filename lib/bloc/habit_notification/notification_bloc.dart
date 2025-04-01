import 'package:flutter_bloc/flutter_bloc.dart';
import 'notification_events.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc() : super(NotificationInitial());

  @override
  Stream<NotificationState> mapEventToState(NotificationEvent event) async* {
    if (event is NotificationReceived) {
      yield NotificationActive(event.message);
    } else if (event is NotificationDismissed) {
      yield NotificationDismissedState();

      // Removed incorrect yield

    }
  }
}
