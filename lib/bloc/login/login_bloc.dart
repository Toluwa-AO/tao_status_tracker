import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'login_events.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  LoginBloc() : super(LoginInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LoginWithGoogle>(_onGoogleLoginRequested);
    on<LoginWithFacebook>(_onFacebookLoginRequested);
    on<LoginWithApple>(_onAppleLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLoginSubmitted(
      LoginSubmitted event, Emitter<LoginState> emit) async {
    emit(LoginLoading());
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      emit(LoginSuccess(user: userCredential.user));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        emit(LoginFailure(error: "The email or password is incorrect"));
      } else {
        emit(LoginFailure(error: e.message ?? "An error occurred"));
      }
    } catch (e) {
      emit(LoginFailure(error: "Unexpected error occurred"));
    }
  }

  Future<void> _onGoogleLoginRequested(
      LoginWithGoogle event, Emitter<LoginState> emit) async {
    emit(LoginLoading());
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        emit(LoginFailure(error: "Google sign-in canceled"));
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      emit(LoginSuccess(user: userCredential.user));
    } on FirebaseAuthException catch (e) {
      emit(LoginFailure(error: e.message ?? "Google sign-in failed"));
    } catch (e) {
      emit(LoginFailure(error: "Unexpected error occurred during Google sign-in"));
    }
  }

  Future<void> _onFacebookLoginRequested(
      LoginWithFacebook event, Emitter<LoginState> emit) async {
    emit(LoginFailure(error: "Facebook login is not yet implemented"));
  }

  Future<void> _onAppleLoginRequested(
      LoginWithApple event, Emitter<LoginState> emit) async {
    emit(LoginFailure(error: "Apple login is not yet implemented"));
  }

  Future<void> _onLogoutRequested(
      LogoutRequested event, Emitter<LoginState> emit) async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      emit(LoginInitial());
    } catch (e) {
      emit(LoginFailure(error: "Logout failed"));
    }
  }
}
