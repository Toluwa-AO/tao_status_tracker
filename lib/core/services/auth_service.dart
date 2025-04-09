import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';


class AuthService {
  Future<void> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Simulating API call
      await Future.delayed(Duration(seconds: 2));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', name);
      await prefs.setString('user_email', email);
      await prefs.setString('user_password', password);
    } catch (e) {
      throw Exception("Registration failed: ${e.toString()}");
    }
  }

  Future<bool> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedEmail = prefs.getString('user_email');
      final storedPassword = prefs.getString('user_password');
      
      if (email == storedEmail && password == storedPassword) {
        return true;
      } else {
        throw Exception("Invalid email or password");
      }
    } catch (e) {
      throw Exception("Login failed: ${e.toString()}");
    }
  }
}
