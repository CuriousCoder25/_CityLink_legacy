import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:municipality_panel/screens/dashboard_screen.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'complaints_screen.dart'; // Import the ComplaintsScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Municipality Panel',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
          '/dashboard': (context) => const DashboardScreen(),
                '/complaints': (context) => ComplaintsScreen(municipalityId: 'municipalityId123'),  // Define the complaints route

      },
    );
  }
}
