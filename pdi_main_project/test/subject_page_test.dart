import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdi_main_project/pages/teacher/subject_page.dart';
import 'package:pdi_main_project/pages/teacher/teacher_grades_page.dart';
import 'package:pdi_main_project/pages/teacher/teacher_attendance_page.dart';
import 'package:pdi_main_project/pages/teacher/students_tasks_page.dart';
import 'package:pdi_main_project/pages/student/task_page_student.dart';
import 'package:pdi_main_project/service/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MockDatabaseMethods extends Mock implements DatabaseMethods {}

void main() {
  late MockDatabaseMethods mockDatabaseMethods;

  setUp(() {
    mockDatabaseMethods = MockDatabaseMethods();
    when(() => mockDatabaseMethods.getSubjectName(any(), any(), any()))
        .thenAnswer((_) async => 'Matematyka');
    when(() => mockDatabaseMethods.getClassName(any(), any()))
        .thenAnswer((_) async => '1A');
    when(() => mockDatabaseMethods.getSubjectYear(any(), any(), any()))
        .thenAnswer((_) async => '2023/2024');
    when(() => mockDatabaseMethods.getLessonTopics(any(), any(), any()))
        .thenAnswer((_) async => {});
    when(() => mockDatabaseMethods.getAssignments(any(), any(), any()))
        .thenAnswer((_) async => {});
    when(() => mockDatabaseMethods.getSubjectFiles(any(), any(), any()))
        .thenAnswer((_) async => []);
    when(() => mockDatabaseMethods.getSubjectGrades(any(), any(), any()))
        .thenAnswer((_) async => []);
    when(() => mockDatabaseMethods.getStudentAttendance(any()))
        .thenAnswer((_) async => {});
    when(() => mockDatabaseMethods.getStudentsAttendance(any(), any(), any()))
        .thenAnswer((_) async => []);
  });

  Widget createWidgetUnderTest({String role = 'teacher'}) {
    return MaterialApp(
      home: SubjectPage(
        schoolId: 'testSchoolId',
        classId: 'testClassId',
        subjectId: 'testSubjectId',
        currentUserRole: role,
        currentUserUid: 'testUserUid',
        databaseMethods: mockDatabaseMethods,
      ),
    );
  }

  testWidgets('Displays subject and class name for teacher', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Klasa: 1A'), findsOneWidget);
    expect(find.text('Przedmiot: Matematyka'), findsOneWidget);
    expect(find.text('Strona przedmiotowa'), findsOneWidget);
  });

  testWidgets('Displays management buttons for teacher', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Zarządzaj ocenami'), findsOneWidget);
    expect(find.text('Zarządzaj frekwencją'), findsOneWidget);
  });

  testWidgets(
      'Navigates to TeacherGradesPage when "Zarządzaj ocenami" is tapped',
      (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Zarządzaj ocenami'));
    await tester.pumpAndSettle();

    expect(find.byType(TeacherGradesPage), findsOneWidget);
  });

  testWidgets(
      'Navigates to TeacherAttendancePage when "Zarządzaj frekwencją" is tapped',
      (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Zarządzaj frekwencją'));
    await tester.pumpAndSettle();

    expect(find.byType(TeacherAttendancePage), findsOneWidget);
  });

  testWidgets('Displays "Brak zadań" when no tasks', (tester) async {
    when(() => mockDatabaseMethods.getAssignments(any(), any(), any()))
        .thenAnswer((_) async => {});
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Brak zadań'), findsOneWidget);
  });

  testWidgets(
      'Displays tasks and navigates to StudentsTasksPage on tap (teacher)',
      (tester) async {
    when(() => mockDatabaseMethods.getAssignments(any(), any(), any()))
        .thenAnswer((_) async => {'task1': 'Zadanie 1'});
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Zadanie 1'), findsOneWidget);

    await tester.tap(find.text('Zadanie 1'));
    await tester.pumpAndSettle();

    expect(find.byType(StudentsTasksPage), findsOneWidget);
  });

  testWidgets('Displays "Brak plików" when no files', (tester) async {
    when(() => mockDatabaseMethods.getSubjectFiles(any(), any(), any()))
        .thenAnswer((_) async => []);
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Brak plików'), findsOneWidget);
  });

  testWidgets('Displays files section with file name', (tester) async {
    when(() => mockDatabaseMethods.getSubjectFiles(any(), any(), any()))
        .thenAnswer((_) async => [
              {'name': 'plik1.pdf', 'url': 'http://example.com/plik1.pdf'}
            ]);
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('plik1.pdf'), findsOneWidget);
    expect(find.byIcon(Icons.download), findsOneWidget);
  });

  testWidgets('Displays "Brak tematów" when no topics', (tester) async {
    when(() => mockDatabaseMethods.getLessonTopics(any(), any(), any()))
        .thenAnswer((_) async => {});
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Brak tematów'), findsOneWidget);
  });

  testWidgets('Displays topics section with topic name', (tester) async {
    when(() => mockDatabaseMethods.getLessonTopics(any(), any(), any()))
        .thenAnswer((_) async => {
              'topic1': {
                'topic': 'Temat 1',
                'date': Timestamp.fromDate(DateTime(2023, 5, 10))
              }
            });
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Temat 1'), findsOneWidget);
    expect(find.textContaining('Data:'), findsOneWidget);
    expect(find.byIcon(Icons.edit), findsOneWidget);
  });

  testWidgets('Student does not see management buttons', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(role: 'student'));
    await tester.pumpAndSettle();

    expect(find.text('Zarządzaj ocenami'), findsNothing);
    expect(find.text('Zarządzaj frekwencją'), findsNothing);
  });

  testWidgets('Student navigates to TaskPageStudent on task tap',
      (tester) async {
    when(() => mockDatabaseMethods.getAssignments(any(), any(), any()))
        .thenAnswer((_) async => {'task1': 'Zadanie 1'});
    when(() => mockDatabaseMethods.getSubmission(any(), any()))
        .thenAnswer((_) async => {'status': 'not_submitted'});
    when(() => mockDatabaseMethods.getTask(any())).thenAnswer((_) async => {
          'task1': {
            'title': 'Zadanie 1',
            'description': 'Opis zadania 1',
            'dueDate': Timestamp.fromDate(DateTime(2023, 5, 20))
          }
        });
    await tester.pumpWidget(createWidgetUnderTest(role: 'student'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Zadanie 1'));
    await tester.pumpAndSettle();

    expect(find.byType(TaskPageStudent), findsOneWidget);
  });
}
