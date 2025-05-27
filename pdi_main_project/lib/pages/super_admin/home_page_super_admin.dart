import 'package:pdi_main_project/pages/super_admin/add_school_admin_page.dart';
import 'package:pdi_main_project/pages/super_admin/manage_schools_page.dart';
import 'package:pdi_main_project/service/auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:pdi_main_project/service/database.dart';

class HomePageSuperAdmin extends StatefulWidget {
  final DatabaseMethods databaseMethods;

  const HomePageSuperAdmin({super.key, required this.databaseMethods});

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
        title: const Text('Super Admin - strona główna'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddSchoolAdminPage(
                              databaseMethods: widget.databaseMethods),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('Dodaj administratora szkoły'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ManageSchoolsPage(
                              databaseMethods: widget.databaseMethods),
                        ),
                      );
                    },
                    icon: const Icon(Icons.school),
                    label: const Text('Zarządzaj szkołami'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: signOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Wyloguj'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
