import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:tao_status_tracker/presentation/screens/login_screen.dart';
import 'package:tao_status_tracker/presentation/screens/registration_screen.dart';
import 'package:tao_status_tracker/presentation/screens/splash_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load();
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: dotenv.env['API_KEY']!,
        appId: dotenv.env['APP_ID']!,
        messagingSenderId: dotenv.env['MESSAGING_SENDER_ID']!,
        projectId: dotenv.env['PROJECT_ID']!,
        storageBucket: dotenv.env['STORAGE_BUCKET']!,
      ),
    );

    // Initialize App Check with debug provider for development
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
    
    // For production, use these providers instead:
    // androidProvider: AndroidProvider.playIntegrity,
    // appleProvider: AppleProvider.appAttest,
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // Continue running app even if Firebase fails to initialize
  }

  runApp(MyApp());
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
