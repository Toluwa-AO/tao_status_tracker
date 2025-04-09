import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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
    on<SendOtpToPhone>(_onSendOtpToPhone);
    on<VerifyPhoneOtp>(_onVerifyPhoneOtp);
    on<SendOtpToEmail>(_onSendOtpToEmail);
    on<VerifyEmailOtp>(_onVerifyEmailOtp);
  }

  // Email/Password Registration
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

      await userCredential.user?.updateDisplayName(event.name);
      emit(RegistrationSuccess(userCredential.user));
    } on FirebaseAuthException catch (e) {
      emit(RegistrationFailure(e.message ?? 'Registration failed'));
    } catch (e) {
      emit(RegistrationFailure('Unexpected error occurred'));
    }
  }

  // Google Registration
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

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      emit(RegistrationSuccess(userCredential.user));
    } on FirebaseAuthException catch (e) {
      emit(RegistrationFailure(e.message ?? "Google sign-up failed"));
    } catch (e) {
      emit(RegistrationFailure("Unexpected error occurred during Google sign-up"));
    }
  }

  // Facebook Registration (Placeholder)
  Future<void> _onRegisterWithFacebook(
      RegisterWithFacebook event, Emitter<RegistrationState> emit) async {
    emit(RegistrationLoading());
    try {
      // Implement Facebook sign-in logic here
      emit(RegistrationFailure("Facebook sign-up is not yet implemented"));
    } catch (e) {
      emit(RegistrationFailure("Unexpected error occurred during Facebook sign-up"));
    }
  }

  // Apple Registration
  Future<void> _onRegisterWithApple(
      RegisterWithApple event, Emitter<RegistrationState> emit) async {
    emit(RegistrationLoading());
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );

      final AuthCredential credential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      emit(RegistrationSuccess(userCredential.user));
    } on FirebaseAuthException catch (e) {
      emit(RegistrationFailure(e.message ?? "Apple sign-up failed"));
    } catch (e) {
      emit(RegistrationFailure("Unexpected error occurred during Apple sign-up"));
    }
  }

  // Sending OTP to Phone
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
          emit(OtpSentSuccess(verificationId));
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      emit(OtpVerificationFailure("Unexpected error occurred during phone OTP"));
    }
  }

  // Verifying Phone OTP
  Future<void> _onVerifyPhoneOtp(
      VerifyPhoneOtp event, Emitter<RegistrationState> emit) async {
    emit(OtpVerificationLoading());
    try {
      final AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: event.verificationId,
        smsCode: event.otp,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      emit(OtpVerificationSuccess());
      emit(RegistrationSuccess(userCredential.user));
    } on FirebaseAuthException catch (e) {
      emit(OtpVerificationFailure(e.message ?? "OTP verification failed"));
    } catch (e) {
      emit(OtpVerificationFailure("Unexpected error occurred during OTP verification"));
    }
  }

  // Sending OTP to Email
  // Sending OTP to Email
  Future<void> _onSendOtpToEmail(
      SendOtpToEmail event, Emitter<RegistrationState> emit) async {
    emit(RegistrationLoading());
    try {
      await _auth.sendSignInLinkToEmail(
        email: event.email,
        actionCodeSettings: ActionCodeSettings(
          url: "https://status-tracker-7d6bf.firebaseapp.com",
          handleCodeInApp: true,
          androidPackageName: "com.example.yourapp",
          iOSBundleId: "com.example.yourapp",
          androidInstallApp: true,
          minimumVersion: "1",
        ),
      );
      emit(EmailOtpSentSuccess());
    } on FirebaseAuthException catch (e) {
      emit(RegistrationFailure(e.message ?? "Failed to send OTP email"));
    } catch (e) {
      emit(RegistrationFailure("Unexpected error occurred during email OTP"));
    }
  }
}

  // Verifying Email OTP (Placeholder)
  Future<void> _onVerifyEmailOtp(
      VerifyEmailOtp event, Emitter<RegistrationState> emit) async {
    emit(OtpVerificationLoading());
    try {
      // Firebase does not support direct email OTP verification via FirebaseAuth.
      // Users should click the email link to verify.
      emit(OtpVerificationSuccess());
    } catch (e) {
      emit(OtpVerificationFailure("Unexpected error occurred during email OTP verification"));
    }
  }
}
