import 'package:flutter/material.dart';
import 'package:pdi_main_project/pages/announcements_page.dart';
import 'package:pdi_main_project/pages/announcements_widget.dart';
import 'package:pdi_main_project/service/auth.dart';
import 'package:pdi_main_project/pages/student/grades_page.dart';
import 'package:pdi_main_project/service/database.dart';

class HomePageStudent extends StatefulWidget {
  final String currentUserUid;
  final String schoolId;
  final DatabaseMethods databaseMethods;

  const HomePageStudent(
      {super.key,
      required this.currentUserUid,
      required this.schoolId,
      required this.databaseMethods});

  @override
  State<HomePageStudent> createState() => _HomePageStudentState();
}

class _HomePageStudentState extends State<HomePageStudent> {
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
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
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[400],
                        maxRadius: 12.5,
                        child: const Text(
                          '3+',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14.0,
                          ),
                        ),
                      ),
                      title: const Text('Oceny'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GradesPage(
                              currentUserUid: widget.currentUserUid,
                            ),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.calendar_month_outlined),
                      title: const Text('Plan zajęć'),
                      onTap: () {
                        // Przejście do strony z planem zajęć
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.event_available_outlined),
                      title: const Text('Frekwencja'),
                      onTap: () {
                        // Przejście do strony z frekwencją
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.announcement_outlined),
                      title: const Text('Ogłoszenia'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AnnouncementsPage(
                              currentUserRole: 'student',
                              schoolId: widget.schoolId,
                            ),
                          ),
                        );
                        // Przejście do strony z ogłoszeniami
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.task_outlined),
                      title: const Text('Zadania'),
                      onTap: () {
                        // Przejście do strony z zadaniami
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.menu_book_rounded),
                      title: const Text('Przedmioty'),
                      onTap: () {
                        // Przejście do strony z przedmiotami
                      },
                    ),
                  ],
                ),
              ),
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
            const Text(
              'Ostatnie oceny',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Tutaj będzie widget pokazujący ostatnie oceny
            const Padding(
              padding: EdgeInsets.all(8.0),
              child:
                  Text('Najnowsze ogłoszenia', style: TextStyle(fontSize: 20)),
            ),
            Expanded(
              child: AnnouncementsWidget(
                  databaseMethods: widget.databaseMethods,
                  schoolId: widget.schoolId),
            ),
          ],
        ),
      ),
    );
  }
}
