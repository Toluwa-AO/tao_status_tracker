import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:tao_status_tracker/core/services/email_services.dart';
import 'package:tao_status_tracker/core/services/firestore_service.dart';
import 'package:flutter/foundation.dart';
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
    on<SendOtpToPhone>(_onSendOtpToPhone);
    on<VerifyPhoneOtp>(_onVerifyPhoneOtp);
    on<SendOtpToEmail>(_onSendOtpToEmail);
    on<VerifyEmailOtp>(_onVerifyEmailOtp);
  }

  Future<void> _onRegistrationSubmitted(
      RegistrationSubmitted event, Emitter<RegistrationState> emit) async {
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
      final user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(event.name);
        try {
          await _firestoreService.saveUserData(
            user.uid,
            event.name,
            event.email,
          );
        } catch (e) {
          // Continue even if Firestore fails since auth succeeded
          debugPrint('Firestore error: ${e.toString()}');
        }
      }

      final otp = _generateOtp();
      await EmailService.sendOtp(event.email, otp);

      emit(OtpSent(
        email: event.email,
        otp: otp,
      ));
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
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
      emit(RegistrationSuccess());
    } catch (e) {
      emit(RegistrationFailure("Google sign-up failed"));
    }
  }

  Future<void> _onRegisterWithApple(
      RegisterWithApple event, Emitter<RegistrationState> emit) async {
    emit(RegistrationLoading());
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final AuthCredential credential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      await _auth.signInWithCredential(credential);
      emit(RegistrationSuccess());
    } catch (e) {
      emit(RegistrationFailure("Apple sign-up failed"));
    }
  }

  Future<void> _onSendOtpToPhone(
      SendOtpToPhone event, Emitter<RegistrationState> emit) async {
    emit(RegistrationLoading());
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: event.phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          emit(OtpVerificationSuccess());
        },
        verificationFailed: (FirebaseAuthException e) {
          emit(OtpVerificationFailure(e.message ?? "OTP verification failed"));
        },
        codeSent: (String verificationId, int? resendToken) {
      emit(OtpSent(
        verificationId: verificationId,
        otp: '', // Not used for phone OTP
      ));
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          emit(OtpVerificationFailure("OTP verification timeout"));
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      emit(OtpVerificationFailure("Unexpected error occurred"));
    }
  }

  Future<void> _onVerifyPhoneOtp(
      VerifyPhoneOtp event, Emitter<RegistrationState> emit) async {
    emit(OtpVerificationLoading());
    try {
      final AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: event.verificationId,
        smsCode: event.smsCode,
      );
      await _auth.signInWithCredential(credential);
      emit(OtpVerificationSuccess());
    } catch (e) {
      emit(OtpVerificationFailure("OTP verification failed"));
    }
  }

  Future<void> _onSendOtpToEmail(
  SendOtpToEmail event,
  Emitter<RegistrationState> emit,
) async {
  emit(RegistrationLoading());
  try {
    final otp = _generateOtp();
    await EmailService.sendOtp(event.email, otp);
    emit(OtpSent(
      email: event.email,
      otp: otp,
    ));
  } catch (e) {
    emit(RegistrationFailure('Failed to send OTP email: ${e.toString()}'));
  }
}


 Future<void> _onVerifyEmailOtp(
  VerifyEmailOtp event,
  Emitter<RegistrationState> emit,
) async {
  emit(OtpVerificationLoading());
  final isValid = await EmailService.verifyOtp(event.emailLink, event.enteredOtp);
  if (isValid) {
    emit(RegistrationSuccess());
  } else {
    emit(RegistrationFailure('Invalid or expired OTP'));
  }
}


  String _generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }
}

