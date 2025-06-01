import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdi_main_project/service/database.dart';

class ExcusesPage extends StatefulWidget {
  final String teacherId;
  final String schoolId;
  final DatabaseMethods databaseMethods;

  const ExcusesPage({
    super.key,
    required this.teacherId,
    required this.schoolId,
    required this.databaseMethods,
  });

  @override
  State<ExcusesPage> createState() => _ExcusesPageState();
}

class _ExcusesPageState extends State<ExcusesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Usprawiedliwienia do zatwierdzenia")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('excuses')
            .where('educator_id', isEqualTo: widget.teacherId)
            .where('approved', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Błąd: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text("Brak usprawiedliwień do zatwierdzenia."));
          }

          final excuses = snapshot.data!.docs;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView.builder(
                itemCount: excuses.length,
                itemBuilder: (context, index) {
                  final excuse = excuses[index];
                  final excuseData = excuse.data() as Map<String, dynamic>;
                  final studentId = excuseData['student_id'];

                  final formattedDate = DateFormat('dd.MM.yyyy')
                      .format((excuseData['date'] as Timestamp).toDate());

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(studentId)
                        .get(),
                    builder: (context, studentSnapshot) {
                      if (studentSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const ListTile(
                            title: Text("Ładowanie danych ucznia..."));
                      }

                      if (!studentSnapshot.hasData ||
                          !studentSnapshot.data!.exists) {
                        return ListTile(
                          title: const Text("Nie znaleziono ucznia"),
                          subtitle: Text("ID: $studentId"),
                        );
                      }

                      final studentData =
                          studentSnapshot.data!.data() as Map<String, dynamic>;
                      final studentName =
                          "${studentData['name']} ${studentData['surname']}";

                      return Card(
                        margin: const EdgeInsets.all(8),
                        elevation: 4,
                        child: ListTile(
                          title: Text("Uczeń: $studentName"),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Data: $formattedDate"),
                              Text("Powód: ${excuseData['reason']}"),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.check_circle,
                                color: Colors.grey),
                            tooltip: 'Zatwierdź usprawiedliwienie',
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);

                              await widget.databaseMethods.approveExcuse(
                                  excuse.id, studentId, widget.schoolId);

                              messenger.showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Usprawiedliwienie zatwierdzone')),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
