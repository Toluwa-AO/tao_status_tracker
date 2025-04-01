import 'package:flutter_bloc/flutter_bloc.dart';
import 'login_events.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(LoginInitial());

  @override
  Stream<LoginState> mapEventToState(LoginEvent event) async* {
    if (event is LoginSubmitted) {
      yield LoginLoading();
      try {
        // Simulate a login process
        await Future.delayed(Duration(seconds: 2));
        // Here you would typically call your authentication service
        yield LoginSuccess();
      } catch (e) {
        yield LoginFailure(error: e.toString());
      }
    }
  }
}
