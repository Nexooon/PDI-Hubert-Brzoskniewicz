import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdi_main_project/pages/school_admin/subject_timetable_page.dart';
import 'package:pdi_main_project/service/database.dart';

class SubjectsPageSa extends StatefulWidget {
  final DatabaseMethods databaseMethods;
  final String schoolId;
  final String classId;
  final String className;

  const SubjectsPageSa({
    super.key,
    required this.databaseMethods,
    required this.schoolId,
    required this.classId,
    required this.className,
  });

  @override
  State<SubjectsPageSa> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPageSa> {
  Future<List<Map<String, dynamic>>>? _subjectsFuture;
  String? currentYear;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
    _loadCurrentYear();
  }

  void _loadSubjects() {
    setState(() {
      _subjectsFuture = widget.databaseMethods.getSubjectsForClass(
        widget.schoolId,
        widget.classId,
      );
    });
  }

  void _loadCurrentYear() async {
    final year = await widget.databaseMethods.getCurrentYear(widget.schoolId);
    setState(() {
      currentYear = year;
    });
  }

  Future<String> _getTeacherName(DocumentReference ref) async {
    final snapshot = await ref.get();
    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) return 'Nieznany nauczyciel';
    return '${data['name'] ?? ''} ${data['surname'] ?? ''}';
  }

  void _showEditDialog({
    String? subjectId,
    Map<String, dynamic>? subjectData,
  }) async {
    final isEdit = subjectId != null;
    final nameController =
        TextEditingController(text: subjectData?['name'] ?? '');
    final yearController =
        TextEditingController(text: subjectData?['year'] ?? currentYear ?? '');
    final teachers = await widget.databaseMethods.getTeachers(widget.schoolId);
    DocumentReference? selectedTeacher = subjectData?['employee'];

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(isEdit ? 'Edytuj przedmiot' : 'Dodaj przedmiot'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration:
                      const InputDecoration(labelText: 'Nazwa przedmiotu'),
                ),
                TextField(
                  controller: yearController,
                  decoration: const InputDecoration(labelText: 'Rok szkolny'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<DocumentReference>(
                  value: selectedTeacher,
                  decoration: const InputDecoration(labelText: 'Nauczyciel'),
                  items: teachers.map((teacher) {
                    return DropdownMenuItem<DocumentReference>(
                      value: teacher['ref'],
                      child: Text(teacher['fullName']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedTeacher = value;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anuluj'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final year = yearController.text.trim();

                if (name.isNotEmpty &&
                    year.isNotEmpty &&
                    selectedTeacher != null) {
                  // final subjectDataToSave = {
                  //   'name': name,
                  //   'year': year,
                  //   'employee': selectedTeacher!,
                  // };

                  if (isEdit) {
                    await widget.databaseMethods.updateSubject(
                        widget.schoolId,
                        widget.classId,
                        subjectId,
                        name,
                        year,
                        selectedTeacher!);
                  } else {
                    await widget.databaseMethods.addSubject(
                      widget.schoolId,
                      widget.classId,
                      name,
                      year,
                      selectedTeacher!,
                    );
                  }

                  Navigator.pop(context);
                  _loadSubjects(); // odśwież listę
                }
              },
              child: Text(isEdit ? 'Zapisz' : 'Dodaj'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(String subjectId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Usuń przedmiot'),
        content: const Text('Czy na pewno chcesz usunąć ten przedmiot?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anuluj')),
          ElevatedButton(
            onPressed: () async {
              await widget.databaseMethods.deleteSubject(
                widget.schoolId,
                widget.classId,
                subjectId,
              );
              Navigator.pop(context);
              _loadSubjects();
            },
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Przedmioty klasy ${widget.className}')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _subjectsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Błąd: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Brak przedmiotów'));
          }

          final subjects = snapshot.data!;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView.builder(
                itemCount: subjects.length,
                itemBuilder: (context, index) {
                  final subject = subjects[index];
                  return FutureBuilder<String>(
                    future: _getTeacherName(subject['employee']),
                    builder: (context, snapshot) {
                      final teacherName = snapshot.data ?? 'Wczytywanie...';
                      return ListTile(
                        title: Text(subject['name']),
                        subtitle: Text(
                            'Rok: ${subject['year']}, nauczyciel: $teacherName'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.schedule),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SubjectTimetablePage(
                                      databaseMethods: widget.databaseMethods,
                                      schoolId: widget.schoolId,
                                      classId: widget.classId,
                                      subjectId: subject['id'],
                                      subjectName: subject['name'],
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEditDialog(
                                    subjectId: subject['id'],
                                    subjectData: subject)),
                            IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _confirmDelete(subject['id'])),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
