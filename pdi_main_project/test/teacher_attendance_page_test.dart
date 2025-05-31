import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdi_main_project/pages/teacher/teacher_attendance_page.dart';
import 'package:pdi_main_project/service/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Mock classes
class MockDatabaseMethods extends Mock implements DatabaseMethods {}

void main() {
  late MockDatabaseMethods mockDatabaseMethods;

  setUp(() {
    mockDatabaseMethods = MockDatabaseMethods();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: TeacherAttendancePage(
        schoolId: 'testSchoolId',
        classId: 'testClassId',
        subjectId: 'testSubjectId',
        subjectName: 'Mathematics',
        databaseMethods: mockDatabaseMethods,
      ),
    );
  }

  testWidgets('Displays loading indicator while waiting for attendance data',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getStudentsAttendance(any(), any(), any()))
        .thenAnswer(
            (_) async => Future.delayed(const Duration(seconds: 2), () => []));

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('Displays message when no lessons are available',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getStudentsAttendance(any(), any(), any()))
        .thenAnswer((_) async => []);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Brak lekcji.'), findsOneWidget);
  });

  testWidgets('Displays attendance data when data is loaded successfully',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getStudentsAttendance(any(), any(), any()))
        .thenAnswer((_) async => [
              {
                'lesson_id': 'lesson1',
                'date': Timestamp.fromDate(DateTime(2023, 3, 10)),
                'students': [
                  {
                    'student_id': 'student1',
                    'name': 'John Doe',
                    'attendance': 'Obecny'
                  },
                  {
                    'student_id': 'student2',
                    'name': 'Jane Smith',
                    'attendance': 'Nieobecny'
                  },
                ],
              },
            ]);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('Jane Smith'), findsOneWidget);
    expect(find.text('Obecny'), findsOneWidget);
    expect(find.text('Nieobecny'), findsOneWidget);
  });

  testWidgets('Saves attendance changes when save button is tapped',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getStudentsAttendance(any(), any(), any()))
        .thenAnswer((_) async => [
              {
                'lesson_id': 'lesson1',
                'date': Timestamp.fromDate(DateTime(2023, 3, 10)),
                'students': [
                  {
                    'student_id': 'student1',
                    'name': 'John Doe',
                    'attendance': 'Obecny'
                  },
                ],
              },
            ]);

    when(() => mockDatabaseMethods.updateStudentAttendance(
          any(),
          any(),
          any(),
          any(),
          any(),
          any(),
        )).thenAnswer((_) async => Future.value());

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Change attendance
    await tester.tap(find.text('Obecny'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nieobecny').last);
    await tester.pumpAndSettle();

    // Tap save button
    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();

    // Verify that the updateStudentAttendance method was called
    verify(() => mockDatabaseMethods.updateStudentAttendance(
          'testSchoolId',
          'testClassId',
          'testSubjectId',
          'lesson1',
          'student1',
          'Nieobecny',
        )).called(1);
  });
}
