import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdi_main_project/service/auth.dart';
import 'package:pdi_main_project/pages/admin/home_page_admin.dart';
import 'package:pdi_main_project/pages/login_register_page.dart';
import 'package:pdi_main_project/service/database.dart';
import 'package:pdi_main_project/pages/student/home_page_student.dart';

class WidgetTree extends StatefulWidget {
  const WidgetTree({super.key});

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  DocumentSnapshot? currentUser;

  Future<Widget> getHomePage() async {
    currentUser = await DatabaseMethods().getUserDetails();

    if (currentUser != null) {
      String role = currentUser!['role'];
      if (role == 'admin') {
        return const HomePageAdmin();
      } else if (role == 'student') {
        return HomePageStudent(currentUser: currentUser!);
      }
    }
    return const LoginPage();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Auth().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasData) {
          return FutureBuilder<Widget>(
            future: getHomePage(),
            builder: (context, AsyncSnapshot<Widget> homePageSnapshot) {
              if (homePageSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              } else if (homePageSnapshot.hasData) {
                return homePageSnapshot.data!;
              } else {
                return const LoginPage();
              }
            },
          );
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
