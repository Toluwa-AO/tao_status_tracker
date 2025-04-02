abstract class RegistrationEvent {}

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

// Add the missing events for social authentication
class RegisterWithGoogle extends RegistrationEvent {}

class RegisterWithFacebook extends RegistrationEvent {}

class RegisterWithApple extends RegistrationEvent {}
