abstract class RegistrationState {}

// Initial State
class RegistrationInitial extends RegistrationState {}

// Loading State
class RegistrationLoading extends RegistrationState {}

// Success States
class RegistrationSuccess extends RegistrationState {}

class OtpSentSuccess extends RegistrationState {
  final String verificationId; // For phone OTP
  OtpSentSuccess(this.verificationId);
}

class EmailOtpSentSuccess extends RegistrationState {}

// Failure State
class RegistrationFailure extends RegistrationState {
  final String error;
  RegistrationFailure(this.error);
}

// OTP Verification States
class OtpVerificationLoading extends RegistrationState {}

class OtpVerificationSuccess extends RegistrationState {}

class OtpVerificationFailure extends RegistrationState {
  final String error;
  OtpVerificationFailure(this.error);
}
