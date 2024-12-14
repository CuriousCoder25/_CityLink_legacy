import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewsFeedScreen extends StatelessWidget {
  final String municipalityId; // Municipality ID of the user
  final String languagePreference; // "Nepali" or "English"

  const NewsFeedScreen({super.key, required this.municipalityId, required this.languagePreference});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("News Feed"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('NewsFeed')
            .where('municipality_id', isEqualTo: "1234567") // Fixed municipality ID
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No news updates available."));
          }

          final newsList = snapshot.data!.docs;

          return ListView.builder(
            itemCount: newsList.length,
            itemBuilder: (context, index) {
              final news = newsList[index];
              final title = languagePreference == "Nepali"
                  ? news['title_nepali'] ?? news['title']
                  : news['title'];
              final content = languagePreference == "Nepali"
                  ? news['content_nepali'] ?? news['content']
                  : news['content'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                child: ListTile(
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(content),
                  trailing: Text(
                    _formatTimestamp(news['created_at']),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year}";
  }
}
