import 'package:flutter/material.dart';
import 'package:pdi_main_project/service/database.dart';

class AnnouncementsPage extends StatefulWidget {
  final String currentUserRole; // "teacher" lub "student"/"parent"
  final String schoolId; // ID szkoły
  final DatabaseMethods databaseMethods;

  const AnnouncementsPage({
    super.key,
    required this.currentUserRole,
    required this.schoolId,
    required this.databaseMethods,
  });

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  late final DatabaseMethods _databaseMethods;
  final Map<int, bool> _expandedState = {};

  @override
  void initState() {
    super.initState();
    _databaseMethods = widget.databaseMethods;
  }

  void _showEditDialog(
      {String? announcementId, String? currentTitle, String? currentContent}) {
    if (announcementId != null) {
      _titleController.text = currentTitle ?? '';
      _contentController.text = currentContent ?? '';
    } else {
      _titleController.clear();
      _contentController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            announcementId == null ? 'Dodaj ogłoszenie' : 'Edytuj ogłoszenie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Tytuł'),
            ),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: 'Treść'),
              keyboardType: TextInputType.multiline,
              maxLines: null,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = _titleController.text;
              final content = _contentController.text;

              try {
                if (announcementId == null) {
                  await _databaseMethods.addAnnouncement(
                    schoolId: widget.schoolId,
                    title: title,
                    content: content,
                  );
                } else {
                  await _databaseMethods.editAnnouncement(
                    announcementId: announcementId,
                    title: title,
                    content: content,
                  );
                }
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Błąd: $e')),
                );
              }
            },
            child: Text(announcementId == null ? 'Dodaj' : 'Zapisz'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = widget.currentUserRole == 'teacher';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ogłoszenia szkolne'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _databaseMethods.getAnnouncements(widget.schoolId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Brak ogłoszeń'));
          }

          final announcements = snapshot.data!;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView.builder(
                itemCount: announcements.length,
                itemBuilder: (context, index) {
                  final announcement = announcements[index];
                  final announcementId = announcement['id'];
                  final title = announcement['title'];
                  final content = announcement['content'];
                  final isExpanded = _expandedState[index] ?? false;

                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text(title),
                          subtitle: Text(
                            isExpanded
                                ? content!
                                : (content!.length > 100
                                    ? '${content!.substring(0, 100)}...'
                                    : content!),
                          ),
                          trailing: isTeacher
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () => _showEditDialog(
                                        announcementId: announcementId,
                                        currentTitle: title,
                                        currentContent: content,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () async {
                                        await _databaseMethods
                                            .deleteAnnouncement(announcementId);
                                      },
                                    ),
                                  ],
                                )
                              : null,
                        ),
                        if (content!.length > 100)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  _expandedState[index] = !isExpanded;
                                });
                              },
                              child: Text(isExpanded ? 'Zwiń' : 'Więcej...'),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: isTeacher
          ? FloatingActionButton(
              onPressed: () => _showEditDialog(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
