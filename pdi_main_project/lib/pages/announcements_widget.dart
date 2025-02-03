import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementsWidget extends StatelessWidget {
  final String schoolId;
  final int maxAnnouncements; // Liczba ogłoszeń do wyświetlenia

  const AnnouncementsWidget({
    super.key,
    required this.schoolId,
    this.maxAnnouncements = 3,
  });

  Stream<QuerySnapshot> getLatestAnnouncements() {
    return FirebaseFirestore.instance
        .collection('announcements')
        .where('school_id', isEqualTo: schoolId)
        .orderBy('date', descending: true)
        .limit(maxAnnouncements)
        .snapshots();
  }

  void _showAnnouncementDialog(
      BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zamknij'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: getLatestAnnouncements(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Brak ogłoszeń'));
        }

        final announcements = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          itemCount: announcements.length,
          itemBuilder: (context, index) {
            final announcement = announcements[index];
            final title = announcement['title'];
            final content = announcement['content'];

            return Card(
              margin:
                  const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              child: ListTile(
                title: Text(title),
                subtitle: Text(
                  content.length > 50
                      ? '${content.substring(0, 50)}...'
                      : content,
                ),
                onTap: () {
                  _showAnnouncementDialog(context, title, content);
                },
              ),
            );
          },
        );
      },
    );
  }
}
