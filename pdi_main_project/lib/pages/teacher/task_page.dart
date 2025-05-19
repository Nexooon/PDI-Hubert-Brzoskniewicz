import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdi_main_project/service/database.dart';
import 'package:url_launcher/url_launcher.dart';

class TaskPage extends StatefulWidget {
  final String taskId;
  final List<String> studentIds;
  final int currentIndex;
  final DatabaseMethods databaseMethods;

  const TaskPage({
    super.key,
    required this.taskId,
    required this.studentIds,
    required this.currentIndex,
    required this.databaseMethods,
  });

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  Map<String, dynamic>? submissionData;
  Map<String, dynamic>? userData;
  Map<String, dynamic>? taskData;

  String get studentId => widget.studentIds[widget.currentIndex];

  final _commentController = TextEditingController();
  String? _selectedGrade;

  final List<String> _grades = [
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
    '6'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final submission = await widget.databaseMethods.getSubmission(
      widget.taskId,
      studentId,
    );
    final user = await widget.databaseMethods.getUser(studentId);
    final task = await widget.databaseMethods.getTask(widget.taskId);

    setState(() {
      submissionData = submission;
      userData = user;
      taskData = task;

      _selectedGrade = submission['grade'];
      _commentController.text = submission['comment'] ?? '';
    });
  }

  Future<void> _saveGradeAndComment() async {
    await widget.databaseMethods.updateSubmission(
      taskId: widget.taskId,
      studentId: studentId,
      grade: _selectedGrade ?? '',
      comment: _commentController.text,
    );
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Zapisano ocenę i komentarz')),
    );
  }

  Widget _buildFileSection() {
    final fileUrl = submissionData?['url'];
    final submittedAt = submissionData?['submitted_at'];
    final dueDate = taskData?['due_date'];

    if (fileUrl == null || fileUrl.isEmpty) {
      return const Text('Brak załączonego pliku.');
    }

    Widget? submissionInfoWidget;
    if (submittedAt != null) {
      final submittedDate = (submittedAt as Timestamp).toDate();
      final submissionText =
          'Wysłano: ${DateFormat('dd.MM.yyyy HH:mm').format(submittedDate)}';

      bool isLate = false;
      if (dueDate != null && dueDate is Timestamp) {
        final deadline = dueDate.toDate();
        isLate = submittedDate.isAfter(deadline);
      }

      submissionInfoWidget = RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.grey),
          children: [
            TextSpan(text: submissionText),
            if (isLate)
              const TextSpan(
                text: ' (po terminie)',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: () => launchUrl(
            Uri.parse(fileUrl),
            mode: LaunchMode.externalApplication,
          ),
          icon: const Icon(Icons.download),
          label: const Text('Pobierz rozwiązanie'),
        ),
        if (submissionInfoWidget != null) submissionInfoWidget,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (submissionData == null || userData == null || taskData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final status = submissionData!['status'] ?? 'nieprzesłane';
    final isGraded = (submissionData!['grade'] ?? '').toString().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zadanie ucznia'),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: widget.currentIndex > 0
                ? () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskPage(
                          taskId: widget.taskId,
                          studentIds: widget.studentIds,
                          currentIndex: widget.currentIndex - 1,
                          databaseMethods: widget.databaseMethods,
                        ),
                      ),
                    );
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: widget.currentIndex < widget.studentIds.length - 1
                ? () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskPage(
                          taskId: widget.taskId,
                          studentIds: widget.studentIds,
                          currentIndex: widget.currentIndex + 1,
                          databaseMethods: widget.databaseMethods,
                        ),
                      ),
                    );
                  }
                : null,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Center(
                child: Text(
                  'Zadanie: ${taskData!['title'] ?? 'Brak tytułu'}',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Uczeń: ${userData!['name']} ${userData!['surname']}',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Termin na wykonanie: ${taskData!['due_date'] != null ? DateFormat('dd.MM.yyyy HH:mm').format((taskData!['due_date'] as Timestamp).toDate()) : 'Brak terminu'}',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.lightBlue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Treść zadania:',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(taskData!['content'] ?? 'Brak treści'),
                    const SizedBox(
                      width: 280,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildFileSection(),
              const SizedBox(height: 16),
              Text('Status: $status'),
              Text('Ocenione: ${isGraded ? 'Tak' : 'Nie'}'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedGrade,
                      decoration: const InputDecoration(labelText: 'Ocena'),
                      items: _grades
                          .map((grade) => DropdownMenuItem(
                                value: grade,
                                child: Text(grade),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedGrade = val),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        labelText: 'Komentarz',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _saveGradeAndComment,
                      icon: const Icon(Icons.save),
                      label: const Text('Zapisz ocenę i komentarz'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
