import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdi_main_project/service/auth.dart';

class DatabaseMethods {
  // Future addEmployeeDetails(
  //     Map<String, dynamic> employeeInfoMap, String id) async {
  //   return await FirebaseFirestore.instance
  //       .collection("Employee")
  //       .doc(id)
  //       .set(employeeInfoMap);
  // }

  Future<DocumentSnapshot> getUserDetails() {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(Auth().currentUser!.uid)
        .get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getStudentGrades(
      String studentId) {
    DocumentReference studentRef =
        FirebaseFirestore.instance.collection('users').doc(studentId);
    return FirebaseFirestore.instance
        .collection('grades')
        .where('student_id', isEqualTo: studentRef)
        .get();
  }

  // Future updateEmployeeDetails(
  //     String id, Map<String, dynamic> updateInfo) async {
  //   return await FirebaseFirestore.instance
  //       .collection("Employee")
  //       .doc(id)
  //       .update(updateInfo);
  // }

  // Future deleteEmployee(String id) async {
  //   return await FirebaseFirestore.instance
  //       .collection("Employee")
  //       .doc(id)
  //       .delete();
  // }
}
