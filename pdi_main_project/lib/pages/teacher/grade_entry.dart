import 'package:cloud_firestore/cloud_firestore.dart';

class GradeEntry {
  final String gradeId;
  final DocumentReference studentId;
  final DocumentReference subjectId;
  String subjectName;
  String schoolYear;
  int weight;
  bool isFinal;
  String? value;
  String description;
  String? comment;
  DateTime date;

  GradeEntry({
    required this.gradeId,
    required this.studentId,
    required this.subjectId,
    required this.subjectName,
    required this.schoolYear,
    required this.weight,
    required this.isFinal,
    this.value,
    required this.description,
    this.comment,
    required this.date,
  });
}
