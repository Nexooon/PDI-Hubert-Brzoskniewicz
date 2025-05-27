import 'package:flutter/material.dart';
import 'package:pdi_main_project/service/database.dart';

class SubjectTimetablePage extends StatefulWidget {
  final DatabaseMethods databaseMethods;
  final String schoolId;
  final String classId;
  final String subjectId;
  final String subjectName;

  const SubjectTimetablePage({
    super.key,
    required this.databaseMethods,
    required this.schoolId,
    required this.classId,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<SubjectTimetablePage> createState() => _SubjectTimetablePageState();
}

class _SubjectTimetablePageState extends State<SubjectTimetablePage> {
  late Future<List<Map<String, dynamic>>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  void _loadEntries() {
    setState(() {
      _entriesFuture = widget.databaseMethods.getTimetableEntries(
        widget.schoolId,
        widget.classId,
        widget.subjectId,
      );
    });
  }

  void _showAddEntryDialog() {
    final lessonNumberController = TextEditingController();
    final roomController = TextEditingController();
    String? selectedDay;

    final List<String> daysOfWeek = [
      'Poniedziałek',
      'Wtorek',
      'Środa',
      'Czwartek',
      'Piątek',
    ];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Dodaj wpis do planu'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Dzień tygodnia'),
                value: selectedDay,
                items: daysOfWeek.map((day) {
                  return DropdownMenuItem(
                    value: day,
                    child: Text(day),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedDay = value;
                },
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Numer lekcji'),
                items: List.generate(9, (index) => (index + 1).toString())
                    .map((number) {
                  return DropdownMenuItem(
                    value: number,
                    child: Text('Lekcja $number'),
                  );
                }).toList(),
                onChanged: (value) {
                  lessonNumberController.text = value ?? '';
                },
              ),
              TextField(
                controller: roomController,
                decoration: const InputDecoration(labelText: 'Sala'),
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
              final lessonNumber = lessonNumberController.text.trim();
              final room = roomController.text.trim();

              if (selectedDay != null &&
                  lessonNumber.isNotEmpty &&
                  room.isNotEmpty) {
                await widget.databaseMethods.addTimetableEntry(
                  widget.schoolId,
                  widget.classId,
                  widget.subjectId,
                  selectedDay!,
                  lessonNumber,
                  room,
                );
                Navigator.pop(context);
                _loadEntries();
              }
            },
            child: const Text('Dodaj'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteEntry(String entryId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Usuń wpis'),
        content: const Text('Czy na pewno chcesz usunąć ten wpis z planu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () async {
              await widget.databaseMethods.deleteTimetableEntry(
                widget.schoolId,
                widget.classId,
                widget.subjectId,
                entryId,
              );
              Navigator.pop(context);
              _loadEntries();
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
      appBar: AppBar(title: Text('Plan zajęć: ${widget.subjectName}')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _entriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Błąd: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Brak wpisów w planie'));
          }

          final entries = snapshot.data!;
          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return ListTile(
                title: Text(
                    '${entry['day']}, lekcja nr ${entry['lesson_number']}'),
                subtitle: Text('Sala: ${entry['room']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _confirmDeleteEntry(entry['id']),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEntryDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
