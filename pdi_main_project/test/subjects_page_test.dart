import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdi_main_project/pages/teacher/subjects_page.dart';
import 'package:pdi_main_project/pages/teacher/subject_page.dart';
import 'package:pdi_main_project/service/database.dart';

// Mock classes
class MockDatabaseMethods extends Mock implements DatabaseMethods {}

void main() {
  late MockDatabaseMethods mockDatabaseMethods;

  setUp(() {
    mockDatabaseMethods = MockDatabaseMethods();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: SubjectsPage(
        teacherId: 'testTeacherId',
        databaseMethods: mockDatabaseMethods,
      ),
    );
  }

  testWidgets('Displays loading indicator while waiting for data',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getTeacherSubjects(any())).thenAnswer(
        (_) async => Future.delayed(const Duration(seconds: 2), () => {}));

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('Displays error message when data loading fails',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getTeacherSubjects(any()))
        .thenThrow(Exception('Test error'));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.textContaining('Błąd: '), findsOneWidget);
  });

  testWidgets('Displays message when no subjects are available',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getTeacherSubjects(any()))
        .thenAnswer((_) async => {});

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Brak przedmiotów'), findsOneWidget);
  });

  testWidgets('Displays subjects when data is loaded successfully',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getTeacherSubjects(any())).thenAnswer(
      (_) async => {
        'School A': {
          'Class 1': [
            {
              'name': 'Mathematics',
              'schoolId': 'schoolA',
              'classId': 'class1',
              'id': 'math1'
            },
            {
              'name': 'Physics',
              'schoolId': 'schoolA',
              'classId': 'class1',
              'id': 'phys1'
            },
          ],
        },
        'School B': {
          'Class 2': [
            {
              'name': 'Chemistry',
              'schoolId': 'schoolB',
              'classId': 'class2',
              'id': 'chem1'
            },
          ],
        },
      },
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('School A'), findsOneWidget);
    await tester.tap(find.text('School A'));
    await tester.pumpAndSettle();

    expect(find.text('Class 1'), findsOneWidget);
    await tester.tap(find.text('Class 1'));
    await tester.pumpAndSettle();

    expect(find.text('Mathematics'), findsOneWidget);
    expect(find.text('Physics'), findsOneWidget);

    expect(find.text('School B'), findsOneWidget);
    await tester.tap(find.text('School B'));
    await tester.pumpAndSettle();

    expect(find.text('Class 2'), findsOneWidget);
    await tester.tap(find.text('Class 2'));
    await tester.pumpAndSettle();

    expect(find.text('Chemistry'), findsOneWidget);
  });

  testWidgets('Navigates to SubjectPage when a subject is tapped',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getTeacherSubjects(any())).thenAnswer(
      (_) async => {
        'School A': {
          'Class 1': [
            {
              'name': 'Mathematics',
              'schoolId': 'schoolA',
              'classId': 'class1',
              'id': 'math1'
            },
          ],
        },
      },
    );

    when(() => mockDatabaseMethods.getSubjectName(any(), any(), any()))
        .thenAnswer((_) async => 'Mathematics');
    when(() => mockDatabaseMethods.getClassName(any(), any()))
        .thenAnswer((_) async => 'class1');
    when(() => mockDatabaseMethods.getSubjectYear(any(), any(), any()))
        .thenAnswer((_) async => '2024/2025');
    when(() => mockDatabaseMethods.getAssignments(any(), any(), any()))
        .thenAnswer((_) async => {});
    when(() => mockDatabaseMethods.getSubjectFiles(any(), any(), any()))
        .thenAnswer((_) async => []);

    when(() => mockDatabaseMethods.getLessonTopics(any(), any(), any()))
        .thenAnswer(
      (_) async => {
        'lessonId1': {
          'topic': 'Algebra',
          'date': Timestamp.now(),
        },
        'lessonId2': {
          'topic': 'Geometry',
          'date': Timestamp.now(),
        },
      },
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.text('School A'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Class 1'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mathematics'));
    await tester.pumpAndSettle();

    expect(find.byType(SubjectPage), findsOneWidget);
  });
}
