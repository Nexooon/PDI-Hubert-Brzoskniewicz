import 'package:flutter/material.dart';
import 'package:pdi_main_project/service/database.dart';

class AddClassPageSa extends StatefulWidget {
  final DatabaseMethods databaseMethods;
  final String schoolId;

  const AddClassPageSa({
    super.key,
    required this.databaseMethods,
    required this.schoolId,
  });

  @override
  State<AddClassPageSa> createState() => _AddClassPageSaState();
}

class _AddClassPageSaState extends State<AddClassPageSa> {
  final TextEditingController _classNameController = TextEditingController();
  String? error;

  Future<void> _addClass() async {
    String className = _classNameController.text.trim();
    if (className.isEmpty) {
      setState(() => error = 'Nazwa klasy nie może być pusta');
      return;
    }

    try {
      await widget.databaseMethods.addClassToSchool(widget.schoolId, className);
      Navigator.pop(context); // wróć do strony głównej po dodaniu
    } catch (e) {
      setState(() => error = 'Błąd przy dodawaniu klasy: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dodaj klasę')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _classNameController,
              decoration:
                  const InputDecoration(labelText: 'Nazwa klasy (np. 2B)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addClass,
              child: const Text('Dodaj klasę'),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(error!, style: const TextStyle(color: Colors.red)),
            ]
          ],
        ),
      ),
    );
  }
}
