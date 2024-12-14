import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';

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
                    return _buildComplaintCard(complaint);
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
            searchQuery = value; // Update the search query
          });
        },
      ),
    );
  }

  Widget _buildComplaintCard(DocumentSnapshot complaint) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      child: ExpansionTile(
        leading: Icon(
          _getIconForComplaintType(complaint['complaint_type']),
          color: Colors.blue,
        ),
        title: Text(complaint['complaint_type']),
        subtitle: Text(
          "Status: ${complaint['status']}\nSubmitted: ${_formatRelativeTime(complaint['submitted_at'])}",
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Complaint Message
                Text(
                  "Message: ${complaint['message']}",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),

                // Display photo if available
                if (complaint['photo_url'] != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Photo:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Image.network(
                        complaint['photo_url'],
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ],
                  ),

                // Display video if available
                if (complaint['video_url'] != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      const Text(
                        "Video:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      VideoWidget(videoUrl: complaint['video_url']),
                    ],
                  ),

                // Display audio if available
                if (complaint['voice_url'] != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      const Text(
                        "Audio:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      AudioWidget(audioUrl: complaint['voice_url']),
                    ],
                  ),

                // Show location if available
                if (complaint['location'] != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      const Text(
                        "Location:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        height: 150,
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              complaint['location'].latitude,
                              complaint['location'].longitude,
                            ),
                            zoom: 14.0,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('complaintLocation'),
                              position: LatLng(
                                complaint['location'].latitude,
                                complaint['location'].longitude,
                              ),
                            ),
                          },
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
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

class VideoWidget extends StatefulWidget {
  final String videoUrl;

  const VideoWidget({super.key, required this.videoUrl});

  @override
  State<VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        : const CircularProgressIndicator();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class AudioWidget extends StatelessWidget {
  final String audioUrl;

  const AudioWidget({super.key, required this.audioUrl});

  @override
  Widget build(BuildContext context) {
    final audioPlayer = AudioPlayer();

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.play_arrow),
          onPressed: () async {
            await audioPlayer.play(UrlSource(audioUrl));
          },
        ),
        IconButton(
          icon: const Icon(Icons.stop),
          onPressed: () async {
            await audioPlayer.stop();
          },
        ),
      ],
    );
  }
}
