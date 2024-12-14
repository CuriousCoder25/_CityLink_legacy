import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:municipality_panel/screens/complaints_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final String fixedMunicipalityId = "1234567"; // Fixed municipality ID
  String municipalityName = "Loading..."; // Default loading state for municipality name
  String provinceName = "Loading..."; // Default loading state for province name

  @override
  void initState() {
    super.initState();
    _fetchMunicipalityData(); // Fetch the name and province on initialization
  }

  Future<void> _fetchMunicipalityData() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('Municipalities')
          .doc(fixedMunicipalityId)
          .get();

      if (docSnapshot.exists) {
        setState(() {
          municipalityName = docSnapshot.data()?['name'] ?? "Unknown Municipality";
          provinceName = docSnapshot.data()?['province'] ?? "Unknown Province";
        });
      } else {
        setState(() {
          municipalityName = "Municipality Not Found";
          provinceName = "Province Not Found";
        });
      }
    } catch (e) {
      setState(() {
        municipalityName = "Error Loading Municipality";
        provinceName = "Error Loading Province";
      });
      debugPrint("Error fetching municipality data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(municipalityName), // Display the fetched municipality name
        backgroundColor: Colors.blue.shade700,
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
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Colors.blue.shade700),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        municipalityName, // Fetch and display municipality name
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      Text(
                        provinceName, // Fetch and display province name
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                // Stay on dashboard
              },
            ),
            // Removed the Complaints ListTile here
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('User Management'),
              onTap: () {
                // Navigate to user management screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Reports'),
              onTap: () {
                // Navigate to reports screen
              },
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Municipality Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              padding: const EdgeInsets.all(16.0),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildDashboardCard(
                  title: 'Total Complaints',
                  subtitle: '5',
                  color: Colors.blue,
                  icon: Icons.chat,
                ),
                _buildDashboardCard(
                  title: 'Add Events/Campaigns',
                  subtitle: 'New Events Endorsed by the municipality',
                  color: Colors.green,
                  icon: Icons.people,
                ),
                _buildDashboardCard(
                  title: 'Emeregency Alerts Issue',
                  subtitle: 'EAS',
                  color: Colors.orange,
                  icon: Icons.check_circle,
                ),
              ],
            ),
          ),
          Container(
            color: Colors.grey.shade200,
            padding: const EdgeInsets.all(16.0),
            alignment: Alignment.center,
            child: const Text(
              'Copyright © 2024 Municipality Panel. All rights reserved.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: color.withOpacity(0.1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                if (title == 'Total Complaints') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ComplaintsScreen(
                        municipalityId: fixedMunicipalityId,
                      ),
                    ),
                  );
                }
              },
              child: const Text(
                'More Info',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
