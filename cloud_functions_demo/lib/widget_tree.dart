import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions_demo/school_admin_home_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions_demo/service/auth.dart';
import 'package:cloud_functions_demo/admin_home_page.dart';
import 'package:cloud_functions_demo/login_page.dart';
import 'package:cloud_functions_demo/service/database.dart';

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
        return HomePageAdmin();
      } else if (role == 'schoolAdmin') {
        return HomePageSchoolAdmin();
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
