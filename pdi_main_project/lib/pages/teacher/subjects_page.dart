import 'package:flutter/material.dart';
import 'package:pdi_main_project/pages/teacher/subject_page.dart';
import 'package:pdi_main_project/service/database.dart';

class SubjectsPage extends StatelessWidget {
  final String teacherId;
  const SubjectsPage({super.key, required this.teacherId});

  void _navigateToSubject(
      BuildContext context, String schoolId, String classId, String subjectId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectPage(
          schoolId: schoolId,
          classId: classId,
          subjectId: subjectId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Przedmioty nauczyciela'),
      ),
      body: FutureBuilder<Map<String, Map<String, List<Map<String, String>>>>>(
        future: DatabaseMethods().getTeacherSubjects(teacherId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Błąd: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Brak przedmiotów'));
          } else {
            Map<String, Map<String, List<Map<String, String>>>> teacherData =
                snapshot.data!;
            return ListView.builder(
              itemCount: teacherData.length,
              itemBuilder: (context, schoolIndex) {
                String schoolName = teacherData.keys.elementAt(schoolIndex);
                Map<String, List<Map<String, String>>> classes =
                    teacherData[schoolName]!;
                return ExpansionTile(
                  title: Text(schoolName),
                  children: classes.keys.map((className) {
                    List<Map<String, String>> subjects = classes[className]!;
                    return ExpansionTile(
                      title: Text(className),
                      children: subjects.map((subject) {
                        return ListTile(
                          title: Text(subject['name']!),
                          onTap: () => _navigateToSubject(
                            context,
                            subject['schoolId']!,
                            subject['classId']!,
                            subject['id']!,
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                );
              },
            );
          }
        },
      ),
    );
  }
}
