import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintsScreen extends StatefulWidget {
  final String municipalityId;

  const ComplaintsScreen({super.key, required this.municipalityId});

  @override
  _ComplaintsScreenState createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> _complaintsStream;
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _complaintsStream = _getFilteredStream(_selectedStatus);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getFilteredStream(String status) {
    var query = FirebaseFirestore.instance
        .collection('Municipalities')
        .doc(widget.municipalityId)
        .collection('Complaints')
        .orderBy('submitted_at', descending: true);

    if (status != 'All') {
      query = query.where('status', isEqualTo: status.toLowerCase());
    }

    return query.snapshots();
  }
Future<void> _updateComplaintStatus(String complaintId, String newStatus) async {
  try {
    final complaintRef = FirebaseFirestore.instance
        .collection('Municipalities')
        .doc(widget.municipalityId)
        .collection('Complaints')
        .doc(complaintId);

    // Update status and 'updated_at' timestamp
    await complaintRef.update({
      'status': newStatus.toLowerCase(),
      'updated_at': Timestamp.now(),
    });

    // Handle additional actions based on the status
    if (newStatus == 'verified') {
      // Add to NewsFeed collection when verified
      final complaintData = await complaintRef.get();
      final data = complaintData.data();
      if (data != null) {
        await FirebaseFirestore.instance.collection('NewsFeed').add({
          'municipality_id': widget.municipalityId,
          'title': data['message'],
          'content': 'Complaint verified and in progress.',
          'created_at': Timestamp.now(),
        });
      }
    }

    if (newStatus == 'resolved') {
      // Add reward points when resolved
      await complaintRef.update({'reward_points': 50});
    }

    _showSnackbar('Status updated to $newStatus.');
  } catch (e) {
    _showSnackbar('Failed to update status: $e');
  }
}

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

void _viewComplaintDetails(DocumentSnapshot<Map<String, dynamic>> complaint) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final data = complaint.data();
      final isAnonymous = data?['anonymous'] ?? false;
      final location = data?['location'];
      final photoUrl = data?['photo_url'];
      final videoUrl = data?['video_url'];
      final status = data?['status']?.toLowerCase() ?? 'pending'; // Default to 'pending' if null

      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Complaint ID: ${complaint.id}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text('Description: ${data?['message'] ?? 'No description'}'),
              if (!isAnonymous)
                Text('User ID: ${data?['user_id'] ?? 'Not available'}'),
              if (location != null)
                Text('Location: Lat ${location.latitude}, Lng ${location.longitude}'),
              if (photoUrl != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    const Text('Photo:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Image.network(photoUrl, height: 150),
                  ],
                ),
              if (videoUrl != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    const Text('Video:', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        // Add video viewing logic here
                      },
                      child: const Text('View Video'),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              const Text('Update Status:', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 10,
                children: [
                  if (status == 'pending')
                    ElevatedButton(
                      onPressed: () => _updateComplaintStatus(complaint.id, 'resolved'),
                      child: const Text('Mark as Resolved'),
                    ),
                  if (status == 'viewed')
                    ElevatedButton(
                      onPressed: () => _updateComplaintStatus(complaint.id, 'verified'),
                      child: const Text('Verify'),
                    ),
                  if (status == 'viewed')
                    ElevatedButton(
                      onPressed: () => _updateComplaintStatus(complaint.id, 'rejected'),
                      child: const Text('Reject'),
                    ),
                  if (status == 'verified')
                    ElevatedButton(
                      onPressed: () => _updateComplaintStatus(complaint.id, 'Pending'),
                      child: const Text('Mark as Pending'),
                    ),
                  // Add a default button for unexpected cases
                  if (
                      status != 'viewed' &&
                      status != 'verified' &&
                      status != 'pending' &&
                      status != 'resolved')
                    ElevatedButton(
                      onPressed: () => _updateComplaintStatus(complaint.id, 'viewed'),
                      child: const Text('Reset to Viewed'),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaints'),
        backgroundColor: Colors.green.shade700,
        actions: [
          DropdownButton<String>(
            value: _selectedStatus,
            items: ['All',  'Viewed', 'Verified','Pending', 'Resolved']
                .map((status) => DropdownMenuItem(
                      value: status,
                      child: Text(status),
                    ))
                .toList(),
            onChanged: (status) {
              setState(() {
                _selectedStatus = status!;
                _complaintsStream = _getFilteredStream(_selectedStatus);
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
  stream: _complaintsStream,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return const Center(child: Text('No complaints found.'));
    }

    final complaints = snapshot.data!.docs;

    return ListView.builder(
      itemCount: complaints.length,
      itemBuilder: (context, index) {
        final complaint = complaints[index];
        final isAnonymous = complaint['anonymous'] ?? false;

        return Card(
          child: ListTile(
            leading: Icon(
              Icons.report,
              color: complaint['status'] == 'resolved'
                  ? Colors.green
                  : Colors.red.shade700,
            ),
            title: Text(
              isAnonymous
                  ? 'Anonymous Complaint'
                  : 'Complaint ID: ${complaint.id}',
            ),
            subtitle: Text('Status: ${complaint['status'] ?? 'Unknown'}'),
            onTap: () => _viewComplaintDetails(complaint),
          ),
        );
      },
    );
  },
),

    );
  }
}
