import 'package:flutter/material.dart';
import 'package:pdi_main_project/service/auth.dart';
import 'package:pdi_main_project/pages/student/grades_page.dart';

class HomePageParent extends StatefulWidget {
  final String currentUserUid;

  const HomePageParent({super.key, required this.currentUserUid});

  @override
  State<HomePageParent> createState() => _HomePageParentState();
}

class _HomePageParentState extends State<HomePageParent> {
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
