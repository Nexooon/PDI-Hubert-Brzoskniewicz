import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdi_main_project/pages/teacher/final_grades_page.dart';
import 'package:pdi_main_project/service/database.dart';
import 'package:pdi_main_project/pages/teacher/grade_entry.dart';

class TeacherGradesPage extends StatefulWidget {
  final String schoolId;
  final String classId;
  final String subjectId;
  final String subjectName;
  final String year;
  final DatabaseMethods databaseMethods;

  const TeacherGradesPage({
    super.key,
    required this.schoolId,
    required this.classId,
    required this.subjectId,
    required this.subjectName,
    required this.year,
    required this.databaseMethods,
  });

  @override
  State<TeacherGradesPage> createState() => _TeacherGradesPageState();
}

class _TeacherGradesPageState extends State<TeacherGradesPage> {
  late Future<List<Map<String, dynamic>>> _studentsGradesFuture;
  final List<String> _additionalGradeTypes = [];
  final List<GradeEntry> _gradesToAdd = [];

  // Funkcja dodająca nowy typ oceny do tabeli
  void addNewGradeType(String gradeType) {
    setState(() {
      _additionalGradeTypes.remove(gradeType); // usunięcie jeśli już istnieje
      _additionalGradeTypes.insert(0, gradeType); // dodanie na początek
    });
  }

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  void _loadGrades() {
    _studentsGradesFuture = widget.databaseMethods
        .getSubjectGrades(widget.schoolId, widget.classId, widget.subjectId);
  }

  // Funkcja do edycji oceny oraz wagi
  void _editGrade(
      BuildContext context,
      String studentId,
      String studentName,
      String gradeType,
      String currentGrade,
      int currentWeight,
      String currentComment,
      String gradeId) {
    final List<String> gradeOptions = [
      '1',
      '1+',
      '2-',
      '2',
      '2+',
      '3-',
      '3',
      '3+',
      '4-',
      '4',
      '4+',
      '5-',
      '5',
      '5+',
      '6-',
      '6'
    ];

    String? selectedGrade = currentGrade == '-' ? null : currentGrade;
    TextEditingController weightController =
        TextEditingController(text: currentWeight.toString());
    TextEditingController commentController =
        TextEditingController(text: currentComment);
    ValueNotifier<String> errorMessage = ValueNotifier('');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edytuj ocenę i wagę'),
          content: ValueListenableBuilder(
            valueListenable: errorMessage,
            builder: (context, value, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(studentName),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedGrade,
                    items: gradeOptions.map((String grade) {
                      return DropdownMenuItem<String>(
                        value: grade,
                        child: Text(grade),
                      );
                    }).toList(),
                    onChanged: (value) {
                      selectedGrade = value!;
                    },
                    decoration:
                        InputDecoration(labelText: 'Ocena za $gradeType'),
                  ),
                  TextField(
                    controller: weightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Waga'),
                  ),
                  TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                        labelText: 'Komentarz (opcjonalny)'),
                  ),
                  if (value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        value,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              );
            },
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
                try {
                  if (selectedGrade == null || selectedGrade!.isEmpty) {
                    errorMessage.value = 'Wybierz ocenę';
                    return;
                  }

                  GradeEntry gradeEntry = GradeEntry(
                    gradeId: gradeId,
                    studentId: FirebaseFirestore.instance
                        .collection('users')
                        .doc(studentId),
                    subjectId: FirebaseFirestore.instance
                        .collection('schools')
                        .doc(widget.schoolId)
                        .collection('classes')
                        .doc(widget.classId)
                        .collection('subjects')
                        .doc(widget.subjectId),
                    subjectName: widget.subjectName,
                    schoolYear: widget.year,
                    weight: int.parse(weightController.text),
                    isFinal: false,
                    value: selectedGrade,
                    description: gradeType,
                    comment: commentController.text.isEmpty
                        ? ''
                        : commentController.text,
                    date: Timestamp.now().toDate(),
                  );
                  _gradesToAdd.add(gradeEntry);
                  setState(() {});

                  Navigator.of(context).pop();
                } catch (e) {
                  errorMessage.value = 'Waga musi być liczbą całkowitą';
                }
              },
              child: const Text('Zapisz'),
            ),
          ],
        );
      },
    );
  }

  void _editColumnWeight(BuildContext context, String gradeType,
      List<Map<String, dynamic>> studentsGrades) {
    TextEditingController weightController = TextEditingController();
    ValueNotifier<String> errorMessage = ValueNotifier('');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edytuj wagę dla $gradeType'),
          content: ValueListenableBuilder<String>(
            valueListenable: errorMessage,
            builder: (context, value, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: weightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Waga'),
                  ),
                  if (value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        value,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              );
            },
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
                try {
                  if (_gradesToAdd.isNotEmpty) {
                    errorMessage.value = 'Zapisz oceny przed edycją wagi';
                    return;
                  }
                  int newWeight = int.parse(weightController.text);
                  for (var student in studentsGrades) {
                    if (student['grades'].containsKey(gradeType)) {
                      widget.databaseMethods.updateGrade(
                          student['grades'][gradeType]['grade_id'], {
                        'weight': newWeight,
                      });
                    }
                  }
                  setState(() {
                    _loadGrades();
                  });
                  Navigator.of(context).pop();
                } catch (e) {
                  errorMessage.value = 'Waga musi być liczbą całkowitą';
                }
              },
              child: const Text('Zapisz'),
            ),
          ],
        );
      },
    );
  }

  void _saveAllGrades() async {
    for (var grade in _gradesToAdd) {
      final gradeData = {
        'student_id': grade.studentId,
        'subject_id': grade.subjectId,
        'subject_name': grade.subjectName,
        'school_year': grade.schoolYear,
        'weight': grade.weight,
        'is_final': grade.isFinal,
        'grade_value': grade.value,
        'description': grade.description,
        'comment': grade.comment,
        'date': grade.date,
      };

      if (grade.gradeId.isEmpty) {
        await widget.databaseMethods.addGrade(gradeData);
      } else {
        await widget.databaseMethods.updateGrade(grade.gradeId, gradeData);
      }
    }

    _gradesToAdd.clear();
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TeacherGradesPage(
            schoolId: widget.schoolId,
            classId: widget.classId,
            subjectId: widget.subjectId,
            subjectName: widget.subjectName,
            year: widget.year,
            databaseMethods: widget.databaseMethods,
          ),
        ));
    // setState(() {
    //   _loadGrades();
    // });
  }

  GradeEntry? getPendingGrade(String studentId, String gradeType) {
    try {
      return _gradesToAdd.firstWhere(
        (entry) =>
            entry.studentId.id == studentId && entry.description == gradeType,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Oceny uczniów'),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FinalGradesPage(
                      schoolId: widget.schoolId,
                      classId: widget.classId,
                      subjectId: widget.subjectId,
                      subjectName: widget.subjectName,
                      year: widget.year,
                      databaseMethods: widget.databaseMethods,
                    ),
                  ),
                );
              },
              child: const Text('Oceny końcowe')),
          IconButton(
            icon: _gradesToAdd.isEmpty
                ? const Icon(Icons.save, color: Colors.grey)
                : const Icon(Icons.save),
            tooltip: 'Zapisz wszystkie oceny',
            onPressed: _gradesToAdd.isEmpty ? null : _saveAllGrades,
          ),
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
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Błąd: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Brak ocen'));
            } else {
              List<Map<String, dynamic>> studentsGrades = snapshot.data!;

              final List<dynamic> gradeTypes = studentsGrades
                  .expand((student) => student['grades'].keys)
                  .toSet()
                  .toList()
                ..insertAll(0, _additionalGradeTypes);

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
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
                                  onPressed: () => _editColumnWeight(
                                      context, gradeType, studentsGrades),
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
                              final gradeComment = gradeData?['comment'] ?? '';
                              final gradeId = gradeData?['grade_id'] ?? '';

                              GradeEntry? pending = getPendingGrade(
                                  student['student_id'], gradeType);
                              final displayValue = pending?.value ?? gradeValue;
                              final isPending = pending != null;

                              return DataCell(
                                GestureDetector(
                                  onTap: () {
                                    _editGrade(
                                        context,
                                        student['student_id'],
                                        student['name'],
                                        gradeType,
                                        gradeValue,
                                        gradeWeight,
                                        gradeComment,
                                        gradeId);
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayValue ?? '-',
                                        style: TextStyle(
                                          color: isPending
                                              ? Colors.blue
                                              : Colors.black,
                                          fontWeight: isPending
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      Text(
                                        'Waga: $gradeWeight',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
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
            }
          }),
    );
  }
}
