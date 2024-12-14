import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;

class ComplaintHistoryScreen extends StatefulWidget {
  final String userId;

  const ComplaintHistoryScreen({super.key, required this.userId});

  @override
  _ComplaintHistoryScreenState createState() => _ComplaintHistoryScreenState();
}

class _ComplaintHistoryScreenState extends State<ComplaintHistoryScreen> {
  String filterStatus = "All"; // Default filter
  String searchQuery = ""; // Default search query

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Complaint History"),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Municipalities')
                  .doc('1234567') // Fixed municipality ID
                  .collection('Complaints')
                  .where('user_id', isEqualTo: widget.userId)
                  .orderBy('submitted_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No complaints found."));
                }

                var complaints = snapshot.data!.docs.where((doc) {
                  final statusMatches =
                      filterStatus == "All" || doc['status'] == filterStatus;
                  final searchMatches = searchQuery.isEmpty ||
                      doc['complaint_type']
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase()) ||
                      doc['message']
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase());
                  return statusMatches && searchMatches;
                }).toList();

                if (complaints.isEmpty) {
                  return const Center(
                      child: Text("No complaints match your filters."));
                }

                return ListView.builder(
                  itemCount: complaints.length,
                  itemBuilder: (context, index) {
                    final complaint = complaints[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 5.0),
                      child: ListTile(
                        leading: Icon(
                          _getIconForComplaintType(complaint['complaint_type']),
                          color: Colors.blue,
                        ),
                        title: Text(complaint['complaint_type']),
                        subtitle: Text(
                          "Status: ${complaint['status']}\nSubmitted: ${_formatRelativeTime(complaint['submitted_at'])}",
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: InputDecoration(
          labelText: "Search Complaints",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
          prefixIcon: const Icon(Icons.search),
        ),
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Filter Complaints"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterOption("All"),
              _buildFilterOption("Pending"),
              _buildFilterOption("Resolved"),
              _buildFilterOption("Rejected"),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String status) {
    return RadioListTile(
      value: status,
      groupValue: filterStatus,
      title: Text(status),
      onChanged: (value) {
        setState(() {
          filterStatus = value!;
        });
        Navigator.pop(context);
      },
    );
  }

  String _formatRelativeTime(Timestamp timestamp) {
    return timeago.format(timestamp.toDate());
  }

  IconData _getIconForComplaintType(String type) {
    switch (type) {
      case "Hospital":
        return Icons.local_hospital;
      case "Fire Department":
        return Icons.local_fire_department;
      case "Police":
        return Icons.local_police;
      case "Public Complaint":
        return Icons.people;
      default:
        return Icons.report_problem;
    }
  }
}
