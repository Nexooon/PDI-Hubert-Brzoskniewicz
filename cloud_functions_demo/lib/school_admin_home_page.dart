import 'package:cloud_functions_demo/service/auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class HomePageSchoolAdmin extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController roleController = TextEditingController();

  HomePageSchoolAdmin({super.key});

  Future<void> signOut() async {
    await Auth().signOut();
  }

  Widget _signOutButton() {
    return ElevatedButton(
      onPressed: signOut,
      child: const Text('Sign Out'),
    );
  }

  Future<void> createUser(String email, String password, String role) async {
    try {
      final HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('createUser');
      final result = await callable.call({
        'email': email,
        'password': password,
        'role': role,
      });
      print(result.data['message']);
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('School admin home page')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            TextField(
              controller: roleController,
              decoration: const InputDecoration(
                  labelText: 'Role (e.g., student, teacher)'),
            ),
            ElevatedButton(
              onPressed: () async {
                await createUser(
                  emailController.text,
                  passwordController.text,
                  roleController.text,
                );
              },
              child: const Text('Create User'),
            ),
            const SizedBox(
              height: 20.0,
            ),
            _signOutButton(),
          ],
        ),
      ),
    );
  }
}
