import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class ComplaintBoxScreen extends StatefulWidget {
  final String municipalityId;

  const ComplaintBoxScreen({super.key, required this.municipalityId});

  @override
  _ComplaintBoxScreenState createState() => _ComplaintBoxScreenState();
}

class _ComplaintBoxScreenState extends State<ComplaintBoxScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitting = false;
  Position? _userLocation;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.denied && permission != LocationPermission.deniedForever) {
        Position position = await Geolocator.getCurrentPosition();
        setState(() => _userLocation = position);
      }
    } catch (e) {
      print('Error fetching location: $e');
    }
  }

  Future<void> _submitComplaint() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a complaint message.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in.');
      }

      final complaint = {
        'user_id': user.uid,
        'message': _messageController.text.trim(),
        'location': _userLocation != null
            ? GeoPoint(_userLocation!.latitude, _userLocation!.longitude)
            : null,
        'status': 'Pending',
        'submitted_at': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('Municipalities')
          .doc(widget.municipalityId) // Use the fixed municipality ID
          .collection('Complaints')
          .add(complaint);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint submitted successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting complaint: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complaint Box')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Your Complaint',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            _isSubmitting
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _submitComplaint,
                    child: const Text('Submit Complaint'),
                  ),
          ],
        ),
      ),
    );
  }
}
