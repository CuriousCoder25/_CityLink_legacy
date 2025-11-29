import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:municipality_panel/screens/complaints_screen.dart';
import 'package:municipality_panel/screens/dashboard_screen.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';

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
    // Define the municipality ID that will always receive complaints
    const String fixedMunicipalityId = "1234567";

    return MaterialApp(
      title: 'Municipality Panel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/dashboard': (context) => const DashboardScreen(),
'/complaints': (context) => const ComplaintsScreen(municipalityId: fixedMunicipalityId),

      },
    );
  }
}
