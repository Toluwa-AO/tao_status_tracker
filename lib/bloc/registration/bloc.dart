import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tao_status_tracker/bloc/registration/events.dart';
import 'package:tao_status_tracker/bloc/registration/state.dart';

class RegistrationBloc extends Bloc<RegistrationEvent, RegistrationState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  RegistrationBloc() : super(RegistrationInitial()) {
    on<RegistrationSubmitted>(_onRegistrationSubmitted);
    on<RegisterWithGoogle>(_onRegisterWithGoogle);
    on<RegisterWithFacebook>(_onRegisterWithFacebook);
    on<RegisterWithApple>(_onRegisterWithApple);
  }

  Future<void> _onRegistrationSubmitted(
    RegistrationSubmitted event,
    Emitter<RegistrationState> emit,
  ) async {
    emit(RegistrationLoading());
    try {
      if (event.name.isEmpty || event.email.isEmpty ||
          event.password.isEmpty || event.confirmPassword.isEmpty) {
        emit(RegistrationFailure('Please fill all fields'));
        return;
      }

      if (event.password != event.confirmPassword) {
        emit(RegistrationFailure('Passwords do not match'));
        return;
      }

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      await userCredential.user?.updateDisplayName(event.name);
      emit(RegistrationSuccess());
    } on FirebaseAuthException catch (e) {
      emit(RegistrationFailure(e.message ?? 'Registration failed'));
    } catch (e) {
      emit(RegistrationFailure('Unexpected error occurred'));
    }
  }

  Future<void> _onRegisterWithGoogle(
      RegisterWithGoogle event, Emitter<RegistrationState> emit) async {
    emit(RegistrationLoading());
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        emit(RegistrationFailure("Google sign-up canceled"));
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      emit(RegistrationSuccess());
    } on FirebaseAuthException catch (e) {
      emit(RegistrationFailure(e.message ?? "Google sign-up failed"));
    } catch (e) {
      emit(RegistrationFailure("Unexpected error occurred during Google sign-up"));
    }
  }

  Future<void> _onRegisterWithFacebook(
      RegisterWithFacebook event, Emitter<RegistrationState> emit) async {
    emit(RegistrationFailure("Facebook sign-up is not yet implemented"));
  }

  Future<void> _onRegisterWithApple(
      RegisterWithApple event, Emitter<RegistrationState> emit) async {
    emit(RegistrationFailure("Apple sign-up is not yet implemented"));
  }
}
