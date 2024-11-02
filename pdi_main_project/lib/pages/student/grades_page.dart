import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdi_main_project/service/database.dart';

class GradesPage extends StatefulWidget {
  final DocumentSnapshot currentUser;
  const GradesPage({super.key, required this.currentUser});

  @override
  State<GradesPage> createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {
//   Future<QuerySnapshot<Map<String, dynamic>>> getStudentGrades() async {
//     return await DatabaseMethods().getStudentGrades();
//   }

  // Przykładowe dane dotyczące lat szkolnych, przedmiotów i ocen
  final Map<String, List<Map<String, dynamic>>> schoolYears = {
    '2023/2024': [
      {
        'subject': 'Matematyka',
        'partialGrades': ['5', '4+', '3', '3-', '2+', '5', '4'],
        'finalGrade': '4+',
      },
      {
        'subject': 'Język Polski',
        'partialGrades': ['4', '5', '4'],
        'finalGrade': '4',
      },
    ],
    '2022/2023': [
      {
        'subject': 'Fizyka',
        'partialGrades': ['3+', '4', '4-'],
        'finalGrade': '4',
      },
      {
        'subject': 'Historia',
        'partialGrades': ['5', '4', '5'],
        'finalGrade': '5',
      },
    ],
  };

  // Funkcja wyświetlająca szczegóły oceny po kliknięciu
  void _showGradeDetails(BuildContext context, String grade) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Szczegóły oceny'),
          content: Text('Ocena: $grade\nWięcej informacji o tej ocenie...'),
          actions: <Widget>[
            TextButton(
              child: Text('Zamknij'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Oceny Ucznia'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: schoolYears.keys.map((year) {
            return ExpansionTile(
              title: Text(
                year,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Wrap(
                          spacing: 5.0,
                          runSpacing: 5.0,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 9.0),
                              child: Text(
                                'Oceny cząstkowe: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            ...subjectData['partialGrades']
                                .map<Widget>((grade) {
                              return GestureDetector(
                                onTap: () => _showGradeDetails(context, grade),
                                child: Container(
                                  margin: EdgeInsets.symmetric(horizontal: 5),
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    grade,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Ocena końcowa: ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showGradeDetails(
                            context,
                            subjectData['finalGrade'],
                          ),
                          child: Container(
                            margin: EdgeInsets.symmetric(vertical: 5),
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              subjectData['finalGrade'],
                              style: TextStyle(
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
  }
}
