import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdi_main_project/service/database.dart';

class TeacherTimetablePage extends StatefulWidget {
  final String schoolId;
  final String teacherId;
  final DatabaseMethods databaseMethods;

  const TeacherTimetablePage({
    super.key,
    required this.schoolId,
    required this.teacherId,
    required this.databaseMethods,
  });

  @override
  State<TeacherTimetablePage> createState() => _TeacherTimetablePageState();
}

class _TeacherTimetablePageState extends State<TeacherTimetablePage> {
  Map<String, dynamic> lessonTimes = {};
  Map<String, Map<String, Map<String, dynamic>>> timetableMatrix =
      {}; // day -> lesson_number -> data
  bool isLoading = true;

  final daysOfWeek = ['Poniedziałek', 'Wtorek', 'Środa', 'Czwartek', 'Piątek'];

  @override
  void initState() {
    super.initState();
    loadAllData();
  }

  Future<void> loadAllData() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // lessonTimes
      final lessonTimesDoc = await firestore
          .collection('schools')
          .doc(widget.schoolId)
          .collection('settings')
          .doc('lessonTimes')
          .get();
      lessonTimes = lessonTimesDoc.data() ?? {};

      // Inicjalizacja macierzy
      for (final day in daysOfWeek) {
        timetableMatrix[day] = {};
      }

      // klasy, w których nauczyciel prowadzi zajęcia
      final classesSnapshot = await firestore
          .collection('schools')
          .doc(widget.schoolId)
          .collection('classes')
          .get();

      for (final classDoc in classesSnapshot.docs) {
        final classId = classDoc.id;
        final className = classDoc.data()['name'] ?? classId;

        final subjectsSnapshot = await firestore
            .collection('schools')
            .doc(widget.schoolId)
            .collection('classes')
            .doc(classId)
            .collection('subjects')
            .where('employee',
                isEqualTo: firestore.collection('users').doc(widget.teacherId))
            .get();

        for (final subjectDoc in subjectsSnapshot.docs) {
          final subjectId = subjectDoc.id;
          final subjectName = subjectDoc.data()['name'] ?? 'Przedmiot';

          final timetableSnapshot = await firestore
              .collection('schools')
              .doc(widget.schoolId)
              .collection('classes')
              .doc(classId)
              .collection('subjects')
              .doc(subjectId)
              .collection('timetable')
              .get();

          for (final doc in timetableSnapshot.docs) {
            final data = doc.data();
            final day = data['day'] ?? '';
            final lessonNum = data['lesson_number'];
            final room = data['room'] ?? '';

            if (!daysOfWeek.contains(day)) continue;

            timetableMatrix[day]![lessonNum] = {
              'subject': subjectName,
              'room': room,
              'className': className,
            };
          }
        }
      }
    } catch (e) {
      print('Błąd podczas ładowania planu nauczyciela: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // sortowanie numerów lekcji
    final lessonNumbers = lessonTimes.keys.toList()
      ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

    return Scaffold(
      appBar: AppBar(title: const Text('Plan nauczyciela')),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          headingRowColor:
              WidgetStateProperty.all(Theme.of(context).primaryColorLight),
          columns: [
            const DataColumn(label: Text('Godzina')),
            ...daysOfWeek.map((day) => DataColumn(label: Text(day))),
          ],
          rows: lessonNumbers.map((lessonNum) {
            final time = lessonTimes[lessonNum];
            final timeLabel = '${time['start']} - ${time['end']}';

            return DataRow(cells: [
              DataCell(Text('Lekcja $lessonNum\n$timeLabel')),
              ...daysOfWeek.map((day) {
                final entry = timetableMatrix[day]![lessonNum];
                if (entry == null) return const DataCell(Text(''));
                return DataCell(Text(
                    '${entry['subject']}\n${entry['room']}, kl. ${entry['className']}'));
              }),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
