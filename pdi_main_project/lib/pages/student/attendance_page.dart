import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdi_main_project/service/database.dart';

class AttendancePage extends StatefulWidget {
  final String currentUserUid;
  final DatabaseMethods databaseMethods;

  const AttendancePage(
      {super.key, required this.currentUserUid, required this.databaseMethods});

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
    );
  }
}
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Frekencja")),
//       body: FutureBuilder<Map<String, dynamic>>(
//         future: _attendanceFuture,
//         builder: (context, snapshot) {
//           // Logowanie do debugowania
//           print(
//               "FutureBuilder snapshot: ${snapshot.connectionState}, error: ${snapshot.error}");

//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             return Center(child: Text("Błąd: ${snapshot.error}"));
//           } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return const Center(child: Text("Brak danych o frekwencji"));
//           }

//           final attendanceData = snapshot.data!;
//           print(attendanceData);
//           return ListView(
//             padding: const EdgeInsets.all(8.0),
//             children: [
//               if (attendanceData['Spóźniony'].isNotEmpty)
//                 AttendanceSection(
//                     title: "Spóźnienia", data: attendanceData['Spóźniony']),
//               if (attendanceData['Nieobecny'].isNotEmpty)
//                 AttendanceSection(
//                     title: "Nieobecności", data: attendanceData['Nieobecny']),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }

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
                  Text("$subject (${lesson['time']})",
                      style: const TextStyle(fontSize: 14)),
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
