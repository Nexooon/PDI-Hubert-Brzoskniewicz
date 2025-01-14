import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdi_main_project/service/database.dart';

class TeacherGradesPage extends StatefulWidget {
  final String schoolId;
  final String classId;
  final String subjectId;
  final String subjectName;
  final String year;

  const TeacherGradesPage(
      {super.key,
      required this.schoolId,
      required this.classId,
      required this.subjectId,
      required this.subjectName,
      required this.year});

  @override
  State<TeacherGradesPage> createState() => _TeacherGradesPageState();
}

class _TeacherGradesPageState extends State<TeacherGradesPage> {
  late Future<List<Map<String, dynamic>>> _studentsGradesFuture;
  final Set<String> _additionalGradeTypes = {};

  // Funkcja dodająca nowy typ oceny do tabeli
  void addNewGradeType(String gradeType) {
    setState(() {
      _additionalGradeTypes.add(gradeType);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  void _loadGrades() {
    DocumentReference subjectRef = FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('classes')
        .doc(widget.classId)
        .collection('subjects')
        .doc(widget.subjectId);
    _studentsGradesFuture = DatabaseMethods().getSubjectGrades(subjectRef);
  }

  // final List<Map<String, dynamic>> studentsGrades = [
  //   {
  //     'name': 'Jan Kowalski',
  //     'student_id': '873hcds98y3hbasdva',
  //     'grades': {
  //       'exam': {'value': '4+', 'weight': 3, 'grade_id': '873hcds98y3hb'},
  //       'homework': {'value': '5', 'weight': 1, 'grade_id': '873hcds98y3hba'},
  //       'quiz': {'value': '3', 'weight': 2, 'grade_id': '873hcds98y3hbc'},
  //     },
  //   },
  //   {
  //     'name': 'Anna Nowak',
  //     'student_id': '873hcds98y3hbasdv',
  //     'grades': {
  //       'exam': {'value': '5', 'weight': 3, 'grade_id': '873hcds98y3hbd'},
  //       'homework': {'value': '4', 'weight': 1, 'grade_id': '873hcds98y3hbe'},
  //       'quiz': {'value': '4+', 'weight': 2, 'grade_id': '873hcds98y3hbf'},
  //     },
  //   },
  //   {
  //     'name': 'Piotr Zieliński',
  //     'student_id': '873hcds98y3hbasdvv',
  //     'grades': {
  //       'exam': {'value': '3', 'weight': 3, 'grade_id': '873hcds98y3hbg'},
  //       'homework': {'value': '3+', 'weight': 1, 'grade_id': '873hcds98y3hbh'},
  //     },
  //   },
  // ];

  // Funkcja do edycji oceny oraz wagi
  void _editGrade(
      BuildContext context,
      String studentId,
      String studentName,
      String gradeType,
      String currentGrade,
      int currentWeight,
      String gradeId) {
    TextEditingController gradeController =
        TextEditingController(text: currentGrade);
    TextEditingController weightController =
        TextEditingController(text: currentWeight.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edytuj ocenę i wagę'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(studentName),
              SizedBox(height: 8),
              TextField(
                controller: gradeController,
                decoration: InputDecoration(labelText: 'Ocena za $gradeType'),
              ),
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Waga'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Anuluj'),
            ),
            TextButton(
              onPressed: () {
                var gradeInfo = {
                  'student_id': FirebaseFirestore.instance
                      .collection('users')
                      .doc(studentId),
                  'subject_id': FirebaseFirestore.instance
                      .collection('schools')
                      .doc(widget.schoolId)
                      .collection('classes')
                      .doc(widget.classId)
                      .collection('subjects')
                      .doc(widget.subjectId),
                  'subject_name': widget.subjectName,
                  'description': gradeType,
                  'grade_value': gradeController.text,
                  'weight': int.parse(weightController.text),
                  'school_year': widget.year,
                  'is_final': false,
                  'date': Timestamp.now().toDate(),
                };
                if (currentGrade == '-') {
                  DatabaseMethods().addGrade(gradeInfo);
                } else {
                  DatabaseMethods().updateGrade(gradeId, gradeInfo);
                }

                setState(() {
                  _loadGrades();
                });
                Navigator.of(context).pop();
              },
              child: const Text('Zapisz'),
            ),
          ],
        );
      },
    );
  }

  //TODO nie dziala
  // Funkcja do masowej edycji wagi dla całej kolumny
  void _editColumnWeight(BuildContext context, String gradeType) {
    TextEditingController weightController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edytuj wagę dla $gradeType'),
          content: TextField(
            controller: weightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Waga'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Anuluj'),
            ),
            TextButton(
              onPressed: () {
                // setState(() {
                //   int newWeight = int.parse(weightController.text);
                //   for (var student in studentsGrades) {
                //     if (student['grades'].containsKey(gradeType)) {
                //       student['grades'][gradeType]['weight'] = newWeight;
                //     }
                //   }
                // });
                Navigator.of(context).pop();
              },
              child: const Text('Zapisz'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Oceny uczniów'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              String? newGradeType = await showDialog<String>(
                context: context,
                builder: (BuildContext context) {
                  TextEditingController controller = TextEditingController();
                  return AlertDialog(
                    title: const Text('Nowy typ oceny'),
                    content: TextField(
                      controller: controller,
                      decoration:
                          const InputDecoration(labelText: 'Nazwa oceny'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Anuluj'),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pop(controller.text),
                        child: const Text('Dodaj'),
                      ),
                    ],
                  );
                },
              );

              if (newGradeType != null && newGradeType.isNotEmpty) {
                addNewGradeType(newGradeType);
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _studentsGradesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Błąd: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('Brak ocen'));
            } else {
              List<Map<String, dynamic>> studentsGrades = snapshot.data!;

              // Uzupełnij `gradeTypes` o dodatkowe kolumny
              final Set<dynamic> gradeTypes = studentsGrades
                  .expand((student) => student['grades'].keys)
                  .toSet()
                ..addAll(_additionalGradeTypes);

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: DataTable(
                  columns: [
                    const DataColumn(label: Text('Uczeń')),
                    ...gradeTypes.map((gradeType) {
                      return DataColumn(
                        label: Row(
                          children: [
                            Text(gradeType),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: () =>
                                  _editColumnWeight(context, gradeType),
                              tooltip: 'Edytuj wagę kolumny',
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                  rows: studentsGrades.map((student) {
                    return DataRow(
                      cells: [
                        DataCell(Text(student['name'])),
                        ...gradeTypes.map((gradeType) {
                          final gradeData = student['grades'][gradeType];
                          final gradeValue = gradeData?['value'] ?? '-';
                          final gradeWeight = gradeData?['weight'] ?? 0;
                          final gradeId = gradeData?['grade_id'] ?? '';

                          return DataCell(
                            GestureDetector(
                              onTap: () => _editGrade(
                                  context,
                                  student['student_id'],
                                  student['name'],
                                  gradeType,
                                  gradeValue,
                                  gradeWeight,
                                  gradeId),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(gradeValue),
                                  Text('Waga: $gradeWeight',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  }).toList(),
                ),
              );
            }
          }),
    );
  }
}
