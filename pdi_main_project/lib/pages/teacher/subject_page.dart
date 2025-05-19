import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdi_main_project/pages/student/task_page_student.dart';
import 'package:pdi_main_project/pages/teacher/students_tasks_page.dart';
import 'package:pdi_main_project/pages/teacher/teacher_attendance_page.dart';
import 'package:pdi_main_project/pages/teacher/teacher_grades_page.dart';
import 'package:pdi_main_project/service/database.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

class SubjectPage extends StatefulWidget {
  final String schoolId;
  final String classId;
  final String subjectId;
  final String currentUserRole;
  final String currentUserUid;
  final DatabaseMethods databaseMethods;

  const SubjectPage({
    super.key,
    required this.schoolId,
    required this.classId,
    required this.subjectId,
    required this.currentUserRole,
    required this.currentUserUid,
    required this.databaseMethods,
  });

  @override
  State<SubjectPage> createState() => _SubjectPageState();
}

class _SubjectPageState extends State<SubjectPage> {
  bool showAllTasks = false;
  bool showAllFiles = false;
  bool showAllTopics = false;

  String subjectName = '';
  String className = '';
  String year = '';

  Map<String, dynamic> tasks = {};

  Map<String, dynamic> topics = {};

  List<Map<String, dynamic>> filesData = [];

  @override
  void initState() {
    super.initState();
    _loadSubjectName();
    _loadClassName();
    _loadSubjectYear();
    _loadTopics();
    _loadAssignments();
    _loadFiles();
  }

  void _loadSubjectName() {
    widget.databaseMethods
        .getSubjectName(widget.schoolId, widget.classId, widget.subjectId)
        .then((value) => setState(() => subjectName = value));
  }

  void _loadClassName() {
    widget.databaseMethods
        .getClassName(widget.schoolId, widget.classId)
        .then((value) => setState(() => className = value));
  }

  void _loadSubjectYear() {
    widget.databaseMethods
        .getSubjectYear(widget.schoolId, widget.classId, widget.subjectId)
        .then((value) => setState(() => year = value));
  }

  void _loadTopics() {
    widget.databaseMethods
        .getLessonTopics(widget.schoolId, widget.classId, widget.subjectId)
        .then((value) => setState(() => topics = value));
  }

  void _loadAssignments() {
    widget.databaseMethods
        .getAssignments(widget.schoolId, widget.classId, widget.subjectId)
        .then((value) => setState(() => tasks = value));
  }

  void _loadFiles() {
    widget.databaseMethods
        .getSubjectFiles(widget.schoolId, widget.classId, widget.subjectId)
        .then((value) => setState(() => filesData = value));
  }

  Future<void> _uploadFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    final pickedFile = result.files.single;
    final fileName = pickedFile.name;

    try {
      final storageRef = FirebaseStorage.instance.ref().child(
          'schools/${widget.schoolId}/classes/${widget.classId}/subjects/${widget.subjectId}/files/$fileName');

      UploadTask uploadTask;

      if (kIsWeb) {
        // WEB: używamy danych binarnych
        final data = pickedFile.bytes;
        if (data == null) {
          print('Błąd: nie można odczytać zawartości pliku na web');
          return;
        }
        uploadTask = storageRef.putData(data);
      } else {
        // MOBILE: używamy File
        final filePath = pickedFile.path;
        if (filePath == null) {
          print('Błąd: ścieżka do pliku jest pusta');
          return;
        }
        final file = io.File(filePath);
        uploadTask = storageRef.putFile(file);
      }

      await uploadTask.whenComplete(() => null);
      final downloadUrl = await storageRef.getDownloadURL();

      await widget.databaseMethods.saveFileMetadataToFirestore(
        schoolId: widget.schoolId,
        classId: widget.classId,
        subjectId: widget.subjectId,
        fileName: fileName,
        downloadUrl: downloadUrl,
      );

      _loadFiles();
    } catch (e) {
      print('Błąd przy wgrywaniu pliku: $e');
    }
  }

  Future<void> _deleteFile(String fileName, String url) async {
    try {
      // Usuń plik ze storage
      final ref = FirebaseStorage.instance.refFromURL(url);
      await ref.delete();

      // Usuń dane z Firestore
      await widget.databaseMethods.deleteFileMetadataFromFirestore(
        schoolId: widget.schoolId,
        classId: widget.classId,
        subjectId: widget.subjectId,
        fileUrl: url,
      );

      _loadFiles();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Plik "$fileName" został usunięty')),
      );
    } catch (e) {
      print('Błąd usuwania pliku: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Błąd podczas usuwania pliku')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = widget.currentUserRole == 'teacher';

    return Scaffold(
      appBar: AppBar(title: const Text('Strona przedmiotowa')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              isTeacher
                  ? Text(
                      'Klasa: $className',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    )
                  : const SizedBox.shrink(),
              Text(
                'Przedmiot: $subjectName',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              isTeacher ? _buildManagementButtons() : const SizedBox.shrink(),
              const SizedBox(height: 10),
              _buildTasksSection(isTeacher),
              _buildFilesSection(isTeacher),
              _buildTopicsSection(isTeacher),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTasksSection(bool isTeacher) {
    final taskEntries = tasks.entries.toList();

    return ExpansionTile(
      title: const Text('Zadania'),
      initiallyExpanded: true,
      children: [
        ...taskEntries
            .take(showAllTasks ? taskEntries.length : 3)
            .map((entry) => ListTile(
                  title: Text(entry.value.toString()),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      isTeacher
                          ? MaterialPageRoute(
                              builder: (context) => StudentsTasksPage(
                                taskId: entry.key,
                                databaseMethods: widget.databaseMethods,
                              ),
                            )
                          : MaterialPageRoute(
                              builder: (context) => TaskPageStudent(
                                taskId: entry.key,
                                studentId: widget.currentUserUid,
                                databaseMethods: widget.databaseMethods,
                              ),
                            ),
                    );
                  },
                ))
            .toList(),
        if (tasks.isEmpty)
          const ListTile(title: Center(child: Text('Brak zadań'))),
        if (tasks.length > 3)
          TextButton(
            onPressed: () => setState(() => showAllTasks = !showAllTasks),
            child: Text(showAllTasks ? 'Pokaż mniej' : 'Pokaż więcej'),
          ),
        isTeacher
            ? ElevatedButton(
                onPressed: _showAddTaskDialog,
                child: const Text('Dodaj zadanie'),
              )
            : const SizedBox.shrink(),
      ],
    );
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    DateTime? selectedDateTime;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Nowe zadanie'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Tytuł'),
                    ),
                    TextField(
                      controller: contentController,
                      decoration: const InputDecoration(labelText: 'Treść'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedDateTime == null
                                ? 'Brak daty i godziny'
                                : 'Termin: ${selectedDateTime!.toLocal().toString().substring(0, 16)}',
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (time != null) {
                                final fullDateTime = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                                setState(() => selectedDateTime = fullDateTime);
                              }
                            }
                          },
                          child: const Text('Wybierz termin'),
                        ),
                      ],
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Anuluj'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    final content = contentController.text.trim();

                    if (title.isEmpty ||
                        content.isEmpty ||
                        selectedDateTime == null) {
                      setState(() {
                        errorMessage =
                            'Uzupełnij wszystkie pola (tytuł, treść, termin).';
                      });
                    } else {
                      setState(() {
                        errorMessage = null;
                      });

                      widget.databaseMethods
                          .addAssignment(
                            schoolId: widget.schoolId,
                            classId: widget.classId,
                            subjectId: widget.subjectId,
                            title: title,
                            content: content,
                            dueDate: selectedDateTime!,
                          )
                          .then(
                              (_) => _loadAssignments()); // Odświeżenie danych

                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Dodaj'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFilesSection(bool isTeacher) {
    return ExpansionTile(
      title: const Text('Pliki'),
      initiallyExpanded: true,
      children: [
        ...filesData.take(showAllFiles ? filesData.length : 3).map((fileData) {
          final name = fileData['name'] ?? 'Bez nazwy';
          final url = fileData['url'];
          return ListTile(
            title: Text(name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () => launchUrl(Uri.parse(url),
                      mode: LaunchMode.externalApplication),
                ),
                isTeacher
                    ? IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Usuń plik'),
                              content:
                                  Text('Czy na pewno chcesz usunąć "$name"?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Anuluj'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Usuń'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await _deleteFile(name, url);
                          }
                        },
                      )
                    : const SizedBox.shrink(),
              ],
            ),
          );
        }),
        if (filesData.isEmpty)
          const ListTile(title: Center(child: Text('Brak plików'))),
        if (filesData.length > 3)
          TextButton(
            onPressed: () => setState(() => showAllFiles = !showAllFiles),
            child: Text(showAllFiles ? 'Pokaż mniej' : 'Pokaż więcej'),
          ),
        isTeacher
            ? ElevatedButton(
                onPressed: _uploadFile, child: const Text('Dodaj plik'))
            : const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildTopicsSection(bool isTeacher) {
    return ExpansionTile(
      title: const Text('Tematy zajęć'),
      initiallyExpanded: true,
      children: [
        ...topics.entries.take(showAllTopics ? topics.length : 3).map(
              (entry) => ListTile(
                title: Text(entry.value['topic']),
                subtitle: entry.value['date'] != null
                    ? Text(
                        "Data: ${entry.value['date'].toDate().toLocal().toString().split(' ')[0]}")
                    : const Text("Brak daty"),
                trailing: isTeacher
                    ? IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _editLesson(entry.key, entry.value);
                        })
                    : null,
              ),
            ),
        if (topics.isEmpty)
          const ListTile(title: Center(child: Text('Brak tematów'))),
        if (topics.length > 3)
          TextButton(
            onPressed: () => setState(() => showAllTopics = !showAllTopics),
            child: Text(showAllTopics ? 'Pokaż mniej' : 'Pokaż więcej'),
          ),
        isTeacher
            ? ElevatedButton(
                onPressed: () {
                  _addLesson();
                },
                child: const Text('Dodaj temat'))
            : const SizedBox.shrink(),
      ],
    );
  }

  void _addLesson() {
    TextEditingController nameController = TextEditingController();
    TextEditingController dateController = TextEditingController();
    DateTime? selectedDate;
    String? errorText;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Dodaj nowy temat'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nazwa tematu',
                      errorText: errorText,
                    ),
                  ),
                  TextField(
                    controller: dateController,
                    decoration: const InputDecoration(labelText: 'Data zajęć'),
                    readOnly: true,
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          selectedDate = pickedDate;
                          dateController.text =
                              "${pickedDate.day}-${pickedDate.month}-${pickedDate.year}";
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Anuluj'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) {
                      setState(() {
                        errorText = "Nazwa tematu nie może być pusta!";
                      });
                      return;
                    }

                    widget.databaseMethods.addTopic(
                      widget.schoolId,
                      widget.classId,
                      widget.subjectId,
                      {
                        'topic': nameController.text.trim(),
                        'date': selectedDate != null
                            ? Timestamp.fromDate(selectedDate!)
                            : null,
                      },
                    ).then((_) => _loadTopics()); // Odświeżenie danych

                    Navigator.pop(context);
                  },
                  child: const Text('Dodaj'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editLesson(String lessonId, Map<String, dynamic> lessonData) {
    TextEditingController nameController =
        TextEditingController(text: lessonData['topic']);
    TextEditingController dateController = TextEditingController(
        text: lessonData['date'] != null
            ? "${lessonData['date'].toDate().day}-${lessonData['date'].toDate().month}-${lessonData['date'].toDate().year}"
            : '');
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edytuj lekcję'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nazwa tematu'),
              ),
              TextField(
                controller: dateController,
                decoration: const InputDecoration(labelText: 'Data zajęć'),
                readOnly: true,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    selectedDate = pickedDate;
                    dateController.text =
                        "${pickedDate.day}-${pickedDate.month}-${pickedDate.year}";
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anuluj'),
            ),
            ElevatedButton(
              onPressed: () {
                widget.databaseMethods.updateTopic(
                  widget.schoolId,
                  widget.classId,
                  widget.subjectId,
                  lessonId,
                  {
                    'topic': nameController.text,
                    'date': selectedDate != null
                        ? Timestamp.fromDate(selectedDate!)
                        : null,
                  },
                ).then((_) => _loadTopics()); // Odświeżenie danych
                Navigator.pop(context);
              },
              child: const Text('Zapisz'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildManagementButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TeacherGradesPage(
                  schoolId: widget.schoolId,
                  classId: widget.classId,
                  subjectId: widget.subjectId,
                  subjectName: className,
                  year: year,
                  databaseMethods: widget.databaseMethods,
                ),
              ),
            );
          },
          child: const Text('Zarządzaj ocenami'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TeacherAttendancePage(
                  schoolId: widget.schoolId,
                  classId: widget.classId,
                  subjectId: widget.subjectId,
                  subjectName: className,
                  databaseMethods: widget.databaseMethods,
                ),
              ),
            );
          },
          child: const Text('Zarządzaj frekwencją'),
        ),
      ],
    );
  }
}
