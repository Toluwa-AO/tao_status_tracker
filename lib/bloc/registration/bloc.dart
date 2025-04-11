import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';
import 'package:tao_status_tracker/core/services/firestore_service.dart';
import 'events.dart';
import 'state.dart';

class RegistrationBloc extends Bloc<RegistrationEvent, RegistrationState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService();

  RegistrationBloc() : super(RegistrationInitial()) {
    on<RegistrationSubmitted>(_onRegistrationSubmitted);
    on<RegisterWithGoogle>(_onRegisterWithGoogle);
    on<RegisterWithApple>(_onRegisterWithApple);
  }

  Future<void> _onRegistrationSubmitted(
    RegistrationSubmitted event,
    Emitter<RegistrationState> emit,
  ) async {
    emit(RegistrationLoading());
    
    try {
      // Validate input
      if (_validateInput(event, emit)) {
        return;
      }

      // Create user account
      final UserCredential userCredential = 
          await _createUserAccount(event.email, event.password);
      
      // Update user profile and save to Firestore
      await _updateUserProfile(userCredential.user, event.name, event.email);

      // Send email verification
      await userCredential.user?.sendEmailVerification();

      emit(RegistrationSuccess(event.email));
    } on FirebaseAuthException catch (e) {
      emit(RegistrationFailure(_getFirebaseErrorMessage(e)));
    } catch (e) {
      emit(RegistrationFailure('An unexpected error occurred'));
      debugPrint('Registration error: ${e.toString()}');
    }
  }

  Future<void> _onRegisterWithGoogle(
    RegisterWithGoogle event,
    Emitter<RegistrationState> emit,
  ) async {
    emit(RegistrationLoading());
    
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        emit(RegistrationFailure('Google sign-in was cancelled'));
        return;
      }

      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      // Save additional user data to Firestore
      await _updateUserProfile(
        userCredential.user,
        userCredential.user?.displayName ?? '',
        userCredential.user?.email ?? '',
      );

      emit(RegistrationSuccess(userCredential.user?.email ?? ''));
    } catch (e) {
      emit(RegistrationFailure('Google sign-in failed. Please try again.'));
      debugPrint('Google sign-in error: ${e.toString()}');
    }
  }

  Future<void> _onRegisterWithApple(
    RegisterWithApple event,
    Emitter<RegistrationState> emit,
  ) async {
    emit(RegistrationLoading());
    
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      
      // Save additional user data to Firestore
      final String fullName = '${appleCredential.givenName ?? ''} '
          '${appleCredential.familyName ?? ''}'.trim();
      
      await _updateUserProfile(
        userCredential.user,
        fullName,
        userCredential.user?.email ?? '',
      );

      emit(RegistrationSuccess(userCredential.user?.email ?? ''));
    } catch (e) {
      emit(RegistrationFailure('Apple sign-in failed. Please try again.'));
      debugPrint('Apple sign-in error: ${e.toString()}');
    }
  }

  // Helper Methods
  bool _validateInput(RegistrationSubmitted event, Emitter<RegistrationState> emit) {
    if (event.name.isEmpty || event.email.isEmpty ||
        event.password.isEmpty || event.confirmPassword.isEmpty) {
      emit(RegistrationFailure('Please fill all fields'));
      return true;
    }
    
    if (event.password != event.confirmPassword) {
      emit(RegistrationFailure('Passwords do not match'));
      return true;
    }
    
    if (event.password.length < 6) {
      emit(RegistrationFailure('Password must be at least 6 characters'));
      return true;
    }
    
    return false;
  }

  Future<UserCredential> _createUserAccount(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> _updateUserProfile(User? user, String name, String email) async {
    if (user != null) {
      await user.updateDisplayName(name);
      
      try {
        await _firestoreService.saveUserData(
          user.uid,
          name,
          email,
        );
      } catch (e) {
        debugPrint('Firestore error: ${e.toString()}');
        // Continue even if Firestore fails since auth succeeded
      }
    }
  }

  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Please enter a valid email address';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled';
      case 'weak-password':
        return 'Please enter a stronger password';
      default:
        return e.message ?? 'Registration failed';
    }
  }
}
