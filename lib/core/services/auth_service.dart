import 'package:firebase_auth/firebase_auth.dart';
import 'package:tao_status_tracker/core/utils/security_utils.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Validate current session
  Future<bool> validateSession() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      await user.reload();
      return user.emailVerified;
    } catch (e) {
      SecurityUtils.secureLog('Session validation error: $e');
      return false;
    }
  }

  // Get current user ID safely
  Future<String?> getCurrentUserName() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      
      // Validate session before returning user ID
      if (await validateSession()) {
        return user.uid;
      }
      return null;
    } catch (e) {
      SecurityUtils.secureLog('Error getting current user: $e');
      return null;
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      // Validate input
      if (!SecurityUtils.isValidEmail(email) || password.length < 6) {
        throw 'Sign in failed. Please check your credentials';
      }

      // Rate limiting
      if (!SecurityUtils.canMakeRequest(email, cooldownSeconds: 3)) {
        throw 'Too many requests. Please wait.';
      }

      final credential = await _auth.signInWithEmailAndPassword(
        email: SecurityUtils.sanitizeInput(email),
        password: password,
      );
      
      SecurityUtils.secureLog('User signed in successfully');
      return credential;
    } catch (e) {
      SecurityUtils.secureLog('Sign in error: $e');
      rethrow;
    }
  }

  // Create user with email and password
  Future<UserCredential?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      // Validate input
      if (!SecurityUtils.isValidEmail(email) || password.length < 6) {
        throw 'Sign Up failed. Please check your credentials';
      }

      // Rate limiting
      if (!SecurityUtils.canMakeRequest(email, cooldownSeconds: 5)) {
        throw 'Too many requests. Please wait.';
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: SecurityUtils.sanitizeInput(email),
        password: password,
      );
      
      // Send email verification
      await credential.user?.sendEmailVerification();
      
      SecurityUtils.secureLog('User created successfully');
      return credential;
    } catch (e) {
      SecurityUtils.secureLog('User creation error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      final userId = _auth.currentUser?.uid;
      await _auth.signOut();
      
      // Clear rate limiting data for this user
      if (userId != null) {
        SecurityUtils.clearRateLimit(userId);
      }
      
      SecurityUtils.secureLog('User signed out successfully');
    } catch (e) {
      SecurityUtils.secureLog('Sign out error: $e');
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      if (!SecurityUtils.isValidEmail(email)) {
        throw 'Invalid email format';
      }

      // Rate limiting
      if (!SecurityUtils.canMakeRequest(email, cooldownSeconds: 60)) {
        throw 'Password reset already requested. Please wait.';
      }

      await _auth.sendPasswordResetEmail(email: SecurityUtils.sanitizeInput(email));
      SecurityUtils.secureLog('Password reset email sent');
    } catch (e) {
      SecurityUtils.secureLog('Password reset error: $e');
      rethrow;
    }
  }

  // Check if user is authenticated and verified
  bool get isAuthenticated {
    final user = _auth.currentUser;
    return user != null && user.emailVerified;
  }
}