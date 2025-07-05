import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tao_status_tracker/bloc/create_habit/bloc.dart';
import 'package:tao_status_tracker/core/services/app_security_service.dart';
import 'package:tao_status_tracker/core/services/habit_reminder_scheduler.dart';
import 'package:tao_status_tracker/firebase_options.dart';
import 'package:tao_status_tracker/presentation/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env.production");
  } catch (e) {
    debugPrint('Environment file not found, using defaults');
  }
  
  // Initialize Firebase with secure configuration
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize security service
  AppSecurityService();
  
  // Initialize habit reminder scheduler
  HabitReminderScheduler().initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CreateHabitBloc>(
          create: (context) => CreateHabitBloc(),
        ),
      ],
      child: MaterialApp(
        title: 'Tao Status Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const LoginScreen(),
      ),
    );
  }
}