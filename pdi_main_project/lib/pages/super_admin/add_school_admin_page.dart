import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:pdi_main_project/service/database.dart';

class AddSchoolAdminPage extends StatefulWidget {
  final DatabaseMethods databaseMethods;

  const AddSchoolAdminPage({super.key, required this.databaseMethods});

  @override
  State<AddSchoolAdminPage> createState() => _AddSchoolAdminPageState();
}

class _AddSchoolAdminPageState extends State<AddSchoolAdminPage> {
  String? errorMessage = '';
  bool isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? selectedSchool;
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic>? schoolsData;

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  Future<void> _loadSchools() async {
    try {
      final data = await widget.databaseMethods.getSchools();
      setState(() {
        schoolsData = data;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Nie udało się pobrać szkół: $e';
      });
    }
  }

  Widget _errorMessage() {
    return Text(errorMessage == '' ? '' : 'Coś poszło nie tak: $errorMessage',
        style: const TextStyle(color: Colors.red));
  }

  Future<void> createSchoolAdmin() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        errorMessage = '';
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('createSchoolAdmin');
      await callable.call({
        'name': _nameController.text,
        'surname': _surnameController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
        'schoolId': selectedSchool,
      });

      _nameController.clear();
      _surnameController.clear();
      _emailController.clear();
      _passwordController.clear();
      setState(() {
        selectedSchool = null;
        errorMessage = '';
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Użytkownik dodany pomyślnie!',
            selectionColor: Colors.green,
          ),
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      setState(() {
        errorMessage = e.message;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dodaj administratora szkoły'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Imię'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Proszę wpisać imię'
                          : null,
                    ),
                    TextFormField(
                      controller: _surnameController,
                      decoration: const InputDecoration(labelText: 'Nazwisko'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Proszę wpisać nazwisko'
                          : null,
                    ),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Proszę wpisać email'
                          : null,
                    ),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Hasło'),
                      obscureText: false,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Proszę wpisać hasło'
                          : null,
                    ),
                    const SizedBox(height: 15),
                    schoolsData != null
                        ? SizedBox(
                            width: MediaQuery.of(context).size.width * 0.9,
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Szkoła',
                                border: OutlineInputBorder(),
                              ),
                              value: selectedSchool,
                              items: schoolsData!.keys.map((schoolId) {
                                return DropdownMenuItem<String>(
                                  value: schoolId,
                                  child: Tooltip(
                                    message: schoolsData![schoolId],
                                    child: Text(
                                      schoolsData![schoolId],
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedSchool = value;
                                });
                              },
                              validator: (value) =>
                                  value == null ? 'Proszę wybrać szkołę' : null,
                            ),
                          )
                        : const CircularProgressIndicator(),
                    _errorMessage(),
                    const SizedBox(height: 10),
                    if (isLoading)
                      const CircularProgressIndicator()
                    else
                      ElevatedButton(
                        onPressed: () async {
                          await createSchoolAdmin();
                        },
                        child: const Text('Dodaj szkolnego administratora'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
