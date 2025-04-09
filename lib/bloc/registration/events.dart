abstract class RegistrationEvent {}

// Standard Registration Event
class RegistrationSubmitted extends RegistrationEvent {
  final String name;
  final String email;
  final String password;
  final String confirmPassword;

  RegistrationSubmitted({
    required this.name,
    required this.email,
    required this.password,
    required this.confirmPassword,
  });
}

// Social Authentication Events
class RegisterWithGoogle extends RegistrationEvent {}

class RegisterWithFacebook extends RegistrationEvent {}

class RegisterWithApple extends RegistrationEvent {}

// OTP Authentication Events
class SendPhoneOtp extends RegistrationEvent {
  final String phoneNumber;

  SendPhoneOtp({required this.phoneNumber});
}

class VerifyPhoneOtp extends RegistrationEvent {
  final String verificationId;
  final String smsCode;

  VerifyPhoneOtp({required this.verificationId, required this.smsCode});
}

class SendEmailOtp extends RegistrationEvent {
  final String email;

  SendEmailOtp({required this.email});
}

class VerifyEmailOtp extends RegistrationEvent {
  final String emailLink;

  VerifyEmailOtp({required this.emailLink});
}
