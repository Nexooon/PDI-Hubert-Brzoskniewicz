import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdi_main_project/pages/teacher/teacher_grades_page.dart';
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
      home: TeacherGradesPage(
        schoolId: 'testSchoolId',
        classId: 'testClassId',
        subjectId: 'testSubjectId',
        subjectName: 'Mathematics',
        year: '2022/2023',
        databaseMethods: mockDatabaseMethods,
      ),
    );
  }

  testWidgets('Displays loading indicator while waiting for grades data',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getSubjectGrades(any(), any(), any()))
        .thenAnswer(
            (_) async => Future.delayed(const Duration(seconds: 2), () => []));

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('Displays message when no grades are available',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getSubjectGrades(any(), any(), any()))
        .thenAnswer((_) async => []);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Brak ocen'), findsOneWidget);
  });

  testWidgets('Displays grades when data is loaded successfully',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getSubjectGrades(any(), any(), any()))
        .thenAnswer(
      (_) async => [
        {
          'name': 'Jan Kowalski',
          'student_id': 'student1',
          'grades': {
            'exam': {'value': '5', 'weight': 3, 'grade_id': 'grade1'},
            'homework': {'value': '4', 'weight': 2, 'grade_id': 'grade2'},
          },
        },
        {
          'name': 'Anna Nowak',
          'student_id': 'student2',
          'grades': {
            'exam': {'value': '4+', 'weight': 3, 'grade_id': 'grade3'},
          },
        },
      ],
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Jan Kowalski'), findsOneWidget);
    expect(find.text('Anna Nowak'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('4+'), findsOneWidget);
  });

  testWidgets('Adds a new grade type', (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getSubjectGrades(any(), any(), any()))
        .thenAnswer(
      (_) async => [
        {
          'name': 'Jan Kowalski',
          'student_id': 'student1',
          'grades': {
            'exam': {'value': '5', 'weight': 3, 'grade_id': 'grade1'},
            'homework': {'value': '4', 'weight': 2, 'grade_id': 'grade2'},
          },
        },
        {
          'name': 'Anna Nowak',
          'student_id': 'student2',
          'grades': {
            'exam': {'value': '4+', 'weight': 3, 'grade_id': 'grade3'},
          },
        },
      ],
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Project');
    await tester.tap(find.text('Dodaj'));
    await tester.pumpAndSettle();

    expect(find.text('Project'), findsOneWidget);
  });

  testWidgets('Edits a column weight', (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getSubjectGrades(any(), any(), any()))
        .thenAnswer(
      (_) async => [
        {
          'name': 'Jan Kowalski',
          'student_id': 'student1',
          'grades': {
            'exam': {'value': '5', 'weight': 3, 'grade_id': 'grade1'},
          },
        },
      ],
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit).first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '5');
    await tester.tap(find.text('Zapisz'));
    await tester.pumpAndSettle();

    verify(() => mockDatabaseMethods.updateGrade('grade1', any())).called(1);
  });
}
