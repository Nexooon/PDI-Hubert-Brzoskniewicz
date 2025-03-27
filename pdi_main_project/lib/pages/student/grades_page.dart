import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdi_main_project/service/database.dart';

class GradesPage extends StatefulWidget {
  final String currentUserUid;
  final DatabaseMethods databaseMethods;

  const GradesPage(
      {super.key, required this.currentUserUid, required this.databaseMethods});

  @override
  State<GradesPage> createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {
  late Future<List<Map<String, dynamic>>> _gradesFuture;

  @override
  void initState() {
    super.initState();
    _gradesFuture =
        widget.databaseMethods.getStudentGrades(widget.currentUserUid);
  }

  String convertDateTime(DateTime dateTime) {
    var date = dateTime;
    String minute = date.minute.toString();
    if (date.minute < 10) {
      minute = '0${date.minute}';
    }
    return '${date.day}.${date.month}.${date.year} ${date.hour}:$minute';
  }

  void _showGradeDetails(
      BuildContext context, String grade, String description, DateTime date) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Szczegóły oceny'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Ocena: $grade'),
              const SizedBox(height: 10),
              Text('Opis: $description'),
              const SizedBox(height: 10),
              Text('Data: ${convertDateTime(date.toLocal())}'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Zamknij'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Przekształcenie danych z Firestore do struktury używanej w UI
  Map<String, List<Map<String, dynamic>>> _organizeGrades(
      List<Map<String, dynamic>> snapshot) {
    Map<String, List<Map<String, dynamic>>> organized = {};

    for (var doc in snapshot) {
      var data = doc;
      String schoolYear = data['school_year'] ?? 'Nieznany rok';
      String subject = data['subject_name'];
      String gradeValue = data['grade_value'] ?? 'Brak oceny';
      String description = data['description'] ?? '';
      Timestamp timestamp = data['date'] ?? Timestamp.now();
      bool isFinal = data['is_final'] ?? false;

      if (!organized.containsKey(schoolYear)) {
        organized[schoolYear] = [];
      }

      // Znajdź przedmiot w zorganizowanych danych lub dodaj nowy
      var subjectList = organized[schoolYear]!;
      var subjectEntry = subjectList.firstWhere(
        (entry) => entry['subject'] == subject,
        orElse: () => {
          'subject': subject,
          'partialGrades': [],
          'finalGrade': null,
        },
      );

      if (!subjectList.contains(subjectEntry)) {
        subjectList.add(subjectEntry);
      }

      if (isFinal) {
        subjectEntry['finalGrade'] = {
          'grade': gradeValue,
          'description': description,
          'date': timestamp.toDate(),
        };
      } else {
        subjectEntry['partialGrades'].add({
          'grade': gradeValue,
          'description': description,
          'date': timestamp.toDate(),
        });
      }
    }

    organized.forEach((year, subjects) {
      for (var subject in subjects) {
        if (subject['finalGrade'] == null) {
          subject['finalGrade'] = {
            'grade': "-",
            'description': 'Nie wystawiono',
            'date': Timestamp.now().toDate(),
          };
        }
      }
    });

    return organized;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _gradesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Oceny Ucznia'),
              backgroundColor: Colors.blue,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Oceny Ucznia'),
              backgroundColor: Colors.blue,
            ),
            body: const Center(
                child: Text('Wystąpił błąd podczas ładowania ocen.')),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Oceny Ucznia'),
              backgroundColor: Colors.blue,
            ),
            body: const Center(child: Text('Brak ocen do wyświetlenia.')),
          );
        }

        Map<String, List<Map<String, dynamic>>> schoolYears =
            _organizeGrades(snapshot.data!);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Oceny Ucznia'),
            backgroundColor: Colors.blue,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: schoolYears.keys.map((year) {
                return ExpansionTile(
                  title: Text(
                    year,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  initiallyExpanded: year == schoolYears.keys.first,
                  children: schoolYears[year]!.map((subjectData) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subjectData['subject'],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Oceny cząstkowe:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 5),
                            Wrap(
                              spacing: 5.0,
                              runSpacing: 5.0,
                              children: subjectData['partialGrades']
                                  .map<Widget>((gradeData) {
                                return GestureDetector(
                                  onTap: () => _showGradeDetails(
                                    context,
                                    gradeData['grade'],
                                    gradeData['description'],
                                    gradeData['date'],
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 5),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      gradeData['grade'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Ocena końcowa:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _showGradeDetails(
                                context,
                                subjectData['finalGrade']['grade'],
                                subjectData['finalGrade']['description'],
                                subjectData['finalGrade']['date'],
                              ),
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 5),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.green[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  subjectData['finalGrade']['grade'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
