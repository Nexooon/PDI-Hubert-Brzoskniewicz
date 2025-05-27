import 'package:flutter/material.dart';
import 'package:pdi_main_project/pages/school_admin/add_user_page_sa.dart';
import 'package:pdi_main_project/pages/school_admin/manage_classes_page_sa.dart';
import 'package:pdi_main_project/service/auth.dart';
import 'package:pdi_main_project/service/database.dart';

class HomePageSchoolAdmin extends StatefulWidget {
  final DatabaseMethods databaseMethods;
  const HomePageSchoolAdmin({super.key, required this.databaseMethods});

  @override
  State<HomePageSchoolAdmin> createState() => _HomePageSchoolAdminState();
}

class _HomePageSchoolAdminState extends State<HomePageSchoolAdmin> {
  String? errorMessage;
  String? schoolId;
  String currentYear = '';
  Map<int, Map<String, String>> lessonTimes = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchoolInfo();
  }

  Future<void> _loadSchoolInfo() async {
    try {
      final id = await widget.databaseMethods.getSchoolId();
      final year = await widget.databaseMethods.getCurrentYear(id);
      final times = await widget.databaseMethods.getLessonTimes(id);
      setState(() {
        schoolId = id;
        currentYear = year;
        lessonTimes = times;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Błąd: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _changeCurrentYear() async {
    final controller = TextEditingController(text: currentYear);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Zmień aktualny rok szkolny'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nowy rok szkolny (np. 2024/2025)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: schoolId == null
                ? null
                : () async {
                    final newYear = controller.text.trim();

                    final regex = RegExp(r'^\d{4}/\d{4}$');
                    if (!regex.hasMatch(newYear)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Nieprawidłowy format. Użyj np. 2024/2025.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (newYear.isNotEmpty && newYear != currentYear) {
                      await widget.databaseMethods
                          .updateCurrentYear(schoolId!, newYear);
                      setState(() {
                        currentYear = newYear;
                      });
                    }

                    Navigator.pop(context);
                  },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
  }

  void _showEditLessonTimesDialog() {
    final controllers = <int, Map<String, TextEditingController>>{};

    for (var entry in lessonTimes.entries) {
      controllers[entry.key] = {
        'start': TextEditingController(text: entry.value['start']),
        'end': TextEditingController(text: entry.value['end']),
      };
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edytuj godziny lekcji'),
        content: SingleChildScrollView(
          child: Column(
            children: lessonTimes.keys.map((num) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lekcja $num',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controllers[num]!['start'],
                          decoration: const InputDecoration(labelText: 'Start'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: controllers[num]!['end'],
                          decoration:
                              const InputDecoration(labelText: 'Koniec'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updatedTimes = <int, Map<String, String>>{};
              for (var entry in controllers.entries) {
                final num = entry.key;
                final start = entry.value['start']!.text.trim();
                final end = entry.value['end']!.text.trim();

                if (start.isNotEmpty && end.isNotEmpty) {
                  updatedTimes[num] = {'start': start, 'end': end};
                }
              }

              if (schoolId != null) {
                await widget.databaseMethods
                    .updateLessonTimes(schoolId!, updatedTimes);
                setState(() {
                  lessonTimes = updatedTimes;
                });
              }

              Navigator.pop(context);
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
  }

  Future<void> signOut() async {
    await Auth().signOut();
  }

  Widget _signOutButton() {
    return ElevatedButton(
      onPressed: signOut,
      child: const Text('Wyloguj'),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('School Admin - strona główna')),
        body: Center(
          child: Text(errorMessage!),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('School Admin - strona główna')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Witaj, Adminie Szkoły!'),
            const SizedBox(height: 20),
            Text('Aktualny rok szkolny: $currentYear'),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _changeCurrentYear,
              child: const Text('Zmień rok szkolny'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: schoolId == null
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddUserPageSa(
                            databaseMethods: widget.databaseMethods,
                            schoolId: schoolId!,
                          ),
                        ),
                      );
                    },
              child: const Text('Dodaj użytkownika'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: schoolId == null
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ManageClassesPageSa(
                            databaseMethods: widget.databaseMethods,
                            schoolId: schoolId!,
                          ),
                        ),
                      );
                    },
              child: const Text('Zarządzaj klasami'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: schoolId == null ? null : _showEditLessonTimesDialog,
              child: const Text('Modyfikuj godziny zajęć'),
            ),
            const SizedBox(height: 20),
            _signOutButton(),
          ],
        ),
      ),
    );
  }
}
