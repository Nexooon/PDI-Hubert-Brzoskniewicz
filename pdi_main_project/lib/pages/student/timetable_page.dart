import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdi_main_project/service/database.dart';

class TimetablePage extends StatefulWidget {
  final String schoolId;
  final String studentId;
  final DatabaseMethods databaseMethods;

  const TimetablePage({
    super.key,
    required this.schoolId,
    required this.studentId,
    required this.databaseMethods,
  });

  @override
  State<TimetablePage> createState() => _StudentTimetablePageState();
}

class _StudentTimetablePageState extends State<TimetablePage> {
  Map<String, dynamic> lessonTimes = {};
  Map<String, List<Map<String, dynamic>>> timetableByDay = {};
  String? classId;
  String? currentYear;
  bool isLoading = true;

  final daysOfWeek = ['Poniedziałek', 'Wtorek', 'Środa', 'Czwartek', 'Piątek'];

  @override
  void initState() {
    super.initState();
    loadAllData();
  }

  Future<void> loadAllData() async {
    try {
      classId = await widget.databaseMethods.getStudentClass(widget.studentId);

      if (classId == null) {
        throw Exception('Nie znaleziono klasy dla ucznia.');
      }

      _loadCurrentYear();
      await loadTimetable();
    } catch (e) {
      print('Błąd podczas ładowania danych: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _loadCurrentYear() async {
    final year = await widget.databaseMethods.getCurrentYear(widget.schoolId);
    setState(() {
      currentYear = year;
    });
  }

  Future<void> loadTimetable() async {
    final firestore = FirebaseFirestore.instance;

    timetableByDay.clear();

    // lessonTimes
    final lessonTimesDoc = await firestore
        .collection('schools')
        .doc(widget.schoolId)
        .collection('settings')
        .doc('lessonTimes')
        .get();
    lessonTimes = lessonTimesDoc.data() ?? {};

    // przedmioty danej klasy
    final subjectsSnapshot = await firestore
        .collection('schools')
        .doc(widget.schoolId)
        .collection('classes')
        .doc(classId)
        .collection('subjects')
        .where('year', isEqualTo: currentYear)
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

        final lessonTime = lessonTimes[lessonNum] ?? {};
        final start = lessonTime['start'] ?? '';
        final end = lessonTime['end'] ?? '';

        timetableByDay.putIfAbsent(day, () => []).add({
          'lesson_number': lessonNum,
          'subject': subjectName,
          'room': room,
          'start': start,
          'end': end,
        });
      }
    }

    // sortowanie wg numeru lekcji
    for (final day in timetableByDay.keys) {
      timetableByDay[day]!.sort((a, b) => int.parse(a['lesson_number'])
          .compareTo(int.parse(b['lesson_number'])));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // wszystkie numery lekcji
    final allLessonNumbers = timetableByDay.values
        .expand((lessons) => lessons)
        .map((e) => int.tryParse(e['lesson_number'].toString()) ?? 0)
        .toSet()
        .toList()
      ..sort();

    // mapa lesson_number -> day -> lekcja
    final timetableMatrix = <int, Map<String, Map<String, dynamic>>>{};
    for (final day in daysOfWeek) {
      final lessons = timetableByDay[day] ?? [];
      for (final lesson in lessons) {
        final lessonNumber = int.tryParse(lesson['lesson_number'].toString());
        if (lessonNumber == null) continue;
        timetableMatrix.putIfAbsent(lessonNumber, () => {})[day] = lesson;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Plan zajęć')),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              const DataColumn(label: Text('Lekcja')),
              ...daysOfWeek.map((day) => DataColumn(label: Text(day))),
            ],
            rows: allLessonNumbers.map((lessonNumber) {
              final lessonTime = lessonTimes[lessonNumber.toString()] ?? {};
              final timeRange =
                  '${lessonTime['start'] ?? '-'} - ${lessonTime['end'] ?? '-'}';

              return DataRow(cells: [
                DataCell(Text('Lekcja $lessonNumber\n$timeRange')),
                ...daysOfWeek.map((day) {
                  final lesson = timetableMatrix[lessonNumber]?[day];
                  if (lesson != null) {
                    return DataCell(Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(lesson['subject'] ?? '',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Sala: ${lesson['room'] ?? '-'}'),
                      ],
                    ));
                  } else {
                    return const DataCell(Text('-'));
                  }
                }).toList(),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}
