import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdi_main_project/service/auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? errorMessage = '';

  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();

  Future<void> signInWithEmailAndPassword() async {
    if (_controllerEmail.text.isEmpty || _controllerPassword.text.isEmpty) {
      setState(() {
        errorMessage = 'Wprowadź email i hasło';
      });
      return;
    }
    try {
      await Auth().signInWithEmailAndPassword(
        email: _controllerEmail.text,
        password: _controllerPassword.text,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  Widget _title() {
    return const Text('System obsługi dydaktyki');
  }

  Widget _errorMessage() {
    return Text(errorMessage == '' ? '' : 'Coś poszło nie tak: $errorMessage',
        style: const TextStyle(color: Colors.red));
  }

  Widget _submitButton() {
    return ElevatedButton(
      onPressed: signInWithEmailAndPassword,
      child: Text('Login'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _title(),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _controllerEmail,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _controllerPassword,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            _errorMessage(),
            _submitButton(),
          ],
        ),
      ),
    );
  }
}
