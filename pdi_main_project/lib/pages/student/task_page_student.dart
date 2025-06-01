import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdi_main_project/service/database.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;

class TaskPageStudent extends StatefulWidget {
  final String taskId;
  final String studentId;
  final DatabaseMethods databaseMethods;

  const TaskPageStudent({
    super.key,
    required this.taskId,
    required this.studentId,
    required this.databaseMethods,
  });

  @override
  State<TaskPageStudent> createState() => _TaskPageStudentState();
}

class _TaskPageStudentState extends State<TaskPageStudent> {
  Map<String, dynamic>? submissionData;
  Map<String, dynamic>? taskData;
  PlatformFile? selectedFile;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final submission = await widget.databaseMethods.getSubmission(
      widget.taskId,
      widget.studentId,
    );
    final task = await widget.databaseMethods.getTask(widget.taskId);

    setState(() {
      submissionData = submission;
      taskData = task;
    });
  }

  Future<void> _submitSelectedFile() async {
    if (selectedFile == null) return;

    final fileName = selectedFile!.name;
    try {
      final oldFileName = submissionData?['file_name'];
      if (oldFileName != null && oldFileName is String) {
        final oldRef = FirebaseStorage.instance.ref().child(
              'assignments/${widget.taskId}/submissions/${widget.studentId}/$oldFileName',
            );
        await oldRef.delete().catchError((e) {
          print('Nie udało się usunąć starego pliku: $e');
        });
      }

      final storageRef = FirebaseStorage.instance.ref().child(
          'assignments/${widget.taskId}/submissions/${widget.studentId}/$fileName');

      UploadTask uploadTask;

      if (kIsWeb) {
        final data = selectedFile!.bytes;
        if (data == null) return;
        uploadTask = storageRef.putData(data);
      } else {
        final path = selectedFile!.path;
        if (path == null) return;
        final file = io.File(path);
        uploadTask = storageRef.putFile(file);
      }

      await uploadTask;
      final downloadUrl = await storageRef.getDownloadURL();
      final now = DateTime.now();

      await widget.databaseMethods.updateSubmissionStudent(
        taskId: widget.taskId,
        studentId: widget.studentId,
        submissionData: {
          'file_name': fileName,
          'url': downloadUrl,
          'status': 'przesłane',
          'submitted_at': now,
        },
      );

      setState(() {
        selectedFile = null;
      });

      _loadData();
    } catch (e) {
      print('Błąd przy przesyłaniu: $e');
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        selectedFile = result.files.single;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (submissionData == null || taskData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final status = submissionData!['status'] ?? 'nieprzesłane';
    final isGraded = (submissionData!['grade'] ?? '').toString().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zadanie ucznia'),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Padding(
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
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Termin na wykonanie: ${taskData!['due_date'] != null ? DateFormat('dd.MM.yyyy HH:mm').format(taskData!['due_date'].toDate()) : 'Brak terminu'}',
                      style: Theme.of(context).textTheme.titleLarge,
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
                          width: 330,
                        ),
                      ],
                    ),
                  ),
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
                        Text(
                          'Ocena:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          submissionData!['grade'] ?? 'Brak oceny',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Komentarz:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(submissionData!['comment'] ?? 'Brak komentarza',
                            style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(
                          width: 330,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (submissionData!['url'] != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Plik został przesłany:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${submissionData!['file_name'] ?? 'Brak nazwy'}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: _pickFile,
                              child: const Text('Zmień (wyślij ponownie)'),
                            ),
                          ],
                        ),
                        if (submissionData!['submitted_at'] != null)
                          Text(
                            'Wysłano: ${DateFormat('dd.MM.yyyy HH:mm').format((submissionData!['submitted_at'] as Timestamp).toDate())}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (selectedFile != null)
                        Row(
                          children: [
                            Expanded(
                                child: Text(
                                    'Wybrany plik: ${selectedFile!.name}')),
                            TextButton(
                              onPressed: _pickFile,
                              child: const Text('Zmień'),
                            ),
                          ],
                        )
                      else if (submissionData!['url'] == null)
                        ElevatedButton.icon(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.attach_file),
                          label: const Text('Wybierz plik'),
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed:
                            selectedFile != null ? _submitSelectedFile : null,
                        icon: const Icon(Icons.upload),
                        label: Text(submissionData!['url'] == null
                            ? 'Prześlij zadanie'
                            : 'Wyślij ponownie'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
