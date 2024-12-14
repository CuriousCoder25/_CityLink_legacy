import 'package:flutter/material.dart';
import 'package:municipality_panel/screens/complaints_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const String fixedMunicipalityId = "1234567"; // Use the fixed municipality ID

    return Scaffold(
      appBar: AppBar(
        title: const Text('Municipality Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/'); // Log out
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Text('Welcome, Admin!', style: TextStyle(color: Colors.white, fontSize: 20)),
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Complaints'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ComplaintsScreen(municipalityId: fixedMunicipalityId),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: const Text('Welcome to the Municipality Dashboard!'),
      ),
    );
  }
}
