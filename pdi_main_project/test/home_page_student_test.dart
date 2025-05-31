import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdi_main_project/pages/student/attendance_page.dart';
import 'package:pdi_main_project/pages/student/home_page_student.dart';
import 'package:pdi_main_project/pages/student/grades_page.dart';
import 'package:pdi_main_project/pages/announcements_page.dart';
import 'package:pdi_main_project/pages/student/timetable_page.dart';
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
      home: HomePageStudent(
        currentUserUid: 'testUserUid',
        schoolId: 'testSchoolId',
        databaseMethods: mockDatabaseMethods,
      ),
    );
  }

  testWidgets('Displays loading indicator while waiting for announcements',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getLatestAnnouncements(any(), any()))
        .thenAnswer((_) => Stream.value([]));

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('Displays message when no announcements are available',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getLatestAnnouncements(any(), any()))
        .thenAnswer((_) => Stream.value([]));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Brak ogłoszeń'), findsOneWidget);
  });

  testWidgets('Displays announcements when data is loaded successfully',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getLatestAnnouncements(any(), any()))
        .thenAnswer((_) => Stream.value([
              {
                'title': 'Test Announcement',
                'content': 'Test Content',
                'date': Timestamp.now(),
              }
            ]));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Test Announcement'), findsOneWidget);
    expect(find.text('Test Content'), findsOneWidget);
  });

  testWidgets('Navigates to GradesPage when "Oceny" menu item is tapped',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getLatestAnnouncements(any(), any()))
        .thenAnswer((_) => Stream.value([
              {
                'title': 'Test Announcement',
                'content': 'Test Content',
                'date': Timestamp.now(),
              }
            ]));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Oceny'));
    await tester.pumpAndSettle();

    expect(find.byType(GradesPage), findsOneWidget);
  });

  testWidgets(
      'Navigates to AnnouncementsPage when "Ogłoszenia" menu item is tapped',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getLatestAnnouncements(any(), any()))
        .thenAnswer((_) => Stream.value([
              {
                'title': 'Test Announcement',
                'content': 'Test Content',
                'date': Timestamp.now(),
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

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ogłoszenia'));
    await tester.pumpAndSettle();

    expect(find.byType(AnnouncementsPage), findsOneWidget);
  });

  testWidgets('Drawer contains all expected menu items',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getLatestAnnouncements(any(), any()))
        .thenAnswer((_) => Stream.value([]));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final scaffoldState =
        tester.firstState<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('Oceny'), findsOneWidget);
    expect(find.text('Plan zajęć'), findsOneWidget);
    expect(find.text('Frekwencja'), findsOneWidget);
    expect(find.text('Ogłoszenia'), findsOneWidget);
  });

  testWidgets(
      'Navigates to TimetablePage when "Plan zajęć" menu item is tapped',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getLatestAnnouncements(any(), any()))
        .thenAnswer((_) => Stream.value([]));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final scaffoldState =
        tester.firstState<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Plan zajęć'));
    await tester.pumpAndSettle();

    expect(find.byType(TimetablePage), findsOneWidget);
  });

  testWidgets(
      'Navigates to AttendancePage when "Frekwencja" menu item is tapped',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getLatestAnnouncements(any(), any()))
        .thenAnswer((_) => Stream.value([]));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final scaffoldState =
        tester.firstState<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Frekwencja'));
    await tester.pumpAndSettle();

    expect(find.byType(AttendancePage), findsOneWidget);
  });
}
