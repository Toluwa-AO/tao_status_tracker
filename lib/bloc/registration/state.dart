abstract class RegistrationState {}

// Initial State
class RegistrationInitial extends RegistrationState {}

// Loading States
class RegistrationLoading extends RegistrationState {}
class OtpVerificationLoading extends RegistrationState {}
class RegistrationValidating extends RegistrationState {}

// Validation States
class PasswordStrengthState extends RegistrationState {
  final double strength; // 0.0 to 1.0
  final String message;
  PasswordStrengthState(this.strength, this.message);
}

class EmailValidationError extends RegistrationState {
  final String error;
  EmailValidationError(this.error);
}

class PasswordValidationError extends RegistrationState {
  final String error;
  PasswordValidationError(this.error);
}

class NameValidationError extends RegistrationState {
  final String error;
  NameValidationError(this.error);
}

// Success States
class RegistrationSuccess extends RegistrationState {}

class OtpSent extends RegistrationState {
  final String verificationId; // For phone OTP
  final String? email; // For email OTP
  final String otp; // For testing
  
  OtpSent({
    this.verificationId = '',
    this.email,
    required this.otp,
  });
}

// Failure States
class RegistrationFailure extends RegistrationState {
  final String error;
  RegistrationFailure(this.error);
}

class OtpVerificationSuccess extends RegistrationState {}

class OtpVerificationFailure extends RegistrationState {
  final String error;
  OtpVerificationFailure(this.error);
}
