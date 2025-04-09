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
class SendOtpToPhone extends RegistrationEvent {
  final String phoneNumber;

 SendOtpToPhone({required this.phoneNumber});
}

class VerifyPhoneOtp extends RegistrationEvent {
  final String verificationId;
  final String smsCode;

  VerifyPhoneOtp({required this.verificationId, required this.smsCode});
}

class SendOtpToEmail extends RegistrationEvent {
  final String email;

  SendOtpToEmail({required this.email});
}

class VerifyEmailOtp extends RegistrationEvent {
  final String emailLink;
  final String enteredOtp;

  VerifyEmailOtp({required this.emailLink, required this.enteredOtp});
}
