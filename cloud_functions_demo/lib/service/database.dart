import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions_demo/service/auth.dart';

class DatabaseMethods {
  Future<DocumentSnapshot> getUserDetails() {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(Auth().currentUser!.uid)
        .get();
  }
}
