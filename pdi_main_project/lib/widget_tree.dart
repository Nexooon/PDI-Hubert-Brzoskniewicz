import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pdi_main_project/pages/parent/home_page_parent.dart';
import 'package:pdi_main_project/pages/super_admin/home_page_super_admin.dart';
import 'package:pdi_main_project/pages/teacher/home_page_teacher.dart';
import 'package:pdi_main_project/service/auth.dart';
import 'package:pdi_main_project/pages/school_admin/home_page_school_admin.dart';
import 'package:pdi_main_project/pages/login_page.dart';
import 'package:pdi_main_project/pages/student/home_page_student.dart';
import 'package:pdi_main_project/service/database.dart';

class WidgetTree extends StatefulWidget {
  const WidgetTree({super.key});

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  Future<Widget> getHomePage() async {
    final User? currentUser = Auth().currentUser;
    // final DatabaseMethods databaseMethods = DatabaseMethods();

    if (currentUser != null) {
      String currentUserUid = currentUser.uid;

      IdTokenResult token = await currentUser.getIdTokenResult();

      DatabaseMethods databaseMethods = DatabaseMethods();
      print(currentUser.email);
      print(token.claims);

      if (token.claims?['superAdmin'] == true) {
        return const HomePageSuperAdmin();
      } else if (token.claims?['schoolAdmin'] == true) {
        return const HomePageSchoolAdmin();
      } else if (token.claims?['student'] == true) {
        String schoolId = await databaseMethods.getSchoolId();
        return HomePageStudent(
          currentUserUid: currentUserUid,
          schoolId: schoolId,
          databaseMethods: databaseMethods,
        );
      } else if (token.claims?['teacher'] == true) {
        String schoolId = await databaseMethods.getSchoolId();
        return HomePageTeacher(
          currentUserUid: currentUserUid,
          schoolId: schoolId,
          databaseMethods: databaseMethods,
        );
      } else if (token.claims?['parent'] == true) {
        String schoolId = await databaseMethods.getSchoolId();
        return HomePageParent(
          currentUserUid: currentUserUid,
          schoolId: schoolId,
          databaseMethods: databaseMethods,
        );
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
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasData) {
          return FutureBuilder<Widget>(
            future: getHomePage(),
            builder: (context, AsyncSnapshot<Widget> homePageSnapshot) {
              if (homePageSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
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
