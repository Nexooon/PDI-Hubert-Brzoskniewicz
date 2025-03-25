import 'package:flutter/material.dart';
import 'package:pdi_main_project/service/database.dart';

class AnnouncementsWidget extends StatelessWidget {
  final String schoolId;
  final int maxAnnouncements;
  final DatabaseMethods databaseMethods;

  const AnnouncementsWidget({
    super.key,
    required this.databaseMethods,
    required this.schoolId,
    this.maxAnnouncements = 3,
  });

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
    return FutureBuilder<List<Map<String, dynamic>>>(
      future:
          databaseMethods.getLatestAnnouncements(schoolId, maxAnnouncements),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Brak ogłoszeń'));
        }

        final announcements = snapshot.data!;

        return ListView.builder(
          shrinkWrap: true,
          itemCount: announcements.length,
          itemBuilder: (context, index) {
            final announcement = announcements[index];
            final title = announcement['title'] ?? 'Brak tytułu';
            final content = announcement['content'] ?? 'Brak treści';

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
