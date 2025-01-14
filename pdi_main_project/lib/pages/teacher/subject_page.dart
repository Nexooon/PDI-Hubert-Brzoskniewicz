import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdi_main_project/pages/teacher/teacher_grades_page.dart';
import 'package:pdi_main_project/service/database.dart';

class SubjectPage extends StatelessWidget {
  final String schoolId;
  final String classId;
  final String subjectId;

  const SubjectPage({
    super.key,
    required this.schoolId,
    required this.classId,
    required this.subjectId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Strona przedmiotowa'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            DatabaseMethods().getSubjectDetails(schoolId, classId, subjectId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Błąd: ${snapshot.error}'));
          } else if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Brak danych o przedmiocie'));
          } else {
            var subjectData = snapshot.data!.data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Nazwa przedmiotu: ${subjectData['name']}',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: 200.0,
                    child: FloatingActionButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TeacherGradesPage(
                              schoolId: schoolId,
                              classId: classId,
                              subjectId: subjectId,
                              subjectName: subjectData['name'],
                              year: subjectData['year'],
                            ),
                          ),
                        );
                      },
                      child: Text('Zarządzaj ocenami'),
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
