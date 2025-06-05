import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdi_main_project/pages/student/grades_page.dart';
import 'package:pdi_main_project/service/database.dart';

// Mock classes
class MockDatabaseMethods extends Mock implements DatabaseMethods {}

void main() {
  late MockDatabaseMethods mockDatabaseMethods;

  setUp(() {
    mockDatabaseMethods = MockDatabaseMethods();

    // Register fallback values for Mocktail
    registerFallbackValue(FakeBuildContext());
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: GradesPage(
        currentUserUid: 'testUserUid',
        schoolId: 'testSchoolId',
        databaseMethods: mockDatabaseMethods,
      ),
    );
  }

  testWidgets('Displays loading indicator while waiting for data',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getStudentGrades(any())).thenAnswer(
        (_) async => Future.delayed(const Duration(seconds: 2), () => []));

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('Displays error message when data loading fails',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getStudentGrades(any()))
        .thenThrow(Exception('Test error'));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.textContaining('Błąd: '), findsOneWidget);
  });

  testWidgets('Displays message when no grades are available',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getStudentGrades(any()))
        .thenAnswer((_) async => []);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Brak ocen do wyświetlenia.'), findsOneWidget);
  });

  testWidgets('Displays grades when data is loaded successfully',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getStudentGrades(any())).thenAnswer(
      (_) async => [
        {
          'school_year': '2022/2023',
          'subject_name': 'Mathematics',
          'grade_value': '5',
          'description': 'Excellent performance',
          'date': Timestamp.now(),
          'is_final': false
        },
        {
          'school_year': '2022/2023',
          'subject_name': 'Physics',
          'grade_value': '4',
          'description': 'Good performance',
          'date': Timestamp.now(),
          'is_final': true
        },
      ],
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('2022/2023'), findsOneWidget);
    expect(find.text('Mathematics'), findsOneWidget);
    expect(find.text('Physics'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('Displays grade details dialog when a grade is tapped',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getStudentGrades(any())).thenAnswer(
      (_) async => [
        {
          'school_year': '2022/2023',
          'subject_name': 'Mathematics',
          'grade_value': '5',
          'description': 'Excellent performance',
          'date': Timestamp.now(),
          'is_final': false
        },
      ],
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();

    expect(find.text('Szczegóły oceny'), findsOneWidget);
    expect(find.text('Ocena: 5'), findsOneWidget);
    expect(find.text('Opis: Excellent performance'), findsOneWidget);
  });
}

// Fake class for BuildContext
class FakeBuildContext extends Fake implements BuildContext {}
