import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdi_main_project/service/auth.dart';

class DatabaseMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addUserData(Map<String, dynamic> userInfoMap, String uid) async {
    return await _firestore.collection("users").doc(uid).set(userInfoMap);
  }

  Future<DocumentSnapshot> getUserDetails() {
    return _firestore.collection("users").doc(Auth().currentUser!.uid).get();
  }

  Future<String> getSchoolId() async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(Auth().currentUser!.uid).get();
    DocumentReference schoolRef = userDoc['school_id'];
    return schoolRef.id;
  }

  Future<Map<String, dynamic>> getClassIdsFromSchoolId(String schoolId) async {
    QuerySnapshot<Map<String, dynamic>> classesSnapshot = await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .get();

    Map<String, dynamic> classesData = {};
    for (var classDoc in classesSnapshot.docs) {
      classesData[classDoc.id] = classDoc['name'];
    }

    return classesData;
  }

  Future<Map<String, dynamic>> getParentsFromSchoolId(String schoolId) async {
    QuerySnapshot<Map<String, dynamic>> usersSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'parent')
        .where('school_id',
            isEqualTo: _firestore.collection('schools').doc(schoolId))
        .get();

    Map<String, dynamic> parentsData = {};
    for (var classDoc in usersSnapshot.docs) {
      parentsData[classDoc.id] = classDoc['name'] + ' ' + classDoc['surname'];
    }

    return parentsData;
  }

  Future<Map<String, dynamic>> getSchools() async {
    QuerySnapshot<Map<String, dynamic>> schoolsSnapshot =
        await _firestore.collection('schools').get();

    Map<String, dynamic> schoolsData = {};
    for (var schoolDoc in schoolsSnapshot.docs) {
      schoolsData[schoolDoc.id] = schoolDoc['name'];
    }

    return schoolsData;
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getStudentGrades(
      String studentId) {
    DocumentReference studentRef =
        _firestore.collection('users').doc(studentId);

    return _firestore
        .collection('grades')
        .where('student_id', isEqualTo: studentRef)
        .get();
  }

  Future<Map<String, Map<String, List<Map<String, String>>>>>
      getTeacherSubjects(String teacherId) async {
    Map<String, Map<String, List<Map<String, String>>>> teacherData = {};
    QuerySnapshot schoolsSnapshot =
        await _firestore.collection('schools').get();

    for (var school in schoolsSnapshot.docs) {
      String schoolName = school['name'];
      String schoolId = school.id;
      QuerySnapshot classesSnapshot =
          await school.reference.collection('classes').get();

      for (var classDoc in classesSnapshot.docs) {
        String className = classDoc['name'];
        String classId = classDoc.id;
        QuerySnapshot subjectsSnapshot = await classDoc.reference
            .collection('subjects')
            .where('employee',
                isEqualTo: _firestore.collection('users').doc(teacherId))
            .get();

        for (var subject in subjectsSnapshot.docs) {
          String subjectName = subject['name'];
          String subjectId = subject.id;

          if (!teacherData.containsKey(schoolName)) {
            teacherData[schoolName] = {};
          }

          if (!teacherData[schoolName]!.containsKey(className)) {
            teacherData[schoolName]![className] = [];
          }

          teacherData[schoolName]![className]!.add({
            'id': subjectId,
            'name': subjectName,
            'schoolId': schoolId,
            'classId': classId,
          });
        }
      }
    }

    return teacherData;
  }

  Future<DocumentSnapshot> getSubjectDetails(
      String schoolId, String classId, String subjectId) async {
    return await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .doc(classId)
        .collection('subjects')
        .doc(subjectId)
        .get();
  }

  Future<List<Map<String, dynamic>>> getSubjectGrades(
      DocumentReference subjectRef) async {
    List<Map<String, dynamic>> studentsGrades = [];

    // Pobierz oceny dla danego przedmiotu
    QuerySnapshot<Map<String, dynamic>> gradesSnapshot = await FirebaseFirestore
        .instance
        .collection('grades')
        .where('subject_id', isEqualTo: subjectRef)
        .get();

    // Mapowanie ocen do uczniów
    Map<String, Map<String, dynamic>> studentGradesMap = {};

    for (var gradeDoc in gradesSnapshot.docs) {
      var gradeData = gradeDoc.data();
      var studentRef = gradeData['student_id'] as DocumentReference;

      // Pobierz dane ucznia
      var studentDoc = await studentRef.get();
      var studentData = studentDoc.data() as Map<String, dynamic>;
      var studentName = studentData['name'] + ' ' + studentData['surname'];
      var studentId = studentRef.id;

      if (!studentGradesMap.containsKey(studentId)) {
        studentGradesMap[studentId] = {
          'name': studentName,
          'student_id': studentId,
          'grades': {},
        };
      }

      var gradeType = gradeData['description'];
      studentGradesMap[studentId]!['grades'][gradeType] = {
        'value': gradeData['grade_value'],
        'weight': gradeData['weight'],
        'grade_id': gradeDoc.id,
      };
    }

    // Przekształć mapę na listę
    studentsGrades = studentGradesMap.values.toList();

    return studentsGrades;
  }

  Future<void> addGrade(Map<String, dynamic> gradeInfo) async {
    return await _firestore.collection("grades").doc().set(gradeInfo);
  }

  Future updateGrade(String gradeId, Map<String, dynamic> updateInfo) async {
    return await _firestore
        .collection("grades")
        .doc(gradeId)
        .update(updateInfo);
  }

  // Announcements
  Future<void> addAnnouncement({
    required String schoolId,
    required String title,
    required String content,
  }) async {
    try {
      await _firestore.collection('announcements').add({
        'school_id': schoolId,
        'title': title,
        'content': content,
        'date': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Nie udało się dodać ogłoszenia: $e');
    }
  }

  Future<void> editAnnouncement({
    required String announcementId,
    required String title,
    required String content,
  }) async {
    try {
      await _firestore.collection('announcements').doc(announcementId).update({
        'title': title,
        'content': content,
        'date': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Nie udało się edytować ogłoszenia: $e');
    }
  }

  Future<void> deleteAnnouncement(String announcementId) async {
    try {
      await _firestore.collection('announcements').doc(announcementId).delete();
    } catch (e) {
      throw Exception('Nie udało się usunąć ogłoszenia: $e');
    }
  }

  Stream<QuerySnapshot> getAnnouncements(String schoolId) {
    try {
      return _firestore
          .collection('announcements')
          .where('school_id', isEqualTo: schoolId)
          .orderBy('date', descending: true)
          .snapshots();
    } catch (e) {
      throw Exception('Nie udało się pobrać ogłoszeń: $e');
    }
  }

  // Future updateEmployeeDetails(
  //     String id, Map<String, dynamic> updateInfo) async {
  //   return await _firestore.collection("Employee").doc(id).update(updateInfo);
  // }

  // Future deleteEmployee(String id) async {
  //   return await _firestore.collection("Employee").doc(id).delete();
  // }
}
