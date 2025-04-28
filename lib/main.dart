import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:provider/provider.dart'; // Import provider package
import 'package:tao_status_tracker/core/services/auth_service.dart'; // Import AuthService
import 'package:tao_status_tracker/presentation/screens/login_screen.dart';
import 'package:tao_status_tracker/presentation/screens/registration_screen.dart';
import 'package:tao_status_tracker/presentation/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "YOUR_API_KEY",
        appId: "YOUR_APP_ID",
        messagingSenderId: "YOUR_SENDER_ID",
        projectId: "YOUR_PROJECT_ID",
        storageBucket: "YOUR_STORAGE_BUCKET",
      ),
    );

    // Initialize App Check with proper error handling
    try {
      final isDebugMode = kDebugMode || kProfileMode;
      await FirebaseAppCheck.instance.activate(
        androidProvider: isDebugMode 
          ? AndroidProvider.debug 
          : AndroidProvider.playIntegrity,
        appleProvider: isDebugMode
          ? AppleProvider.debug
          : AppleProvider.appAttest,
      );
    } catch (e) {
      debugPrint('App Check initialization error: $e');
      // Continue without App Check if initialization fails
    }
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // Continue running app even if Firebase fails to initialize
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()), // Add AuthService provider
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFFDB501D),
      ),
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => const RegistrationScreen(),
      },
    );
  }
}
