import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:tao_status_tracker/bloc/create_habit/bloc.dart';
import 'package:tao_status_tracker/core/services/auth_service.dart';
import 'package:tao_status_tracker/core/services/habit_reminder_scheduler.dart';
import 'package:tao_status_tracker/core/services/in_app_notification_service.dart';
import 'package:tao_status_tracker/presentation/screens/login_screen.dart';
import 'package:tao_status_tracker/presentation/screens/registration_screen.dart';
import 'package:tao_status_tracker/presentation/screens/splash_screen.dart';
import 'package:tao_status_tracker/bloc/habit_notification/notification_bloc.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
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

  // Initialize in-app notification service
  final notificationService = InAppNotificationService();
  await notificationService.initialize();
  
  // Initialize habit reminder scheduler
  final habitScheduler = HabitReminderScheduler();
  habitScheduler.initialize();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<NotificationBloc>(
          create: (context) => NotificationBloc(notificationService: notificationService),
        ),
        BlocProvider<CreateHabitBloc>(
          create: (context) => CreateHabitBloc(),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'Habit Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: Color(0xFFDB501D),
        ),
        home: const SplashScreen(),
        routes: {
          '/login': (context) => LoginScreen(),
          '/register': (context) => const RegistrationScreen(),
        },
      ),
    );
  }
}