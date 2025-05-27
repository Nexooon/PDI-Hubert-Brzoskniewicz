import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdi_main_project/service/database.dart';

class AttendancePage extends StatefulWidget {
  final String currentUserUid;
  final String userRole;
  final DatabaseMethods databaseMethods;

  const AttendancePage(
      {super.key,
      required this.currentUserUid,
      required this.userRole,
      required this.databaseMethods});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  Future<Map<String, dynamic>> _loadAttendance() async {
    try {
      return await widget.databaseMethods
          .getStudentAttendance(widget.currentUserUid);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  void _showExcuseDialog(BuildContext context) {
    final reasonController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Usprawiedliwienie nieobecności'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setState(() => selectedDate = pickedDate);
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(selectedDate == null
                        ? 'Wybierz datę'
                        : "${selectedDate!.day}.${selectedDate!.month}.${selectedDate!.year}"),
                  ),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(labelText: 'Powód'),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Anuluj'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedDate != null &&
                        reasonController.text.trim().isNotEmpty) {
                      await widget.databaseMethods.addExcuse({
                        'student_id': widget.currentUserUid,
                        'date': Timestamp.fromDate(selectedDate!),
                        'reason': reasonController.text.trim(),
                        'approved': false,
                      });

                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Usprawiedliwienie wysłane')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Uzupełnij wszystkie pola')),
                      );
                    }
                  },
                  child: const Text('Wyślij'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Frekencja")),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadAttendance(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("Błąd: podczas ładowania danych"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Brak danych o frekwencji"));
          } else if (snapshot.data!.containsKey("error")) {
            return Center(child: Text("Błąd: ${snapshot.data!['error']}"));
          }

          final attendanceData = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(8.0),
            children: [
              if (attendanceData['Spóźniony'].isNotEmpty)
                AttendanceSection(
                    title: "Spóźnienia", data: attendanceData['Spóźniony']),
              if (attendanceData['Nieobecny'].isNotEmpty)
                AttendanceSection(
                    title: "Nieobecności", data: attendanceData['Nieobecny']),
            ],
          );
        },
      ),
      floatingActionButton: widget.userRole == 'parent'
          ? FloatingActionButton(
              onPressed: () => _showExcuseDialog(context),
              tooltip: 'Wyślij usprawiedliwienie',
              child: const Icon(Icons.note_add),
            )
          : null,
    );
  }
}

class AttendanceSection extends StatelessWidget {
  final String title;
  final Map<dynamic, dynamic> data;

  const AttendanceSection({super.key, required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const Text("Usprawiedliwione",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
            const Divider(),
            ...data.entries
                .map((entry) =>
                    AttendanceDateGroup(date: entry.key, subjects: entry.value))
                .toList(),
          ],
        ),
      ),
    );
  }
}

class AttendanceDateGroup extends StatelessWidget {
  final Timestamp date;
  final Map<dynamic, dynamic> subjects;

  const AttendanceDateGroup(
      {super.key, required this.date, required this.subjects});

  @override
  Widget build(BuildContext context) {
    String formattedDate =
        "${date.toDate().day}.${date.toDate().month}.${date.toDate().year}";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(formattedDate,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ...subjects.entries.map((subjectEntry) {
          final subject = subjectEntry.key;
          final lessons = subjectEntry.value as List;
          return Column(
            children: lessons.map((lesson) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("$subject", style: const TextStyle(fontSize: 14)),
                  Icon(
                    lesson['justified'] ? Icons.check_circle : Icons.cancel,
                    color: lesson['justified'] ? Colors.green : Colors.red,
                  ),
                ],
              );
            }).toList(),
          );
        }).toList(),
        const SizedBox(height: 8),
      ],
    );
  }
}
