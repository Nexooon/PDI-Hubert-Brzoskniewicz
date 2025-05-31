import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdi_main_project/pages/student/timetable_page.dart';
import 'package:pdi_main_project/service/database.dart';

class MockDatabaseMethods extends Mock implements DatabaseMethods {}

void main() {
  late MockDatabaseMethods mockDatabaseMethods;

  setUp(() {
    mockDatabaseMethods = MockDatabaseMethods();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: TimetablePage(
        schoolId: 'testSchoolId',
        studentId: 'testStudentId',
        databaseMethods: mockDatabaseMethods,
      ),
    );
  }

  testWidgets('Displays loading indicator while waiting for timetable data',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getStudentClass(any())).thenAnswer(
        (_) async =>
            Future.delayed(const Duration(seconds: 1), () => 'classA'));

    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('Handles missing class gracefully', (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getStudentClass(any()))
        .thenAnswer((_) async => "");

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('Plan zajęć'), findsOneWidget);
  });

  testWidgets('Displays timetable table with lesson and subject data',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getStudentClass(any()))
        .thenAnswer((_) async => 'classA');

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TimetablePage(
              schoolId: 'testSchoolId',
              studentId: 'testStudentId',
              databaseMethods: mockDatabaseMethods,
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Plan zajęć'), findsOneWidget);
    expect(find.text('Lekcja'), findsOneWidget);
    expect(find.text('Poniedziałek'), findsOneWidget);
    expect(find.text('Wtorek'), findsOneWidget);
    expect(find.text('Środa'), findsOneWidget);
    expect(find.text('Czwartek'), findsOneWidget);
    expect(find.text('Piątek'), findsOneWidget);
  });
}
