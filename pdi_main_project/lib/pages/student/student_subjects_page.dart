import 'package:flutter/material.dart';
import 'package:pdi_main_project/pages/teacher/subject_page.dart';
import 'package:pdi_main_project/service/database.dart';

class StudentSubjectsPage extends StatelessWidget {
  final String studentId;
  final DatabaseMethods databaseMethods;

  const StudentSubjectsPage({
    super.key,
    required this.studentId,
    required this.databaseMethods,
  });

  void _navigateToSubject(
      BuildContext context, String schoolId, String classId, String subjectId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectPage(
          schoolId: schoolId,
          classId: classId,
          subjectId: subjectId,
          currentUserRole: 'student',
          currentUserUid: studentId,
          databaseMethods: databaseMethods,
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _getStudentSubjects() async {
    try {
      return await databaseMethods.getStudentSubjects(studentId);
    } catch (e) {
      throw Exception('Błąd podczas ładowania przedmiotów: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Przedmioty ucznia'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getStudentSubjects(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Błąd: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Brak przedmiotów'));
          } else {
            Map<String, dynamic> studentData = snapshot.data!;
            return ListView.builder(
              itemCount: studentData.length,
              itemBuilder: (context, subjectIndex) {
                String subjectName = studentData.keys.elementAt(subjectIndex);
                return ListTile(
                  title: Text(subjectName),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () {
                    _navigateToSubject(
                        context,
                        studentData[subjectName]['schoolId'],
                        studentData[subjectName]['classId'],
                        studentData[subjectName]['id']);
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
