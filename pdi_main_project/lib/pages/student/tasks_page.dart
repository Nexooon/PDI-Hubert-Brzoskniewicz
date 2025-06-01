import 'package:flutter/material.dart';
import 'package:pdi_main_project/pages/student/task_page_student.dart';
import 'package:pdi_main_project/service/database.dart';

class TasksPage extends StatelessWidget {
  final String studentId;
  final DatabaseMethods databaseMethods;

  const TasksPage({
    super.key,
    required this.studentId,
    required this.databaseMethods,
  });

  void _navigateToTask(BuildContext context, String taskId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskPageStudent(
          taskId: taskId,
          studentId: studentId,
          databaseMethods: databaseMethods,
        ),
      ),
    );
  }

  Future<Map<String, List<Map<String, String>>>> _getStudentTasks() async {
    try {
      return await databaseMethods.getStudentTasks(studentId);
    } catch (e) {
      throw Exception('Błąd podczas ładowania zadań: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zadania'),
      ),
      body: FutureBuilder<Map<String, List<Map<String, String>>>>(
        future: _getStudentTasks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Błąd: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Brak zadań'));
          } else {
            Map<String, List<Map<String, String>>> allTasksData =
                snapshot.data!;

            // Filtrowanie przedmiotów z co najmniej jednym zadaniem
            Map<String, List<Map<String, String>>> filteredTasksData = {
              for (var entry in allTasksData.entries)
                if (entry.value.isNotEmpty) entry.key: entry.value,
            };

            if (filteredTasksData.isEmpty) {
              return const Center(child: Text('Brak zadań do wyświetlenia'));
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ListView.builder(
                  itemCount: filteredTasksData.length,
                  itemBuilder: (context, index) {
                    String subjectName =
                        filteredTasksData.keys.elementAt(index);
                    List<Map<String, String>> tasks =
                        filteredTasksData[subjectName]!;

                    return ExpansionTile(
                      title: Text(subjectName),
                      children: tasks.map((task) {
                        String taskId = task['task_id'] ?? '';
                        String taskTitle = task['title'] ?? '';
                        return ListTile(
                          title: Text(taskTitle),
                          onTap: () => _navigateToTask(context, taskId),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
