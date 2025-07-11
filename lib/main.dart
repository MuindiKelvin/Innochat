import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:innochat/config/firebase_config.dart';
import 'package:innochat/screens/auth/login_screen.dart';
import 'package:innochat/screens/home_screen.dart';
import 'package:innochat/services/auth_service.dart';
import 'package:innochat/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Check if a default app already exists
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: firebaseOptions);
    }
  } catch (e) {
    print("Error initializing Firebase: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InnoChat',
      theme: AppTheme.lightTheme,
      home: StreamBuilder(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
