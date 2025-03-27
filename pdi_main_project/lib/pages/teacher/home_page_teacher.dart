import 'package:flutter/material.dart';
import 'package:pdi_main_project/pages/announcements_page.dart';
import 'package:pdi_main_project/pages/announcements_widget.dart';
import 'package:pdi_main_project/pages/teacher/subjects_page.dart';
import 'package:pdi_main_project/service/auth.dart';
import 'package:pdi_main_project/service/database.dart';

class HomePageTeacher extends StatefulWidget {
  final String currentUserUid;
  final String schoolId;
  final DatabaseMethods databaseMethods;

  const HomePageTeacher(
      {super.key,
      required this.currentUserUid,
      required this.schoolId,
      required this.databaseMethods});

  @override
  State<HomePageTeacher> createState() => _HomePageTeacherState();
}

class _HomePageTeacherState extends State<HomePageTeacher> {
  Future<void> signOut() async {
    await Auth().signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Strona Główna'),
        backgroundColor: Colors.blue,
      ),
      drawer: Drawer(
        width: 240.0,
        child: Column(
          children: <Widget>[
            const SizedBox(
              width: double.infinity,
              height: 140.0,
              child: DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('Plan zajęć'),
              onTap: () {
                // Przejście do strony z planem zajęć
              },
            ),
            ListTile(
              leading: const Icon(Icons.announcement_outlined),
              title: const Text('Ogłoszenia'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnnouncementsPage(
                      currentUserRole: 'teacher',
                      schoolId: widget.schoolId,
                      databaseMethods: widget.databaseMethods,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_rounded),
              title: const Text('Strony przedmiotowe'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubjectsPage(
                      teacherId: widget.currentUserUid,
                    ),
                  ),
                );
              },
            ),
            Expanded(
              child: Container(),
            ),
            ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.black,
              ),
              title: const Text(
                'Wyloguj się',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              tileColor: Colors.red,
              onTap: () {
                signOut();
              },
            ),
            const SizedBox(
              height: 20.0,
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Dzisiejszy plan zajęć',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Tutaj będzie widget pokazujący dzisiejszy plan zajęć
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child:
                  Text('Najnowsze ogłoszenia', style: TextStyle(fontSize: 20)),
            ),
            Expanded(
              child: AnnouncementsWidget(
                databaseMethods: widget.databaseMethods,
                schoolId: widget.schoolId,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
