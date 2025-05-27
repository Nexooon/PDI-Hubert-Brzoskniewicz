import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:pdi_main_project/service/database.dart';

class AddUserPageSa extends StatefulWidget {
  final String schoolId;
  final DatabaseMethods databaseMethods;
  const AddUserPageSa(
      {super.key, required this.schoolId, required this.databaseMethods});

  @override
  State<AddUserPageSa> createState() => _HomePageSchoolAdminState();
}

class _HomePageSchoolAdminState extends State<AddUserPageSa> {
  String? errorMessage = '';
  bool isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? selectedRole;
  String? selectedClass;
  String? selectedParent;
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic>? classesData;
  Map<String, dynamic>? parentsData;

  @override
  void initState() {
    super.initState();
    _loadSchoolInfo();
  }

  Future<void> _loadSchoolInfo() async {
    try {
      await _loadClassIds();
      await _loadParentIds();
    } catch (e) {
      setState(() {
        errorMessage = 'Nie udało się pobrać schoolId: $e';
      });
    }
  }

  Future<void> _loadClassIds() async {
    try {
      classesData =
          await widget.databaseMethods.getClassIdsFromSchoolId(widget.schoolId);
    } catch (e) {
      setState(() {
        errorMessage = 'Nie udało się pobrać klas: $e';
      });
    }
  }

  Future<void> _loadParentIds() async {
    try {
      parentsData =
          await widget.databaseMethods.getParentsFromSchoolId(widget.schoolId);
    } catch (e) {
      setState(() {
        errorMessage = 'Nie udało się pobrać rodziców: $e';
      });
    }
  }

  Widget _errorMessage() {
    return Text(errorMessage == '' ? '' : 'Coś poszło nie tak: $errorMessage',
        style: const TextStyle(color: Colors.red));
  }

  Future<void> createUser() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        errorMessage = '';
      });
      return;
    }

    // if (widget.schoolId == null) {
    //   setState(() {
    //     errorMessage = 'Nie można dodać użytkownika: brak schoolId';
    //   });
    //   return;
    // }

    setState(() {
      isLoading = true;
    });

    try {
      final HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('createUser');
      await callable.call({
        'name': _nameController.text,
        'surname': _surnameController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
        'role': selectedRole!,
        'schoolId': widget.schoolId,
        'classId': selectedClass ?? '',
        'parentId': selectedParent ?? '',
      });

      _nameController.clear();
      _surnameController.clear();
      _emailController.clear();
      _passwordController.clear();
      setState(() {
        selectedRole = null;
        selectedParent = null;
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
    final List<String> roles = ['student', 'teacher', 'parent'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dodaj użytkownika'),
      ),
      body: Padding(
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
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Rola',
                  border: OutlineInputBorder(),
                ),
                value: selectedRole,
                items: roles.map((role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedRole = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Proszę wybrać rolę' : null,
              ),
              const SizedBox(height: 15),
              selectedRole == 'student'
                  ? Column(
                      children: [
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Klasa',
                            border: OutlineInputBorder(),
                          ),
                          value: selectedClass,
                          items: classesData!.keys.map((schoolId) {
                            return DropdownMenuItem<String>(
                              value: schoolId,
                              child: Text(classesData![schoolId]),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedClass = value;
                            });
                          },
                          validator: (value) =>
                              value == null && selectedRole == 'student'
                                  ? 'Proszę wybrać klasę'
                                  : null,
                        ),
                        const SizedBox(height: 15),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Rodzic',
                            border: OutlineInputBorder(),
                          ),
                          value: selectedParent,
                          items: parentsData!.keys.map((schoolId) {
                            return DropdownMenuItem<String>(
                              value: schoolId,
                              child: Text(parentsData![schoolId]),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedParent = value;
                            });
                          },
                          validator: (value) =>
                              value == null && selectedRole == 'student'
                                  ? 'Proszę wybrać rodzica'
                                  : null,
                        ),
                      ],
                    )
                  // : selectedRole == 'teacher'
                  //     ? DropdownButtonFormField<String>(
                  //         decoration: const InputDecoration(
                  //           labelText: 'Klasa',
                  //           border: OutlineInputBorder(),
                  //         ),
                  //         value: selectedClass,
                  //         items: classesData!.keys.map((schoolId) {
                  //           return DropdownMenuItem<String>(
                  //             value: schoolId,
                  //             child: Text(classesData![schoolId]),
                  //           );
                  //         }).toList(),
                  //         onChanged: (value) {
                  //           setState(() {
                  //             selectedClass = value;
                  //           });
                  //         },
                  //         validator: (value) =>
                  //             value == null && selectedRole == 'teacher'
                  //                 ? 'Proszę wybrać klasę'
                  //                 : null,
                  //       )
                  : const SizedBox(),
              _errorMessage(),
              const SizedBox(height: 10),
              if (isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: () async {
                    await createUser();
                  },
                  child: const Text('Dodaj użytkownika'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
