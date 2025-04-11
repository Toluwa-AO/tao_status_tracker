import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Create user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update the user's display name
      await userCredential.user?.updateDisplayName(name);

      // Send email verification
      await userCredential.user?.sendEmailVerification();

      // Store in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', name);
    } catch (e) {
      throw Exception("Registration failed: ${e.toString()}");
    }
  }

  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Get username from Firebase user
      String username = userCredential.user?.displayName ?? '';
      
      // Optional: Store in SharedPreferences if needed
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', username);
      
      return username;
    } catch (e) {
      throw Exception("Login failed: ${e.toString()}");
    }
  }

  // Get current user's name
  Future<String> getCurrentUserName() async {
    User? user = _auth.currentUser;
    if (user != null) {
      // Refresh user data to ensure we have the latest
      await user.reload();
      return user.displayName ?? '';
    }
    return '';
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear local storage
  }
}

