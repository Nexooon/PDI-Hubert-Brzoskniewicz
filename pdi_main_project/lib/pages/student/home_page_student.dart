import 'package:flutter/material.dart';
import 'package:pdi_main_project/service/auth.dart';
import 'package:pdi_main_project/pages/student/grades_page.dart';

class HomePageStudent extends StatefulWidget {
  final String currentUserUid;

  const HomePageStudent({super.key, required this.currentUserUid});

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
        title: Text('Strona Główna'),
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
                    SizedBox(
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
                        child: Text(
                          '3+',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14.0,
                          ),
                        ),
                      ),
                      title: Text('Oceny'),
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
                      leading: Icon(Icons.calendar_month_outlined),
                      title: Text('Plan zajęć'),
                      onTap: () {
                        // Przejście do strony z planem zajęć
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.event_available_outlined),
                      title: Text('Frekwencja'),
                      onTap: () {
                        // Przejście do strony z frekwencją
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.announcement_outlined),
                      title: Text('Ogłoszenia'),
                      onTap: () {
                        // Przejście do strony z ogłoszeniami
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.task_outlined),
                      title: Text('Zadania'),
                      onTap: () {
                        // Przejście do strony z zadaniami
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.menu_book_rounded),
                      title: Text('Przedmioty'),
                      onTap: () {
                        // Przejście do strony z przedmiotami
                      },
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.logout,
                color: Colors.black,
              ),
              title: Text(
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
            Text(
              'Dzisiejszy plan zajęć',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Tutaj będzie widget pokazujący dzisiejszy plan zajęć
            SizedBox(height: 20),
            Text(
              'Ostatnie oceny',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Tutaj będzie widget pokazujący ostatnie oceny
          ],
        ),
      ),
    );
  }
}
