import 'package:flutter/material.dart';
import 'package:pdi_main_project/pages/announcements_page.dart';
import 'package:pdi_main_project/pages/announcements_widget.dart';
import 'package:pdi_main_project/pages/student/attendance_page.dart';
import 'package:pdi_main_project/pages/student/grades_page.dart';
import 'package:pdi_main_project/service/auth.dart';
import 'package:pdi_main_project/service/database.dart';

class HomePageParent extends StatefulWidget {
  final String currentUserUid;
  final String schoolId;
  final DatabaseMethods databaseMethods;

  const HomePageParent(
      {super.key,
      required this.currentUserUid,
      required this.schoolId,
      required this.databaseMethods});

  @override
  State<HomePageParent> createState() => _HomePageParentState();
}

class _HomePageParentState extends State<HomePageParent> {
  Future<Map<String, dynamic>> _loadChildrenData() async {
    try {
      return await widget.databaseMethods.getChildren(widget.currentUserUid);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<void> signOut() async {
    await Auth().signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Strona główna rodzica',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text(
              'Wyloguj',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: signOut,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadChildrenData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Błąd podczas ładowania danych'));
          } else if (snapshot.data!.containsKey('error')) {
            return Center(child: Text('Błąd: ${snapshot.data!['error']}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Brak danych o dzieciach'));
          }

          Map<String, dynamic> children = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Twoje dzieci',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: children.length,
                    itemBuilder: (context, index) {
                      String childId = children.keys.elementAt(index);
                      String childName = children[childId];
                      return Card(
                        child: ListTile(
                          title: Text(childName),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  // Nawigacja do strony z ocenami
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => GradesPage(
                                        currentUserUid: childId,
                                        databaseMethods: widget.databaseMethods,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Oceny'),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AttendancePage(
                                        currentUserUid: childId,
                                        userRole: 'parent',
                                        databaseMethods: widget.databaseMethods,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Frekwencja'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                // const Text(
                //   'Ogłoszenia',
                //   style: TextStyle(
                //     fontSize: 24,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Najnowsze ogłoszenia',
                      style: TextStyle(fontSize: 20)),
                ),
                Expanded(
                  child: AnnouncementsWidget(
                    databaseMethods: widget.databaseMethods,
                    schoolId: widget.schoolId,
                  ),
                ),
                ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnnouncementsPage(
                            currentUserRole: 'parent',
                            schoolId: widget.schoolId,
                            databaseMethods: widget.databaseMethods,
                          ),
                        ),
                      );
                    },
                    child: const Text('Strona ogłoszeń')),
              ],
            ),
          );
        },
      ),
    );
  }
}
