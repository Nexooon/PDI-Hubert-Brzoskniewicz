import 'package:flutter/material.dart';
import 'package:pdi_main_project/service/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TodayLessonsWidget extends StatefulWidget {
  final String schoolId;
  final String studentId;
  final DatabaseMethods databaseMethods;

  const TodayLessonsWidget({
    super.key,
    required this.schoolId,
    required this.studentId,
    required this.databaseMethods,
  });

  @override
  State<TodayLessonsWidget> createState() => _TodayLessonsWidgetState();
}

class _TodayLessonsWidgetState extends State<TodayLessonsWidget> {
  Map<String, dynamic> lessonTimes = {};
  List<Map<String, dynamic>> todayLessons = [];
  String? classId;
  String? currentYear;
  bool isLoading = true;

  final daysOfWeek = ['Poniedziałek', 'Wtorek', 'Środa', 'Czwartek', 'Piątek'];

  @override
  void initState() {
    super.initState();
    loadTodayTimetable();
    _loadCurrentYear();
  }

  void _loadCurrentYear() async {
    final year = await widget.databaseMethods.getCurrentYear(widget.schoolId);
    setState(() {
      currentYear = year;
    });
  }

  Future<void> loadTodayTimetable() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // classId ucznia
      classId = await widget.databaseMethods.getStudentClass(widget.studentId);
      if (classId == null) throw Exception("Brak klasy dla ucznia");

      // godziny lekcji
      final lessonTimesDoc = await firestore
          .collection('schools')
          .doc(widget.schoolId)
          .collection('settings')
          .doc('lessonTimes')
          .get();
      lessonTimes = lessonTimesDoc.data() ?? {};

      // wszystkie przedmioty
      final subjectsSnapshot = await firestore
          .collection('schools')
          .doc(widget.schoolId)
          .collection('classes')
          .doc(classId)
          .collection('subjects')
          .where('year', isEqualTo: currentYear)
          .get();

      final todayIndex = DateTime.now().weekday - 1;
      if (todayIndex < 0 || todayIndex > 4) {
        todayLessons = []; // Weekend
        return;
      }
      final todayName = daysOfWeek[todayIndex];
      // final todayName = "Poniedziałek";

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
            .where('day', isEqualTo: todayName)
            .get();

        for (final doc in timetableSnapshot.docs) {
          final data = doc.data();
          final lessonNum = data['lesson_number'];
          final room = data['room'] ?? '';
          final lessonTime = lessonTimes[lessonNum.toString()] ?? {};
          final start = lessonTime['start'] ?? '';
          final end = lessonTime['end'] ?? '';

          todayLessons.add({
            'lesson_number': lessonNum,
            'subject': subjectName,
            'room': room,
            'start': start,
            'end': end,
          });
        }
      }

      todayLessons.sort((a, b) => int.parse(a['lesson_number'].toString())
          .compareTo(int.parse(b['lesson_number'].toString())));
    } catch (e) {
      print("Błąd ładowania planu: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (todayLessons.isEmpty) {
      return const Card(
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text("Dziś nie ma lekcji."),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dzisiejszy plan lekcji',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Column(
              children: todayLessons.map((lesson) {
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(lesson['lesson_number'].toString()),
                  ),
                  title: Text(lesson['subject']),
                  subtitle: Text(
                      '${lesson['start']} - ${lesson['end']} • Sala: ${lesson['room']}'),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
