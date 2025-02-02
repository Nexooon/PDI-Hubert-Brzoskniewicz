import 'package:pdi_main_project/service/auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:pdi_main_project/service/database.dart';

class HomePageSuperAdmin extends StatefulWidget {
  const HomePageSuperAdmin({super.key});

  @override
  State<HomePageSuperAdmin> createState() => _HomePageSuperAdminState();
}

class _HomePageSuperAdminState extends State<HomePageSuperAdmin> {
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
      final data = await DatabaseMethods().getSchools();
      setState(() {
        schoolsData = data;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Nie udało się pobrać szkół: $e';
      });
    }
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
        SnackBar(
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
        title: Text('Super Admin - strona główna'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Imię'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Proszę wpisać imię'
                    : null,
              ),
              TextFormField(
                controller: _surnameController,
                decoration: InputDecoration(labelText: 'Nazwisko'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Proszę wpisać nazwisko'
                    : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Proszę wpisać email'
                    : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Hasło'),
                obscureText: false,
                validator: (value) => value == null || value.isEmpty
                    ? 'Proszę wpisać hasło'
                    : null,
              ),
              SizedBox(height: 15),
              schoolsData != null
                  ? SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Szkoła',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedSchool,
                        items: schoolsData!.keys.map((schoolId) {
                          return DropdownMenuItem<String>(
                            value: schoolId,
                            child: Text(schoolsData![schoolId]),
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
                  : CircularProgressIndicator(),
              _errorMessage(),
              SizedBox(height: 10),
              if (isLoading)
                CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: () async {
                    await createSchoolAdmin();
                  },
                  child: Text('Dodaj szkolnego administratora'),
                ),
              SizedBox(height: 20),
              _signOutButton(),
            ],
          ),
        ),
      ),
    );
  }
}
