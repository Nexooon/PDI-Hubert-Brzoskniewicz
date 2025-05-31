import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdi_main_project/pages/teacher/home_page_teacher.dart';
import 'package:pdi_main_project/pages/announcements_page.dart';
import 'package:pdi_main_project/pages/teacher/subjects_page.dart';
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
      home: HomePageTeacher(
        currentUserUid: 'testTeacherUid',
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

    expect(find.byType(CircularProgressIndicator), findsWidgets);

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

  testWidgets('Navigates to AnnouncementsPage when "Ogłoszenia" is tapped',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getLatestAnnouncements(any(), any()))
        .thenAnswer((_) => Stream.value([]));

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

  testWidgets('Navigates to SubjectsPage when "Strony przedmiotowe" is tapped',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getLatestAnnouncements(any(), any()))
        .thenAnswer((_) => Stream.value([]));

    when(() => mockDatabaseMethods.getTeacherSubjects(any()))
        .thenAnswer((_) => Future.value({
              'Test School': {
                'Test Class': [
                  {
                    'id': 'testSubjectId',
                    'name': 'Test Subject',
                    'schoolId': 'testSchoolId',
                    'classId': 'testClassId',
                  }
                ]
              }
            }));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Strony przedmiotowe'));
    await tester.pumpAndSettle();

    expect(find.byType(SubjectsPage), findsOneWidget);
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

    expect(find.text('Ogłoszenia'), findsOneWidget);
    expect(find.text('Strony przedmiotowe'), findsOneWidget);
    expect(find.text('Usprawiedliwienia'), findsOneWidget);
    expect(find.text('Plan zajęć'), findsOneWidget);
  });

  testWidgets('Shows correct message when announcements stream is null',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getLatestAnnouncements(any(), any()))
        .thenAnswer((_) => Stream.value([]));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Brak ogłoszeń'), findsOneWidget);
  });

  testWidgets('Drawer opens when menu icon is tapped',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getLatestAnnouncements(any(), any()))
        .thenAnswer((_) => Stream.value([]));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byType(Drawer), findsNothing);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.byType(Drawer), findsOneWidget);
  });
}
