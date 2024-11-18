import 'package:cloud_functions_demo/service/auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class HomePageAdmin extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  HomePageAdmin({super.key});

  Future<void> signOut() async {
    await Auth().signOut();
  }

  Widget _signOutButton() {
    return ElevatedButton(
      onPressed: signOut,
      child: const Text('Sign Out'),
    );
  }

  // Future<void> makeMeAdmin() async {
  //   try {
  //     final HttpsCallable callable =
  //         FirebaseFunctions.instance.httpsCallable('makeMeAdmin');
  //     final result = await callable.call();
  //     print(result.data['message']);
  //   } catch (e) {
  //     print('Error: $e');
  //   }
  // }

  Future<void> createSchoolAdmin(String email, String password) async {
    try {
      final HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('createSchoolAdmin');
      final result = await callable.call({
        'email': email,
        'password': password,
      });
      print(result.data['message']);
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Super admin home page')),
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
            ElevatedButton(
              onPressed: () async {
                await createSchoolAdmin(
                  emailController.text,
                  passwordController.text,
                );
              },
              child: const Text('Create User'),
            ),
            // ElevatedButton(
            //   onPressed: () async {
            //     await makeMeAdmin();
            //   },
            //   child: const Text('Make Me Admin'),
            // ),
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
