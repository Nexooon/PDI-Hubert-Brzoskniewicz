import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdi_main_project/pages/school_admin/subjects_page_sa.dart';
import 'package:pdi_main_project/service/database.dart';

class ManageClassesPageSa extends StatefulWidget {
  final DatabaseMethods databaseMethods;
  final String schoolId;

  const ManageClassesPageSa({
    super.key,
    required this.databaseMethods,
    required this.schoolId,
  });

  @override
  State<ManageClassesPageSa> createState() => _ManageClassesPageSaState();
}

class _ManageClassesPageSaState extends State<ManageClassesPageSa> {
  Future<List<Map<String, dynamic>>>? _classesFuture;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  void _loadClasses() {
    setState(() {
      _classesFuture =
          widget.databaseMethods.getClassesForSchool(widget.schoolId);
    });
  }

  void _showAddClassDialog() async {
    final TextEditingController controller = TextEditingController();
    List<DocumentSnapshot> teachers = [];

    try {
      teachers =
          await widget.databaseMethods.getTeachersForSchool(widget.schoolId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd pobierania nauczycieli: $e')),
      );
      return;
    }

    String? selectedTeacherId;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Dodaj klasę'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Nazwa klasy (np. 2B)',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedTeacherId,
                  items: teachers.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text('${data['name']} ${data['surname']}'),
                    );
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => selectedTeacherId = value),
                  decoration: const InputDecoration(
                    labelText: 'Wychowawca klasy',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Anuluj'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final className = controller.text.trim();
                  if (className.isNotEmpty && selectedTeacherId != null) {
                    await widget.databaseMethods.addClassToSchool(
                      widget.schoolId,
                      className,
                      selectedTeacherId!,
                    );
                    Navigator.pop(context);
                    _loadClasses();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Uzupełnij wszystkie pola')),
                    );
                  }
                },
                child: const Text('Dodaj'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditDialog(String classId, String currentName) {
    final TextEditingController controller =
        TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edytuj nazwę klasy'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nowa nazwa klasy'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await widget.databaseMethods
                    .updateClassName(widget.schoolId, classId, newName);
                Navigator.pop(context);
                _loadClasses();
              }
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String classId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Usuń klasę'),
        content: const Text('Czy na pewno chcesz usunąć tę klasę?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () async {
              await widget.databaseMethods
                  .deleteClass(widget.schoolId, classId);
              Navigator.pop(context);
              _loadClasses();
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
      appBar: AppBar(title: const Text('Zarządzaj klasami')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _classesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Błąd: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Brak klas'));
          }

          final classes = snapshot.data!;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView.builder(
                itemCount: classes.length,
                itemBuilder: (context, index) {
                  final classData = classes[index];
                  return ListTile(
                    title: Text(classData['name']),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SubjectsPageSa(
                            databaseMethods: widget.databaseMethods,
                            schoolId: widget.schoolId,
                            classId: classData['id'],
                            className: classData['name'],
                          ),
                        ),
                      );
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEditDialog(
                              classData['id'], classData['name']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _confirmDelete(classData['id']),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 30),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddClassDialog,
        tooltip: 'Dodaj klasę',
        child: const Icon(Icons.add),
      ),
    );
  }
}
