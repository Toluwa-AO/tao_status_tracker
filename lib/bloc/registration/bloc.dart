// registration_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tao_status_tracker/bloc/registration/events.dart';
import 'package:tao_status_tracker/bloc/registration/state.dart';

class RegistrationBloc extends Bloc<RegistrationEvent, RegistrationState> {
  RegistrationBloc() : super(RegistrationInitial()) {
    on<RegistrationSubmitted>(_onRegistrationSubmitted);
  }

  Future<void> _onRegistrationSubmitted(
    RegistrationSubmitted event,
    Emitter<RegistrationState> emit,
  ) async {
    try {
      emit(RegistrationLoading());

      // Validate inputs
      if (event.name.isEmpty || event.email.isEmpty || 
          event.password.isEmpty || event.confirmPassword.isEmpty) {
        emit(RegistrationFailure('Please fill all fields'));
        return;
      }

      if (event.password != event.confirmPassword) {
        emit(RegistrationFailure('Passwords do not match'));
        return;
      }

      //  make an API call or save to local storage
      await _saveUserData(event.name, event.email);

      emit(RegistrationSuccess());
    } catch (e) {
      emit(RegistrationFailure(e.toString()));
    }
  }

  Future<void> _saveUserData(String name, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_email', email);
  }
}
