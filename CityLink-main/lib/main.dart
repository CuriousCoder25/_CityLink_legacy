import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Import your app screens
import 'package:maincitylink/phone_login.dart';
import 'package:maincitylink/otp.dart';

import 'package:maincitylink/profile_screen.dart';
import 'package:maincitylink/user_detail.dart';
import 'package:maincitylink/dashboard.dart';
import 'package:maincitylink/complain.dart';

import 'news_feed.dart';
import 'notifications.dart';
import 'history.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MainCityLinkApp());
}

class MainCityLinkApp extends StatelessWidget {
  const MainCityLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    const String fixedMunicipalityId = "1234567"; // Fixed ID for complaints

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/phone': (context) => const myPhone(),
        '/otp': (context) => const MyOtp(),
        '/dashboard': (context) => const DashboardScreen(),
        '/user_detail': (context) => const UserDetailsScreen(),
        '/complaint_box': (context) => ComplaintBoxScreen(municipalityId: fixedMunicipalityId),
        '/notifications': (context) => const NotificationsScreen(),
        '/profile': (context) => ProfileScreen(),
        '/history': (context) => ComplaintHistoryScreen(
              userId: FirebaseAuth.instance.currentUser?.uid ?? "",
            ),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/news_feed') {
          final args = settings.arguments as Map<String, dynamic>;
          final municipalityId = args['municipalityId'] as String? ?? fixedMunicipalityId; // Use fixed ID
          final languagePreference = args['languagePreference'] as String? ?? 'English';

          return MaterialPageRoute(
            builder: (context) => NewsFeedScreen(
              municipalityId: municipalityId,
              languagePreference: languagePreference,
            ),
          );
        }
        return null;
      },
    );
  }
}
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () async {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/phone');
      }
    });

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(), // Add your custom splash screen design here
      ),
    );
  }
}
