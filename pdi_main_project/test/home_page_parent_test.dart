import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdi_main_project/pages/parent/home_page_parent.dart';
import 'package:pdi_main_project/pages/announcements_page.dart';
import 'package:pdi_main_project/pages/student/grades_page.dart';
import 'package:pdi_main_project/pages/student/attendance_page.dart';
import 'package:pdi_main_project/service/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Mock classes
class MockDatabaseMethods extends Mock implements DatabaseMethods {}

void main() {
  late MockDatabaseMethods mockDatabaseMethods;

  setUp(() {
    mockDatabaseMethods = MockDatabaseMethods();
    Firebase.initializeApp();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: HomePageParent(
        currentUserUid: 'testUserUid',
        schoolId: 'testSchoolId',
        databaseMethods: mockDatabaseMethods,
      ),
    );
  }

  testWidgets('Displays loading indicator while waiting for data',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getChildren(any())).thenAnswer(
        (_) async => Future.delayed(const Duration(seconds: 2), () => {}));

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('Displays error message when data loading fails',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getChildren(any()))
        .thenThrow(Exception('Test error'));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();
    // await tester.pump();
    // await tester.pump();

    expect(find.textContaining('Błąd: '), findsOneWidget);
  });

  testWidgets('Displays message when there are no children',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getChildren(any()))
        .thenAnswer((_) async => {});
    when(() => mockDatabaseMethods.getLatestAnnouncements(any(), any()))
        .thenAnswer((_) => Stream.value([
              {
                'title': 'Test announcement',
                'content': 'Test content',
                'date': Timestamp.now()
              }
            ]));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Brak danych o dzieciach'), findsOneWidget);
  });

  testWidgets('Displays children list when data is loaded successfully',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getChildren(any())).thenAnswer(
        (_) async => {'child1': 'Child One', 'child2': 'Child Two'});
    when(() => mockDatabaseMethods.getLatestAnnouncements(any(), any()))
        .thenAnswer((_) => Stream.value([
              {
                'title': 'Test announcement',
                'content': 'Test content',
                'date': Timestamp.now()
              }
            ]));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Child One'), findsOneWidget);
    expect(find.text('Child Two'), findsOneWidget);
  });

  testWidgets('Navigates to GradesPage when "Oceny" button is tapped',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getChildren(any()))
        .thenAnswer((_) async => {'child1': 'Child One'});
    when(() => mockDatabaseMethods.getLatestAnnouncements(any(), any()))
        .thenAnswer((_) => Stream.value([
              {
                'title': 'Test announcement',
                'content': 'Test content',
                'date': Timestamp.now()
              }
            ]));
    when(() => mockDatabaseMethods.getStudentGrades(any()))
        .thenAnswer((_) async => [
              {
                'school_year': '2022/2023',
                'subject_name': 'Mathematics',
                'grade_value': '5',
                'description': 'Excellent performance',
                'date': Timestamp.now(),
                'is_final': true
              }
            ]);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Oceny'));
    await tester.pumpAndSettle();

    expect(find.byType(GradesPage), findsOneWidget);
  });

  testWidgets('Navigates to AttendancePage when "Frekwencja" button is tapped',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getChildren(any()))
        .thenAnswer((_) async => {'child1': 'Child One'});
    when(() => mockDatabaseMethods.getLatestAnnouncements(any(), any()))
        .thenAnswer((_) => Stream.value([
              {
                'title': 'Test announcement',
                'content': 'Test content',
                'date': Timestamp.now()
              }
            ]));
    when(() => mockDatabaseMethods.getStudentAttendance(any()))
        .thenAnswer((_) async => {
              "Spóźniony": {
                Timestamp.now(): {
                  "Matematyka": [
                    {"lesson_id": "lesson123", "justified": false}
                  ],
                  "Fizyka": [
                    {"lesson_id": "lesson456", "justified": true}
                  ]
                },
                Timestamp.now(): {
                  "Informatyka": [
                    {"lesson_id": "lesson789", "justified": false}
                  ]
                }
              },
              "Nieobecny": {
                Timestamp.now(): {
                  "Historia": [
                    {"lesson_id": "lesson101", "justified": false}
                  ]
                },
                Timestamp.fromDate(DateTime(2025, 3, 10)): {
                  "Język Angielski": [
                    {"lesson_id": "lesson202", "justified": true}
                  ]
                }
              }
            });

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Frekwencja'));
    await tester.pumpAndSettle();

    expect(find.byType(AttendancePage), findsOneWidget);
  });

  testWidgets(
      'Navigates to AnnouncementsPage when "Ogłoszenia" button is tapped',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getChildren(any()))
        .thenAnswer((_) async => {'child1': 'Child One'});
    when(() => mockDatabaseMethods.getLatestAnnouncements(any(), any()))
        .thenAnswer((_) => Stream.value([
              {
                'title': 'Test announcement',
                'content': 'Test content',
                'date': Timestamp.now()
              }
            ]));
    when(() => mockDatabaseMethods.getAnnouncements(any()))
        .thenAnswer((_) => Stream.value([
              {
                'title': 'Test announcement',
                'content': 'Test content',
                'date': Timestamp.now()
              }
            ]));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Strona ogłoszeń'));
    await tester.pumpAndSettle();
    expect(find.byType(AnnouncementsPage), findsOneWidget);

    // expect(find.text("Rodzic - strona główna"), findsOneWidget);
    // expect(find.text("Test announcement"), findsOneWidget);
  });
}
