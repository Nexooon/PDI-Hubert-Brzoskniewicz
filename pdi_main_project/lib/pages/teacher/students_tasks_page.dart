import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdi_main_project/pages/teacher/task_page.dart';
import 'package:pdi_main_project/service/database.dart';

class StudentsTasksPage extends StatefulWidget {
  final String taskId;
  final DatabaseMethods databaseMethods;

  const StudentsTasksPage({
    super.key,
    required this.taskId,
    required this.databaseMethods,
  });

  @override
  State<StudentsTasksPage> createState() => _StudentsTasksPageState();
}

class _StudentsTasksPageState extends State<StudentsTasksPage> {
  late Future<Map<String, dynamic>> _taskFuture;
  String _sortBy = 'name';

  Future<Map<String, dynamic>> _loadTaskWithStudents() async {
    final title = await widget.databaseMethods.getTaskTitle(widget.taskId);
    final dueDate = await widget.databaseMethods.getTaskDueDate(widget.taskId);
    final students = await widget.databaseMethods
        .getStudentsWithTaskStatus(widget.taskId, sortBy: _sortBy);
    return {
      'title': title,
      'due_date': dueDate,
      'students': students,
    };
  }

  @override
  void initState() {
    super.initState();
    _taskFuture = _loadTaskWithStudents();
  }

  void _refresh() {
    setState(() {
      _taskFuture = _loadTaskWithStudents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zadania do oceny')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _taskFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.hasError) {
            return const Center(child: Text('Błąd wczytywania danych'));
          }

          final title = snapshot.data!['title'] as String;
          final dueDate = snapshot.data!['due_date'];
          final students =
              snapshot.data!['students'] as List<Map<String, dynamic>>;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Termin na wykonanie: ${dueDate != null ? DateFormat('dd.MM.yyyy HH:mm').format(dueDate.toDate()) : 'Brak terminu'}',
                  style: Theme.of(context).textTheme.titleMedium,
                  // textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: DropdownButton<String>(
                  value: _sortBy,
                  items: const [
                    DropdownMenuItem(
                        value: 'name', child: Text('Sortuj wg nazwiska')),
                    DropdownMenuItem(
                        value: 'status', child: Text('Sortuj wg statusu')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _sortBy = value;
                        _taskFuture = _loadTaskWithStudents();
                      });
                    }
                  },
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final name =
                        '${student['firstName']} ${student['lastName']}';
                    final status = student['status'] as String;

                    Color? tileColor;
                    Color? textColor;

                    switch (status) {
                      case 'ocenione':
                        tileColor = Colors.green[50];
                        textColor = Colors.green[800];
                        break;
                      case 'przesłane':
                        tileColor = Colors.blue[50];
                        textColor = Colors.blue[800];
                        break;
                      case 'nieprzesłane':
                        tileColor = Colors.grey[200];
                        textColor = Colors.grey[600];
                        break;
                    }

                    return ListTile(
                      tileColor: tileColor,
                      title: Text(name),
                      subtitle: Text(
                        'Status: $status',
                        style: TextStyle(color: textColor),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TaskPage(
                              taskId: widget.taskId,
                              studentIds: students
                                  .map((e) => e['studentId'] as String)
                                  .toList(),
                              currentIndex: index,
                              databaseMethods: widget.databaseMethods,
                            ),
                          ),
                        );
                        _refresh();
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
