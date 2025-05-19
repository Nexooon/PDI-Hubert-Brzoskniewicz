import 'package:flutter/material.dart';
import 'package:pdi_main_project/service/database.dart';

class TeacherAttendancePage extends StatefulWidget {
  final String schoolId;
  final String classId;
  final String subjectId;
  final String subjectName;
  final DatabaseMethods databaseMethods;

  const TeacherAttendancePage({
    super.key,
    required this.schoolId,
    required this.classId,
    required this.subjectId,
    required this.subjectName,
    required this.databaseMethods,
  });

  @override
  State<TeacherAttendancePage> createState() => _TeacherAttendancePageState();
}

class _TeacherAttendancePageState extends State<TeacherAttendancePage> {
  late Future<List<Map<String, dynamic>>> _studentsAttendanceFuture;
  Map<String, String> studentsMap = {}; // ID -> Nazwa ucznia
  Map<String, Map<String, String>> editedAttendance =
      {}; // studentId -> {lessonID -> attendanceStatus}

  @override
  void initState() {
    super.initState();
    _loadStudentsAttendance();
  }

  void _loadStudentsAttendance() {
    _studentsAttendanceFuture = widget.databaseMethods.getStudentsAttendance(
        widget.schoolId, widget.classId, widget.subjectId);
  }

  Future<void> _saveAttendanceChanges() async {
    for (var studentId in editedAttendance.keys) {
      for (var lessonId in editedAttendance[studentId]!.keys) {
        String newStatus = editedAttendance[studentId]![lessonId]!;
        await widget.databaseMethods.updateStudentAttendance(
          widget.schoolId,
          widget.classId,
          widget.subjectId,
          lessonId,
          studentId,
          newStatus,
        );
      }
    }
    setState(() {
      editedAttendance.clear(); // Po zapisaniu czyścimy zmiany
      _loadStudentsAttendance(); // Ponowne pobranie zaktualizowanych danych
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Frekwencja uczniów'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed:
                editedAttendance.isNotEmpty ? _saveAttendanceChanges : null,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _studentsAttendanceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Błąd: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Brak lekcji.'));
          }

          List<Map<String, dynamic>> studentsAttendance = snapshot.data!;

          // Pobranie unikalnych uczniów
          studentsMap.clear();
          for (var lesson in studentsAttendance) {
            for (var student in lesson['students']) {
              studentsMap[student['student_id']] = student['name'];
            }
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  columns: [
                    const DataColumn(label: Text('Uczeń')),
                    ...studentsAttendance.map((lesson) {
                      return DataColumn(
                        label: Text(
                          lesson['date'].toDate().toString().split(' ')[0],
                        ),
                      );
                    }).toList(),
                  ],
                  rows: studentsMap.entries.map((entry) {
                    String studentId = entry.key;
                    String studentName = entry.value;

                    return DataRow(
                      cells: [
                        DataCell(Text(studentName)),
                        ...studentsAttendance.map((lesson) {
                          // String lessonDate =
                          //     lesson['date'].toDate().toString().split(' ')[0];
                          String lessonID = lesson['lesson_id'];

                          var studentData = lesson['students'].firstWhere(
                            (s) => s['student_id'] == studentId,
                            orElse: () => {'attendance': 'Brak danych'},
                          );

                          String? initialAttendanceStatus =
                              studentData['attendance'] == 'Brak danych'
                                  ? null
                                  : studentData['attendance'];

                          String? currentValue = editedAttendance[studentId]
                                  ?[lessonID] ??
                              initialAttendanceStatus;

                          return DataCell(
                            DropdownButton<String>(
                              value: currentValue,
                              hint: const Text("Wybierz"),
                              items: [
                                'Obecny',
                                'Nieobecny',
                                'Spóźniony',
                                'Nieobecny usprawiedliwiony'
                              ]
                                  .map((status) => DropdownMenuItem(
                                        value: status,
                                        child: SizedBox(
                                          width: 126,
                                          child: Text(status,
                                              overflow: TextOverflow.visible),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  editedAttendance.putIfAbsent(
                                      studentId, () => {});
                                  editedAttendance[studentId]![lessonID] =
                                      newValue!;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
