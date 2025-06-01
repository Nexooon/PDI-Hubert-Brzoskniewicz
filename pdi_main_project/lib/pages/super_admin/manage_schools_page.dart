import 'package:flutter/material.dart';
import 'package:pdi_main_project/service/database.dart';

class ManageSchoolsPage extends StatefulWidget {
  final DatabaseMethods databaseMethods;

  const ManageSchoolsPage({super.key, required this.databaseMethods});

  @override
  State<ManageSchoolsPage> createState() => _ManageSchoolsPageState();
}

class _ManageSchoolsPageState extends State<ManageSchoolsPage> {
  Map<String, dynamic>? schools;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  Future<void> _loadSchools() async {
    setState(() => isLoading = true);
    try {
      final data = await widget.databaseMethods.getSchoolsWithDetails();
      setState(() {
        schools = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _deleteSchool(String schoolId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potwierdzenie'),
        content: const Text('Czy na pewno chcesz usunąć tę szkołę?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.databaseMethods.deleteSchool(schoolId);
        await _loadSchools();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd przy usuwaniu szkoły: $e')),
        );
      }
    }
  }

  void _showSchoolDialog({Map<String, dynamic>? school, String? schoolId}) {
    final nameController = TextEditingController(text: school?['name'] ?? '');
    final addressController =
        TextEditingController(text: school?['address'] ?? '');
    final contactController =
        TextEditingController(text: school?['contact'] ?? '');
    final yearController =
        TextEditingController(text: school?['current_year'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(school == null ? 'Dodaj szkołę' : 'Edytuj szkołę'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nazwa')),
              TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Adres')),
              TextField(
                  controller: contactController,
                  decoration: const InputDecoration(labelText: 'Kontakt')),
              TextField(
                  controller: yearController,
                  decoration: const InputDecoration(labelText: 'Rok szkolny')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anuluj')),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final address = addressController.text.trim();
              final contact = contactController.text.trim();
              final year = yearController.text.trim();

              if (name.isEmpty ||
                  address.isEmpty ||
                  contact.isEmpty ||
                  year.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Wszystkie pola są wymagane')),
                );
                return;
              }

              final data = {
                'name': name,
                'address': address,
                'contact': contact,
                'current_year': year,
              };

              try {
                if (school == null) {
                  await widget.databaseMethods.addSchool(data);
                } else {
                  await widget.databaseMethods.updateSchool(schoolId!, data);
                }

                Navigator.pop(context);
                await _loadSchools();
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Błąd: $e')),
                );
              }
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zarządzanie szkołami')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSchoolDialog(),
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text('Błąd: $errorMessage'))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: ListView(
                      children: schools!.entries.map((entry) {
                        final id = entry.key;
                        final school = entry.value;
                        return ListTile(
                          title: Text(school['name']),
                          subtitle: Text(
                              '${school['address']}\nKontakt: ${school['contact']}\nRok: ${school['current_year']}'),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showSchoolDialog(
                                    school: school, schoolId: id),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteSchool(id),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
    );
  }
}
