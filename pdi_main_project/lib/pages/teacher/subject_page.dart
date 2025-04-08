import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdi_main_project/pages/teacher/teacher_attendance_page.dart';
import 'package:pdi_main_project/pages/teacher/teacher_grades_page.dart';
// import 'package:pdi_main_project/pages/teacher/teacher_attendance_page.dart';
import 'package:pdi_main_project/service/database.dart';

class SubjectPage extends StatefulWidget {
  final String schoolId;
  final String classId;
  final String subjectId;
  final String className;
  final DatabaseMethods databaseMethods;

  const SubjectPage({
    super.key,
    required this.schoolId,
    required this.classId,
    required this.subjectId,
    required this.className,
    required this.databaseMethods,
  });

  @override
  State<SubjectPage> createState() => _SubjectPageState();
}

class _SubjectPageState extends State<SubjectPage> {
  bool showAllTasks = false;
  bool showAllFiles = false;
  bool showAllTopics = false;

  // final List<String> tasks = [
  //   'Zadanie 1',
  //   'Zadanie 2',
  //   'Zadanie 3',
  //   'Zadanie 4',
  //   'Zadanie 5'
  // ];

  List<String> tasks = [];

  Map<String, dynamic> topics = {};

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  void _loadTopics() {
    widget.databaseMethods
        .getLessonTopics(widget.schoolId, widget.classId, widget.subjectId)
        .then((value) => setState(() => topics = value));
  }

  final List<String> files = [
    'Plik1.pdf',
    'Plik2.pdf',
    'Plik3.pdf',
    'Plik4.pdf',
    'Plik5.pdf'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Strona przedmiotowa')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Klasa: ${widget.className}',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildManagementButtons(),
              const SizedBox(height: 10),
              _buildTasksSection(),
              _buildFilesSection(),
              _buildTopicsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTasksSection() {
    return ExpansionTile(
      title: const Text('Zadania'),
      initiallyExpanded: true,
      children: [
        ...tasks
            .take(showAllTasks ? tasks.length : 3)
            .map((task) => ListTile(title: Text(task)))
            .toList(),
        if (tasks.isEmpty)
          const ListTile(title: Center(child: Text('Brak zadań'))),
        if (tasks.length > 3)
          TextButton(
            onPressed: () => setState(() => showAllTasks = !showAllTasks),
            child: Text(showAllTasks ? 'Pokaż mniej' : 'Pokaż więcej'),
          ),
        ElevatedButton(onPressed: () {}, child: const Text('Dodaj zadanie')),
      ],
    );
  }

  Widget _buildFilesSection() {
    return ExpansionTile(
      title: const Text('Pliki'),
      initiallyExpanded: true,
      children: [
        ...files.take(showAllFiles ? files.length : 3).map((file) => ListTile(
            title: Text(file),
            trailing:
                IconButton(icon: const Icon(Icons.delete), onPressed: () {}))),
        if (files.isEmpty)
          const ListTile(title: Center(child: Text('Brak plików'))),
        if (files.length > 3)
          TextButton(
            onPressed: () => setState(() => showAllFiles = !showAllFiles),
            child: Text(showAllFiles ? 'Pokaż mniej' : 'Pokaż więcej'),
          ),
        ElevatedButton(onPressed: () {}, child: const Text('Dodaj plik')),
      ],
    );
  }

  Widget _buildTopicsSection() {
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
                  trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        _editLesson(entry.key, entry.value);
                      })),
            ),
        if (topics.isEmpty)
          const ListTile(title: Center(child: Text('Brak tematów'))),
        if (topics.length > 3)
          TextButton(
            onPressed: () => setState(() => showAllTopics = !showAllTopics),
            child: Text(showAllTopics ? 'Pokaż mniej' : 'Pokaż więcej'),
          ),
        ElevatedButton(
            onPressed: () {
              _addLesson();
            },
            child: const Text('Dodaj temat')),
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
                  subjectName: widget.className,
                  year: '', // Placeholder, dostosuj do modelu danych
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
                  subjectName: widget.className,
                  year: '', // Placeholder, dostosuj do modelu danych
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
