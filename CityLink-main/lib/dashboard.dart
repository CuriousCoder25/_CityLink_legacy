import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _userId;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('No user logged in. Redirecting to login screen.');
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      _userId = user.uid;

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Municipalities')
          .doc('1234567')
          .collection('Users')
          .doc(_userId) // Fetch by UID
          .get();



      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data() as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        _showSnackBar('User data not found. Redirecting to User Details.');
        Navigator.pushReplacementNamed(context, '/user_detail', arguments: {
          'userId': _userId,
          'phoneNumber': user.phoneNumber,
        });
      }
    } catch (e) {
      _showSnackBar('Error fetching user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.green.shade700,
      ),
      body: _userData == null
          ? Center(
              child: ElevatedButton(
                onPressed: _fetchUserData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Retry', style: TextStyle(fontSize: 16)),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade50, Colors.green.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome to your Dashboard!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return _buildDashboardItem(index);
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDashboardItem(int index) {
    final items = [
      {'title': 'Complaint Box', 'icon': Icons.report_problem, 'route': '/complaint_box'},
      {'title': 'Notifications', 'icon': Icons.notifications, 'route': '/notifications'},
      {'title': 'Profile', 'icon': Icons.person, 'route': '/profile'},
      {'title': 'News Feed', 'icon': Icons.feed, 'route': '/news_feed'},
      {'title': 'History', 'icon': Icons.history, 'route': '/history'},
    ];

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, items[index]['route'] as String, arguments: _userData);
      },
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadowColor: Colors.grey.shade300,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.green.shade200, Colors.green.shade300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                items[index]['icon'] as IconData,
                size: 40,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              Text(
                items[index]['title'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
