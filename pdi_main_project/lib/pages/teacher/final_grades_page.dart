import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdi_main_project/service/database.dart';

class FinalGradesPage extends StatefulWidget {
  final String schoolId;
  final String classId;
  final String subjectId;
  final String subjectName;
  final String year;
  final DatabaseMethods databaseMethods;

  const FinalGradesPage({
    super.key,
    required this.schoolId,
    required this.classId,
    required this.subjectId,
    required this.subjectName,
    required this.year,
    required this.databaseMethods,
  });

  @override
  State<FinalGradesPage> createState() => _FinalGradesPageState();
}

class _FinalGradesPageState extends State<FinalGradesPage> {
  final Map<String, String?> _finalGrades = {};
  final Map<String, String?> _existingFinalGradeIds = {};
  final List<String> _gradeOptions = [
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

  late Future<List<Map<String, dynamic>>> _studentsFuture;

  @override
  void initState() {
    super.initState();
    _studentsFuture = widget.databaseMethods.getStudentsWithFinalGrades(
      widget.schoolId,
      widget.classId,
      widget.subjectId,
      widget.year,
    );
  }

  void _saveFinalGrades() async {
    for (final entry in _finalGrades.entries) {
      final studentId = entry.key;
      final gradeValue = entry.value;

      if (gradeValue != null) {
        final gradeData = {
          'student_id':
              FirebaseFirestore.instance.collection('users').doc(studentId),
          'subject_id': FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('classes')
              .doc(widget.classId)
              .collection('subjects')
              .doc(widget.subjectId),
          'subject_name': widget.subjectName,
          'school_year': widget.year,
          'weight': 1,
          'is_final': true,
          'grade_value': gradeValue,
          'description': 'Ocena końcowa',
          'comment': '',
          'date': DateTime.now(),
        };

        final existingGradeId = _existingFinalGradeIds[studentId];

        if (existingGradeId != null) {
          await widget.databaseMethods.updateGrade(existingGradeId, gradeData);
        } else {
          await widget.databaseMethods.addGrade(gradeData);
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oceny końcowe zapisane')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Oceny końcowe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Zapisz oceny końcowe',
            onPressed: _saveFinalGrades,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _studentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Brak uczniów'));
          }

          final students = snapshot.data!;

          for (final student in students) {
            final studentId = (student['student_id'] as DocumentReference).id;
            final existingGrade = student['final_grade'] as String?;
            final existingGradeId = student['final_grade_id'] as String?;

            _finalGrades.putIfAbsent(studentId, () => existingGrade);
            if (existingGradeId != null) {
              _existingFinalGradeIds[studentId] = existingGradeId;
            }
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  final studentId =
                      (student['student_id'] as DocumentReference).id;
                  final studentName = student['name'] as String;

                  return ListTile(
                    title: Text(studentName),
                    trailing: DropdownButton<String>(
                      hint: const Text('Wybierz'),
                      value: _finalGrades[studentId],
                      items: _gradeOptions.map((grade) {
                        return DropdownMenuItem(
                          value: grade,
                          child: Text(grade),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _finalGrades[studentId] = value;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
