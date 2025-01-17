import 'package:flutter/material.dart';
import 'package:pdi_main_project/pages/announcements_page.dart';
import 'package:pdi_main_project/pages/student/grades_page.dart';
import 'package:pdi_main_project/service/auth.dart';
import 'package:pdi_main_project/service/database.dart';

class HomePageParent extends StatefulWidget {
  final String currentUserUid;
  final String schoolId;

  const HomePageParent(
      {super.key, required this.currentUserUid, required this.schoolId});

  @override
  State<HomePageParent> createState() => _HomePageParentState();
}

class _HomePageParentState extends State<HomePageParent> {
  Future<Map<String, dynamic>> _loadChildrenData() async {
    try {
      return await DatabaseMethods().getChildren(widget.currentUserUid);
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
        title: Text('Rodzic - strona główna'),
        backgroundColor: Colors.blue,
        actions: [
          TextButton.icon(
            icon: Icon(Icons.logout, color: Colors.white),
            label: Text(
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
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Błąd podczas ładowania danych'));
          } else if (snapshot.data!.containsKey('error')) {
            return Center(child: Text('Błąd: ${snapshot.data!['error']}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Brak danych o dzieciach'));
          }

          Map<String, dynamic> children = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Twoje dzieci',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
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
                                      ),
                                    ),
                                  );
                                },
                                child: Text('Oceny'),
                              ),
                              SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () {
                                  // Nawigacja do strony z frekwencją
                                },
                                child: Text('Frekwencja'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Ogłoszenia',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Tutaj będzie widget pokazujący ogłoszenia
                ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnnouncementsPage(
                            currentUserRole: 'parent',
                            schoolId: widget.schoolId,
                          ),
                        ),
                      );
                    },
                    child: Text('Ogłoszenia'))
              ],
            ),
          );
        },
      ),
    );
  }
}
