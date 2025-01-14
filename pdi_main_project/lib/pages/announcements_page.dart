// import 'package:flutter/material.dart';

// class AnnouncementsPage extends StatefulWidget {
//   final String currentUserRole; // "teacher" lub "student"

//   const AnnouncementsPage({super.key, required this.currentUserRole});

//   @override
//   State<AnnouncementsPage> createState() => _AnnouncementsPageState();
// }

// class _AnnouncementsPageState extends State<AnnouncementsPage> {
//   final List<Map<String, String>> _announcements = [];
//   final Map<int, bool> _expandedState = {};

//   final TextEditingController _titleController = TextEditingController();
//   final TextEditingController _contentController = TextEditingController();

//   void _addAnnouncement(String title, String content) {
//     setState(() {
//       _announcements.add({
//         'title': title,
//         'content': content,
//       });
//     });
//   }

//   void _editAnnouncement(int index, String title, String content) {
//     setState(() {
//       _announcements[index] = {
//         'title': title,
//         'content': content,
//       };
//     });
//   }

//   void _deleteAnnouncement(int index) {
//     setState(() {
//       _announcements.removeAt(index);
//       _expandedState.remove(index);
//     });
//   }

//   void _showEditDialog({int? index}) {
//     if (index != null) {
//       _titleController.text = _announcements[index]['title']!;
//       _contentController.text = _announcements[index]['content']!;
//     } else {
//       _titleController.clear();
//       _contentController.clear();
//     }

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(index == null ? 'Dodaj ogłoszenie' : 'Edytuj ogłoszenie'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextField(
//               controller: _titleController,
//               decoration: InputDecoration(labelText: 'Tytuł'),
//             ),
//             TextField(
//               controller: _contentController,
//               decoration: InputDecoration(labelText: 'Treść'),
//               keyboardType: TextInputType.multiline,
//               maxLines: null,
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Anuluj'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               final title = _titleController.text;
//               final content = _contentController.text;
//               if (index == null) {
//                 _addAnnouncement(title, content);
//               } else {
//                 _editAnnouncement(index, title, content);
//               }
//               Navigator.pop(context);
//             },
//             child: Text(index == null ? 'Dodaj' : 'Zapisz'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isTeacher = widget.currentUserRole == 'teacher';

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Ogłoszenia szkolne'),
//       ),
//       body: ListView.builder(
//         itemCount: _announcements.length,
//         itemBuilder: (context, index) {
//           final announcement = _announcements[index];
//           final isExpanded = _expandedState[index] ?? false;

//           return Card(
//             margin: const EdgeInsets.all(8.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 ListTile(
//                   title: Text(announcement['title']!),
//                   subtitle: Text(
//                     isExpanded
//                         ? announcement['content']!
//                         : (announcement['content']!.length > 100
//                             ? '${announcement['content']!.substring(0, 100)}...'
//                             : announcement['content']!),
//                   ),
//                   trailing: isTeacher
//                       ? Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             IconButton(
//                               icon: Icon(Icons.edit, color: Colors.blue),
//                               onPressed: () => _showEditDialog(index: index),
//                             ),
//                             IconButton(
//                               icon: Icon(Icons.delete, color: Colors.red),
//                               onPressed: () => _deleteAnnouncement(index),
//                             ),
//                           ],
//                         )
//                       : null,
//                 ),
//                 if (announcement['content']!.length > 100)
//                   Align(
//                     alignment: Alignment.centerLeft,
//                     child: TextButton(
//                       onPressed: () {
//                         setState(() {
//                           _expandedState[index] = !isExpanded;
//                         });
//                       },
//                       child: Text(isExpanded ? 'Zwiń' : 'Więcej...'),
//                     ),
//                   ),
//               ],
//             ),
//           );
//         },
//       ),
//       floatingActionButton: isTeacher
//           ? FloatingActionButton(
//               onPressed: () => _showEditDialog(),
//               child: Icon(Icons.add),
//             )
//           : null,
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdi_main_project/service/database.dart';

class AnnouncementsPage extends StatefulWidget {
  final String currentUserRole; // "teacher" lub "student"
  final String schoolId; // ID szkoły

  const AnnouncementsPage({
    super.key,
    required this.currentUserRole,
    required this.schoolId,
  });

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final DatabaseMethods _databaseMethods = DatabaseMethods();

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
              decoration: InputDecoration(labelText: 'Tytuł'),
            ),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(labelText: 'Treść'),
              keyboardType: TextInputType.multiline,
              maxLines: null,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Anuluj'),
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
        title: Text('Ogłoszenia szkolne'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _databaseMethods.getAnnouncements(widget.schoolId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Brak ogłoszeń'));
          }

          final announcements = snapshot.data!.docs;

          return ListView.builder(
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final announcement = announcements[index];
              final announcementId = announcement.id;
              final title = announcement['title'];
              final content = announcement['content'];

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text(title),
                      subtitle: Text(content),
                      trailing: isTeacher
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showEditDialog(
                                    announcementId: announcementId,
                                    currentTitle: title,
                                    currentContent: content,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    await _databaseMethods
                                        .deleteAnnouncement(announcementId);
                                  },
                                ),
                              ],
                            )
                          : null,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: isTeacher
          ? FloatingActionButton(
              onPressed: () => _showEditDialog(),
              child: Icon(Icons.add),
            )
          : null,
    );
  }
}
