import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdi_main_project/service/auth.dart';
import 'package:firebase_performance/firebase_performance.dart';

final FirebasePerformance performance = FirebasePerformance.instance;

class DatabaseMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addUserData(Map<String, dynamic> userInfoMap, String uid) async {
    return await _firestore.collection("users").doc(uid).set(userInfoMap);
  }

  Future<DocumentSnapshot> getUserDetails() {
    return _firestore.collection("users").doc(Auth().currentUser!.uid).get();
  }

  Future<Map<String, dynamic>> getUser(String userId) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();
    return userDoc.data() as Map<String, dynamic>;
  }

  Future<DocumentSnapshot> getUserDetailsById(String userId) {
    return _firestore.collection("users").doc(userId).get();
  }

  Future<String> getStudentClass(String studentId) async {
    DocumentSnapshot studentDoc =
        await _firestore.collection('users').doc(studentId).get();
    DocumentReference classRef = studentDoc['class_id'];
    return classRef.id;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      getStudentsFromClass(String schoolId, String classId) async {
    QuerySnapshot<Map<String, dynamic>> studentsSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('class_id',
            isEqualTo: _firestore
                .collection('schools')
                .doc(schoolId)
                .collection('classes')
                .doc(classId))
        .orderBy('surname', descending: false)
        .get();

    return studentsSnapshot.docs;
  }

  Future<String> getSchoolId() async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(Auth().currentUser!.uid).get();
    DocumentReference schoolRef = userDoc['school_id'];
    return schoolRef.id;
  }

  Future<String> getSchoolName(String schoolId) async {
    DocumentSnapshot schoolDoc =
        await _firestore.collection('schools').doc(schoolId).get();
    return schoolDoc['name'];
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

  Future<String> getClassName(String schoolId, String classId) async {
    DocumentSnapshot classDoc = await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .doc(classId)
        .get();
    return classDoc['name'];
  }

  Future<Map<String, dynamic>> getParentsFromSchoolId(String schoolId) async {
    QuerySnapshot<Map<String, dynamic>> usersSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'parent')
        .where('school_id',
            isEqualTo: _firestore.collection('schools').doc(schoolId))
        .get();

    // Lista krotek (id, imię nazwisko)
    List<MapEntry<String, String>> parentsList = usersSnapshot.docs.map((doc) {
      return MapEntry(doc.id, '${doc['name']} ${doc['surname']}');
    }).toList();

    // Sortowanie po nazwisku (czyli po ostatnim członie)
    parentsList.sort(
        (a, b) => a.value.split(' ').last.compareTo(b.value.split(' ').last));

    // Konwersja z powrotem na mapę
    return Map.fromEntries(parentsList);
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

  Future<Map<String, dynamic>> getChildren(String currentUserUid) async {
    QuerySnapshot<Map<String, dynamic>> childrenSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('parent_id',
            isEqualTo: _firestore.collection('users').doc(currentUserUid))
        .get();

    Map<String, dynamic> childrenData = {};
    for (var childDoc in childrenSnapshot.docs) {
      childrenData[childDoc.id] = childDoc['name'] + ' ' + childDoc['surname'];
    }

    return childrenData;
  }

  Future<void> addEmptyGradeForAllStudents(
      String schoolId,
      String classId,
      String subjectId,
      String year,
      String description,
      String subjectName) async {
    QuerySnapshot studentsSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('class_id',
            isEqualTo: _firestore
                .collection('schools')
                .doc(schoolId)
                .collection('classes')
                .doc(classId))
        .get();

    DocumentReference subjectRef = _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .doc(classId)
        .collection('subjects')
        .doc(subjectId);

    for (var studentDoc in studentsSnapshot.docs) {
      DocumentReference studentRef = studentDoc.reference;
      Map<String, dynamic> gradeData = {
        'date': Timestamp.now().toDate(),
        'description': description,
        'grade_value': null,
        'is_final': false,
        'school_year': year,
        'student_id': studentRef,
        'subject_id': subjectRef,
        'subject_name': subjectName,
        'weight': null,
      };
      try {
        await _firestore.collection('grades').add(gradeData);
      } catch (e) {
        print("Błąd podczas dodawania pustej oceny: $e");
      }
    }
  }

  Future<List<Map<String, dynamic>>> getStudentGrades(String studentId) async {
    DocumentReference studentRef =
        _firestore.collection('users').doc(studentId);

    final snapshot = await _firestore
        .collection('grades')
        .where('student_id', isEqualTo: studentRef)
        .where('grade_value', isNull: false)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<Map<String, Map<String, List<Map<String, String>>>>>
      getTeacherSubjects(String teacherId) async {
    Map<String, Map<String, List<Map<String, String>>>> tempData = {};
    QuerySnapshot schoolsSnapshot =
        await _firestore.collection('schools').get();

    for (var school in schoolsSnapshot.docs) {
      String schoolName = school['name'];
      String schoolId = school.id;
      String year = school['current_year'];
      QuerySnapshot classesSnapshot =
          await school.reference.collection('classes').get();

      for (var classDoc in classesSnapshot.docs) {
        String className = classDoc['name'];
        String classId = classDoc.id;
        QuerySnapshot subjectsSnapshot = await classDoc.reference
            .collection('subjects')
            .where('employee',
                isEqualTo: _firestore.collection('users').doc(teacherId))
            .where('year', isEqualTo: year)
            .get();

        for (var subject in subjectsSnapshot.docs) {
          String subjectName = subject['name'];
          String subjectId = subject.id;

          tempData.putIfAbsent(schoolName, () => {});
          tempData[schoolName]!.putIfAbsent(className, () => []);
          tempData[schoolName]![className]!.add({
            'id': subjectId,
            'name': subjectName,
            'schoolId': schoolId,
            'classId': classId,
          });
        }
      }
    }

    // Sortowanie klas i przedmiotów
    Map<String, Map<String, List<Map<String, String>>>> sortedData = {};

    for (var schoolEntry in tempData.entries) {
      var sortedClasses = Map.fromEntries(
        schoolEntry.value.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key)),
      );

      // Sortuj listy przedmiotów
      sortedClasses.updateAll((className, subjects) {
        subjects.sort((a, b) => a['name']!.compareTo(b['name']!));
        return subjects;
      });

      sortedData[schoolEntry.key] = sortedClasses;
    }

    return sortedData;
  }

  Future<Map<String, dynamic>> getStudentSubjects(String studentId) async {
    Map<String, dynamic> studentData = {};
    DocumentSnapshot studentDoc = await _firestore
        .collection('users')
        .doc(studentId)
        .get(); // Pobierz dokument ucznia na podstawie jego ID
    DocumentReference schoolRef = studentDoc['school_id'];
    DocumentReference classRef = studentDoc['class_id'];
    String year = await schoolRef.get().then((value) => value['current_year']);

    //pobierz aktualne przedmioty
    QuerySnapshot subjectsSnapshot = await schoolRef
        .collection('classes')
        .doc(classRef.id)
        .collection('subjects')
        .where('year', isEqualTo: year)
        .get();

    for (var subject in subjectsSnapshot.docs) {
      String subjectName = subject['name'];
      String subjectId = subject.id;

      studentData[subjectName] = {
        'id': subjectId,
        'name': subjectName,
        'schoolId': schoolRef.id,
        'classId': classRef.id
      };
    }

    return studentData;
  }

// LESSON TOPICS

  Future<Map<String, dynamic>> getLessonTopics(
      String schoolId, String classId, String subjectId) async {
    Map<String, dynamic> topicsData = {};
    QuerySnapshot lessonsRef = await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .doc(classId)
        .collection('subjects')
        .doc(subjectId)
        .collection('lessons')
        .orderBy('date', descending: true)
        .get();

    for (var lesson in lessonsRef.docs) {
      topicsData[lesson.id] = {
        "topic": lesson['topic'],
        "date": lesson['date']
      };
    }

    return topicsData;
  }

  Future<void> addTopic(String schoolId, String classId, String subjectId,
      Map<String, dynamic> lessonInfo) async {
    return await _firestore
        .collection("schools")
        .doc(schoolId)
        .collection("classes")
        .doc(classId)
        .collection("subjects")
        .doc(subjectId)
        .collection("lessons")
        .doc()
        .set(lessonInfo);
  }

  Future updateTopic(String schoolId, String classId, String subjectId,
      String lessonId, Map<String, dynamic> updateInfo) async {
    return await _firestore
        .collection("schools")
        .doc(schoolId)
        .collection("classes")
        .doc(classId)
        .collection("subjects")
        .doc(subjectId)
        .collection("lessons")
        .doc(lessonId)
        .update(updateInfo);
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

  Future<String> getSubjectName(
      String schoolId, String classId, String subjectId) async {
    DocumentSnapshot subjectDoc = await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .doc(classId)
        .collection('subjects')
        .doc(subjectId)
        .get();
    return subjectDoc['name'];
  }

  Future<String> getSubjectYear(
      String schoolId, String classId, String subjectId) async {
    DocumentSnapshot subjectDoc = await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .doc(classId)
        .collection('subjects')
        .doc(subjectId)
        .get();
    return subjectDoc['year'];
  }

  // ATTENDANCE

  Future<List<Map<String, dynamic>>> getStudentsAttendance(
      String schoolId, String classId, String subjectId) async {
    // Pobierz listę uczniów
    List<QueryDocumentSnapshot<Map<String, dynamic>>> studentsDocumentSnapshot =
        await getStudentsFromClass(schoolId, classId);

    Map<String, String> studentsMap = {};
    for (var studentDoc in studentsDocumentSnapshot) {
      var studentData = studentDoc.data();
      studentsMap[studentDoc.id] =
          "${studentData['name']} ${studentData['surname']}";
    }

    // Pobierz listę lekcji
    QuerySnapshot<Map<String, dynamic>> lessonsSnapshot = await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .doc(classId)
        .collection('subjects')
        .doc(subjectId)
        .collection('lessons')
        .orderBy('date', descending: true)
        .get();

    List<Map<String, dynamic>> studentsAttendance = [];

    for (var lessonDoc in lessonsSnapshot.docs) {
      var lessonData = lessonDoc.data();
      var lessonId = lessonDoc.id;
      var lessonDate = lessonData['date'];

      Map<String, dynamic> lessonEntry = {
        'lesson_id': lessonId,
        'date': lessonDate,
        'students': [],
      };

      // Pobierz obecności uczniów
      QuerySnapshot<Map<String, dynamic>> attendanceSnapshot =
          await lessonDoc.reference.collection('attendance').get();

      Map<String, String> attendanceMap = {}; // student_id -> status
      for (var attendanceDoc in attendanceSnapshot.docs) {
        var attendanceData = attendanceDoc.data();
        var studentId = attendanceData['student_id'];
        attendanceMap[studentId] = attendanceData['status'];
      }

      // Przypisz obecności do wszystkich uczniów
      studentsMap.forEach((studentId, studentName) {
        lessonEntry['students'].add({
          'student_id': studentId,
          'name': studentName,
          'attendance': attendanceMap[studentId] ?? 'Brak danych',
        });
      });

      studentsAttendance.add(lessonEntry);
    }

    return studentsAttendance;
  }

  Future<Map<String, dynamic>> getStudentAttendance(String studentId) async {
    Map<String, dynamic> attendanceData = {
      'Spóźniony': {},
      'Nieobecny': {},
    };

    // getUserDetailsById(studentId).then((value) {
    //   print(value.data());
    // });
    var student = await getUserDetailsById(studentId);
    var schoolRef = student['school_id'];
    var classRef = student['class_id'];
    var schoolId = schoolRef.id;
    var classId = classRef.id;
    String year = await schoolRef.get().then((value) => value['current_year']);

    // Pobierz listę przedmiotów
    QuerySnapshot<Map<String, dynamic>> subjectsSnapshot = await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .doc(classId)
        .collection('subjects')
        .where('year', isEqualTo: year)
        .get();

    // print("subjectsSnapshot: ${subjectsSnapshot.docs}");

    for (var subjectDoc in subjectsSnapshot.docs) {
      var subjectData = subjectDoc.data();
      var subjectName = subjectData['name'];

      // print("subjectName: $subjectName");

      // Pobierz listę lekcji
      QuerySnapshot<Map<String, dynamic>> lessonsSnapshot = await subjectDoc
          .reference
          .collection('lessons')
          .orderBy('date', descending: true)
          .get();

      for (var lessonDoc in lessonsSnapshot.docs) {
        var lessonData = lessonDoc.data();
        var lessonId = lessonDoc.id;
        var lessonDate = lessonData['date'];

        // Pobierz obecności ucznia
        QuerySnapshot<Map<String, dynamic>> attendanceSnapshot =
            await lessonDoc.reference.collection('attendance').get();

        // var attendanceEntry = attendanceSnapshot.docs.firstWhere(
        //   (element) => element['student_id'] == studentId,
        //   orElse: () => null,
        // );
        var attendanceDocs = attendanceSnapshot.docs.where(
          (element) => element['student_id'] == studentId,
        );

        var attendanceEntry =
            attendanceDocs.isNotEmpty ? attendanceDocs.first : null;

        // print("attendanceEntry: $attendanceEntry");

        if (attendanceEntry != null) {
          String status =
              attendanceEntry['status']; // np. "Spóźniony" lub "Nieobecny"
          bool isJustified = attendanceEntry['justified'] ?? false;

          if (status == 'Spóźniony' || status == 'Nieobecny') {
            if (!attendanceData[status].containsKey(lessonDate)) {
              attendanceData[status][lessonDate] = {};
            }
            if (!attendanceData[status][lessonDate].containsKey(subjectName)) {
              attendanceData[status][lessonDate][subjectName] = [];
            }

            attendanceData[status][lessonDate][subjectName].add({
              'lesson_id': lessonId,
              'justified': isJustified,
            });
          }
        }
      }
    }

    for (var status in ['Spóźniony', 'Nieobecny']) {
      var original = attendanceData[status] as Map;
      var sortedEntries = original.entries.toList()
        ..sort((a, b) => (a.key as Timestamp).compareTo(b.key as Timestamp));

      attendanceData[status] =
          Map.fromEntries(sortedEntries.reversed); // descending
    }

    return attendanceData;
  }

  //update attendance
  Future<void> updateStudentAttendance(
      String schoolId,
      String classId,
      String subjectId,
      String lessonId,
      String studentId,
      String status) async {
    return await _firestore
        .collection("schools")
        .doc(schoolId)
        .collection("classes")
        .doc(classId)
        .collection("subjects")
        .doc(subjectId)
        .collection("lessons")
        .doc(lessonId)
        .collection("attendance")
        .doc(studentId)
        .set({
      'status': status,
      'student_id': studentId,
      'justified': status == 'Nieobecny usprawiedliwiony' ? true : false
    });
  }

  Future<String> getStudentEducator(String studentId) async {
    DocumentReference classRef =
        (await _firestore.collection('users').doc(studentId).get())['class_id'];
    DocumentSnapshot classDoc = await classRef.get();
    String educatorId = classDoc['educator'];

    return educatorId;
  }

  Future<void> addExcuse(Map<String, dynamic> excuseInfo) async {
    String educatorId = await getStudentEducator(excuseInfo['student_id']);
    excuseInfo['educator_id'] = educatorId;

    return await _firestore.collection("excuses").doc().set(excuseInfo);
  }

  Future<void> approveExcuse(
      String excuseId, String studentId, String schoolId) async {
    final excuseRef = _firestore.collection('excuses').doc(excuseId);
    final studentRef = _firestore.collection('users').doc(studentId);

    final studentSnap = await studentRef.get();
    final excuseSnap = await excuseRef.get();

    final classId = studentSnap['class_id'].id;
    final excuseData = excuseSnap.data()!;
    final excuseDate = (excuseData['date'] as Timestamp).toDate();

    // Ustaw pole approved w usprawiedliwieniu
    await excuseRef.update({'approved': true});

    // wszystkie lekcje w klasie ucznia w danym dniu
    final classSubjectsRef = _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .doc(classId)
        .collection('subjects');

    final subjectsSnapshot = await classSubjectsRef.get();

    for (final subjectDoc in subjectsSnapshot.docs) {
      final lessonsRef = subjectDoc.reference.collection('lessons');
      final lessonsSnapshot = await lessonsRef
          .where('date', isEqualTo: Timestamp.fromDate(excuseDate))
          .get();

      for (final lessonDoc in lessonsSnapshot.docs) {
        final attendanceRef = lessonDoc.reference.collection('attendance');
        final attendanceSnapshot = await attendanceRef
            .where('student_id', isEqualTo: studentRef.id)
            .where('status', whereIn: ['Nieobecny', 'Spóźniony']).get();

        for (final attendanceDoc in attendanceSnapshot.docs) {
          await attendanceDoc.reference.update({'justified': true});
        }
      }
    }
  }

  // GRADES
  DocumentReference getSubjectRefenece(
      String schoolId, String classId, String subjectId) {
    return _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .doc(classId)
        .collection('subjects')
        .doc(subjectId);
  }

  Future<List<Map<String, dynamic>>> getSubjectGrades(
      String schoolId, String classId, String subjectId) async {
    List<Map<String, dynamic>> studentsGrades = [];

    DocumentReference subjectRef =
        getSubjectRefenece(schoolId, classId, subjectId);

    // Pobierz oceny dla danego przedmiotu
    QuerySnapshot<Map<String, dynamic>> gradesSnapshot = await FirebaseFirestore
        .instance
        .collection('grades')
        .where('subject_id', isEqualTo: subjectRef)
        .where('is_final', isEqualTo: false)
        .orderBy('date', descending: true)
        .get();

    // Mapowanie ocen do uczniów
    Map<String, Map<String, dynamic>> studentGradesMap = {};

    for (var gradeDoc in gradesSnapshot.docs) {
      var gradeData = gradeDoc.data();
      var studentRef = gradeData['student_id'] as DocumentReference;

      // Pobierz dane ucznia
      var studentDoc = await studentRef.get();
      var studentData = studentDoc.data() as Map<String, dynamic>;
      var firstName = studentData['name'];
      var lastName = studentData['surname'];
      var studentId = studentRef.id;

      if (!studentGradesMap.containsKey(studentId)) {
        studentGradesMap[studentId] = {
          'first_name': firstName,
          'last_name': lastName,
          'name': '$firstName $lastName',
          'student_id': studentId,
          'grades': {},
        };
      }

      var gradeType = gradeData['description'];
      studentGradesMap[studentId]!['grades'][gradeType] = {
        'value': gradeData['grade_value'],
        'weight': gradeData['weight'],
        'comment': gradeData['comment'],
        'grade_id': gradeDoc.id,
      };
    }

    // Przekształć mapę na listę i posortuj po nazwisku
    studentsGrades = studentGradesMap.values.toList()
      ..sort((a, b) =>
          (a['last_name'] as String).compareTo(b['last_name'] as String));

    return studentsGrades;
  }

  Future<List<Map<String, dynamic>>> getStudentsWithFinalGrades(
    String schoolId,
    String classId,
    String subjectId,
    String schoolYear,
  ) async {
    final studentsSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where(
          'class_id',
          isEqualTo: _firestore
              .collection('schools')
              .doc(schoolId)
              .collection('classes')
              .doc(classId),
        )
        .orderBy('surname', descending: false)
        .get();

    final gradesSnapshot = await _firestore
        .collection('grades')
        .where(
          'subject_id',
          isEqualTo: _firestore
              .collection('schools')
              .doc(schoolId)
              .collection('classes')
              .doc(classId)
              .collection('subjects')
              .doc(subjectId),
        )
        .where('school_year', isEqualTo: schoolYear)
        .where('is_final', isEqualTo: true)
        .get();

    // Mapujemy studentId → {grade_value, grade_id}
    final gradesMap = {
      for (var doc in gradesSnapshot.docs)
        (doc['student_id'] as DocumentReference).id: {
          'grade_value': doc['grade_value'] as String,
          'grade_id': doc.id,
        }
    };

    final result = <Map<String, dynamic>>[];
    for (var studentDoc in studentsSnapshot.docs) {
      final studentId = studentDoc.id;
      final gradeInfo = gradesMap[studentId];

      result.add({
        'student_id': studentDoc.reference,
        'name': '${studentDoc['name']} ${studentDoc['surname']}',
        'final_grade': gradeInfo?['grade_value'],
        'final_grade_id': gradeInfo?['grade_id'],
      });
    }

    return result;
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

  Stream<List<Map<String, dynamic>>> getAnnouncements(String schoolId) {
    return _firestore
        .collection('announcements')
        .where('school_id', isEqualTo: schoolId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              var data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Stream<List<Map<String, dynamic>>> getLatestAnnouncements(
      String schoolId, int maxAnnouncements) {
    final Trace myTrace = performance.newTrace("load_announcements_widget");
    myTrace.putAttribute("school_id", schoolId);
    myTrace.start();

    return _firestore
        .collection('announcements')
        .where('school_id', isEqualTo: schoolId)
        .orderBy('date', descending: true)
        .limit(maxAnnouncements)
        .snapshots()
        .map((snapshot) {
      var data = snapshot.docs.map((doc) {
        var docData = doc.data();
        docData['id'] = doc.id;
        return docData;
      }).toList();

      myTrace.stop(); // Stop trace dopiero po pobraniu danych

      return data;
    });
  }

  // FILES

  Future<List<Map<String, dynamic>>> getSubjectFiles(
      String schoolId, String classId, String subjectId) async {
    final querySnapshot = await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .doc(classId)
        .collection('subjects')
        .doc(subjectId)
        .collection('files')
        .orderBy('timestamp', descending: true)
        .get();

    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> saveFileMetadataToFirestore({
    required String schoolId,
    required String classId,
    required String subjectId,
    required String fileName,
    required String downloadUrl,
  }) async {
    await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .doc(classId)
        .collection('subjects')
        .doc(subjectId)
        .collection('files')
        .add({
      'name': fileName,
      'url': downloadUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteFileMetadataFromFirestore({
    required String schoolId,
    required String classId,
    required String subjectId,
    required String fileUrl,
  }) async {
    final collection = _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .doc(classId)
        .collection('subjects')
        .doc(subjectId)
        .collection('files');

    final query = await collection.where('url', isEqualTo: fileUrl).get();

    for (var doc in query.docs) {
      await doc.reference.delete();
    }
  }

// ASSIGNMENTS
  Future<void> addAssignment({
    required String schoolId,
    required String classId,
    required String subjectId,
    required String title,
    required String content,
    required DateTime dueDate,
  }) async {
    try {
      // Generuj nowe ID zadania
      final assignmentRef = _firestore.collection('assignments').doc();
      final assignmentId = assignmentRef.id;

      await assignmentRef.set({
        'school_id': schoolId,
        'class_id': classId,
        'subject_id': subjectId,
        'title': title,
        'content': content,
        'due_date': dueDate,
      });

      // Pobierz uczniów z klasy i dodaj zgłoszenia
      final students = await getStudentsFromClass(schoolId, classId);
      for (var studentDoc in students) {
        await addAssignmentSubmission(
          assignmentId: assignmentId,
          studentId: studentDoc.id,
        );
      }
    } catch (e) {
      throw Exception('Nie udało się dodać zadania: $e');
    }
  }

  Future<void> addAssignmentSubmission({
    required String assignmentId,
    required String studentId,
  }) async {
    try {
      await _firestore
          .collection('assignments')
          .doc(assignmentId)
          .collection('submissions')
          .doc(studentId)
          .set({
        'status': 'nieprzesłane', // Domyślny status – zadanie nieprzesłane
      });
    } catch (e) {
      throw Exception('Nie udało się dodać zgłoszenia: $e');
    }
  }

  Future<Map<String, dynamic>> getAssignments(
      String schoolId, String classId, String subjectId) async {
    Map<String, dynamic> assignmentsData = {};

    QuerySnapshot assignmentsRef = await _firestore
        .collection('assignments')
        .where('school_id', isEqualTo: schoolId)
        .where('class_id', isEqualTo: classId)
        .where('subject_id', isEqualTo: subjectId)
        .orderBy('due_date', descending: false)
        .get();

    for (var assignment in assignmentsRef.docs) {
      assignmentsData[assignment.id] = assignment['title'];
    }

    return assignmentsData;
  }

  Future<Map<String, dynamic>> getTask(String taskId) async {
    DocumentSnapshot taskDoc =
        await _firestore.collection('assignments').doc(taskId).get();
    return taskDoc.data() as Map<String, dynamic>;
  }

  Future<String> getTaskTitle(String taskId) {
    return _firestore
        .collection('assignments')
        .doc(taskId)
        .get()
        .then((value) => value['title']);
  }

  Future<Timestamp?> getTaskDueDate(String taskId) async {
    DocumentSnapshot taskDoc =
        await _firestore.collection('assignments').doc(taskId).get();
    return taskDoc['due_date'];
  }

  Future<Map<String, List<Map<String, String>>>> getStudentTasks(
      String studentId) async {
    Map<String, List<Map<String, String>>> tasksData = {};

    final subjects = await getStudentSubjects(studentId);

    for (var subject in subjects.entries) {
      String subjectName = subject.key;
      List<Map<String, String>> tasksList = [];

      QuerySnapshot assignmentsRef = await _firestore
          .collection('assignments')
          .where('subject_id', isEqualTo: subject.value['id'])
          .get();

      for (var assignment in assignmentsRef.docs) {
        var assignmentData = assignment.data();
        tasksList.add({
          'task_id': assignment.id,
          'title': assignmentData != null
              ? (assignmentData as Map<String, dynamic>)['title']
              : '',
        });
      }

      tasksData[subjectName] = tasksList;
    }
    return tasksData;
  }

  Future<List<Map<String, dynamic>>> getStudentsWithTaskStatus(
    String taskId, {
    String sortBy = 'name',
  }) async {
    // 1. Pobierz wszystkie submissions (każdy dokument ma student_id jako ID)
    final submissionsSnapshot = await _firestore
        .collection('assignments')
        .doc(taskId)
        .collection('submissions')
        .get();

    final List<Map<String, dynamic>> result = [];

    for (var submissionDoc in submissionsSnapshot.docs) {
      final studentId = submissionDoc.id;
      final status = submissionDoc.data()['status'] ?? 'nieprzesłane';

      // 2. Pobierz dane ucznia z kolekcji users
      final userDoc = await _firestore.collection('users').doc(studentId).get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        result.add({
          'firstName': userData['name'] ?? '',
          'lastName': userData['surname'] ?? '',
          'status': status,
          'studentId': studentId,
        });
      } else {
        result.add({
          'firstName': '[nieznany]',
          'lastName': '[użytkownik]',
          'status': status,
          'studentId': studentId,
        });
      }
    }

    if (sortBy == 'name') {
      result.sort((a, b) =>
          (a['lastName'] as String).compareTo(b['lastName'] as String));
    } else if (sortBy == 'status') {
      const order = {'przesłane': 0, 'nieprzesłane': 1, 'ocenione': 2};
      result.sort((a, b) =>
          (order[a['status']] ?? 3).compareTo(order[b['status']] ?? 3));
    }

    return result;
  }

  Future<Map<String, dynamic>> getSubmission(
      String taskId, String studentId) async {
    final submissionDoc = await _firestore
        .collection('assignments')
        .doc(taskId)
        .collection('submissions')
        .doc(studentId)
        .get();

    return submissionDoc.data() ?? {};
  }

  Future<void> updateSubmission({
    required String taskId,
    required String studentId,
    required String grade,
    required String comment,
  }) async {
    await _firestore
        .collection('assignments')
        .doc(taskId)
        .collection('submissions')
        .doc(studentId)
        .update({
      'grade': grade,
      'comment': comment,
      'status': 'ocenione',
    });
  }

  Future<void> updateSubmissionStudent({
    required String taskId,
    required String studentId,
    required Map<String, dynamic> submissionData,
  }) async {
    await _firestore
        .collection('assignments')
        .doc(taskId)
        .collection('submissions')
        .doc(studentId)
        .update(submissionData);
  }

  // SCHOOL ADMIN

  Future<void> addClassToSchool(
      String schoolId, String className, String educatorId) async {
    final classData = {
      'name': className,
      'educator': educatorId,
    };

    await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .add(classData);
  }

  Future<List<Map<String, dynamic>>> getClassesForSchool(
      String schoolId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .orderBy('name')
        .get();

    return snapshot.docs
        .map((doc) => {
              'id': doc.id,
              'name': doc['name'],
            })
        .toList();
  }

  Future<void> updateClassName(
      String schoolId, String classId, String newName) async {
    await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .doc(classId)
        .update({'name': newName});
  }

  Future<void> deleteClass(String schoolId, String classId) async {
    await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .doc(classId)
        .delete();
  }

  Future<List<Map<String, dynamic>>> getSubjectsForClass(
      String schoolId, String classId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .doc(classId)
        .collection('subjects')
        .get();

    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<void> addSubject(String schoolId, String classId, String name,
      String schoolYear, DocumentReference teacherId) async {
    await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .doc(classId)
        .collection('subjects')
        .add({
      'name': name,
      'year': schoolYear,
      'employee': teacherId,
    });
  }

  Future<void> updateSubject(String schoolId, String classId, String subjectId,
      String name, String year, DocumentReference teacherId) async {
    await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .doc(classId)
        .collection('subjects')
        .doc(subjectId)
        .update({
      'name': name,
      'year': year,
      'employee': teacherId,
    });
  }

  Future<void> deleteSubject(
      String schoolId, String classId, String subjectId) async {
    await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .doc(classId)
        .collection('subjects')
        .doc(subjectId)
        .delete();
  }

  Future<List<Map<String, dynamic>>> getTeachers(schoolId) async {
    DocumentReference schoolRef =
        _firestore.collection('schools').doc(schoolId);

    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'teacher')
        .where('school_id', isEqualTo: schoolRef)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'ref': doc.reference,
        'fullName': '${data['name']} ${data['surname']}',
      };
    }).toList();
  }

  Future<List<DocumentSnapshot>> getTeachersForSchool(String schoolId) async {
    try {
      DocumentReference schoolRef =
          _firestore.collection('schools').doc(schoolId);

      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('school_id', isEqualTo: schoolRef)
          .where('role', isEqualTo: 'teacher')
          .get();

      return querySnapshot.docs;
    } catch (e) {
      throw Exception('Nie udało się pobrać nauczycieli: $e');
    }
  }

  Future<String> getCurrentYear(String schoolId) async {
    DocumentSnapshot schoolDoc =
        await _firestore.collection('schools').doc(schoolId).get();
    return schoolDoc['current_year'];
  }

  Future<void> updateCurrentYear(String schoolId, String newYear) async {
    await _firestore
        .collection('schools')
        .doc(schoolId)
        .update({'current_year': newYear});
  }

  //TIMETABLE

  Future<void> addTimetableEntry(
    String schoolId,
    String classId,
    String subjectId,
    String day,
    String lessonNumber,
    String room,
  ) async {
    await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .doc(classId)
        .collection('subjects')
        .doc(subjectId)
        .collection('timetable')
        .add({
      'day': day,
      'lesson_number': lessonNumber,
      'room': room,
    });
  }

  Future<List<Map<String, dynamic>>> getTimetableEntries(
    String schoolId,
    String classId,
    String subjectId,
  ) async {
    final snapshot = await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .doc(classId)
        .collection('subjects')
        .doc(subjectId)
        .collection('timetable')
        .get();

    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<void> deleteTimetableEntry(
      String schoolId, String classId, String subjectId, String entryId) async {
    await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .doc(classId)
        .collection('subjects')
        .doc(subjectId)
        .collection('timetable')
        .doc(entryId)
        .delete();
  }

  Future<Map<int, Map<String, String>>> getLessonTimes(String schoolId) async {
    final doc = await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('settings')
        .doc('lessonTimes')
        .get();

    if (!doc.exists) return {};
    final data = doc.data()!;
    return data.map((key, value) =>
        MapEntry(int.parse(key), Map<String, String>.from(value)));
  }

  Future<void> updateLessonTimes(
      String schoolId, Map<int, Map<String, String>> times) async {
    final converted =
        times.map((key, value) => MapEntry(key.toString(), value));
    await FirebaseFirestore.instance
        .collection('schools')
        .doc(schoolId)
        .collection('settings')
        .doc('lessonTimes')
        .set(converted);
  }

  Future<Map<String, dynamic>> getTeacherTimetableMatrix({
    required String schoolId,
    required String teacherId,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final lessonTimesDoc = await firestore
        .collection('schools')
        .doc(schoolId)
        .collection('settings')
        .doc('lessonTimes')
        .get();

    final lessonTimes = lessonTimesDoc.data() ?? {};

    final daysOfWeek = [
      'Poniedziałek',
      'Wtorek',
      'Środa',
      'Czwartek',
      'Piątek'
    ];
    final timetableMatrix = <String, Map<String, Map<String, dynamic>>>{};

    for (final day in daysOfWeek) {
      timetableMatrix[day] = {};
    }

    final classesSnapshot = await firestore
        .collection('schools')
        .doc(schoolId)
        .collection('classes')
        .get();

    for (final classDoc in classesSnapshot.docs) {
      final classId = classDoc.id;
      final className = classDoc.data()['name'] ?? classId;

      final subjectsSnapshot = await firestore
          .collection('schools')
          .doc(schoolId)
          .collection('classes')
          .doc(classId)
          .collection('subjects')
          .where('employee',
              isEqualTo: firestore.collection('users').doc(teacherId))
          .where('year', isEqualTo: await getCurrentYear(schoolId))
          .get();

      for (final subjectDoc in subjectsSnapshot.docs) {
        final subjectId = subjectDoc.id;
        final subjectName = subjectDoc.data()['name'] ?? 'Przedmiot';

        final timetableSnapshot = await firestore
            .collection('schools')
            .doc(schoolId)
            .collection('classes')
            .doc(classId)
            .collection('subjects')
            .doc(subjectId)
            .collection('timetable')
            .get();

        for (final doc in timetableSnapshot.docs) {
          final data = doc.data();
          final day = data['day'] ?? '';
          final lessonNum = data['lesson_number'];
          final room = data['room'] ?? '';

          if (!daysOfWeek.contains(day)) continue;

          timetableMatrix[day]![lessonNum.toString()] = {
            'subject': subjectName,
            'room': room,
            'className': className,
          };
        }
      }
    }

    return {
      'lessonTimes': lessonTimes,
      'timetableMatrix': timetableMatrix,
    };
  }

  // SUPER ADMIN

  Future<Map<String, dynamic>> getSchoolsWithDetails() async {
    final snapshot = await _firestore.collection('schools').get();
    return {
      for (var doc in snapshot.docs) doc.id: doc.data(),
    };
  }

  Future<void> addSchool(Map<String, dynamic> data) async {
    final schoolRef = await _firestore.collection('schools').add(data);
    final schoolId = schoolRef.id;

    final defaultLessonTimes = {
      '1': {'start': '08:00', 'end': '08:45'},
      '2': {'start': '08:55', 'end': '09:40'},
      '3': {'start': '09:50', 'end': '10:35'},
      '4': {'start': '10:45', 'end': '11:30'},
      '5': {'start': '11:40', 'end': '12:25'},
      '6': {'start': '12:45', 'end': '13:30'},
      '7': {'start': '13:40', 'end': '14:25'},
      '8': {'start': '14:35', 'end': '15:20'},
      '9': {'start': '15:30', 'end': '16:15'},
    };

    await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('settings')
        .doc('lessonTimes')
        .set(defaultLessonTimes);
  }

  Future<void> updateSchool(String id, Map<String, dynamic> data) async {
    await _firestore.collection('schools').doc(id).update(data);
  }

  Future<void> deleteSchool(String id) async {
    await _firestore.collection('schools').doc(id).delete();
  }
}
