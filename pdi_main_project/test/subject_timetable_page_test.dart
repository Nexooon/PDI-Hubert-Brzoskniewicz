import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdi_main_project/pages/school_admin/subject_timetable_page.dart';
import 'package:pdi_main_project/service/database.dart';

class MockDatabaseMethods extends Mock implements DatabaseMethods {}

void main() {
  late MockDatabaseMethods mockDatabaseMethods;

  setUp(() {
    mockDatabaseMethods = MockDatabaseMethods();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: SubjectTimetablePage(
        databaseMethods: mockDatabaseMethods,
        schoolId: 'testSchoolId',
        classId: 'testClassId',
        subjectId: 'testSubjectId',
        subjectName: 'Matematyka',
      ),
    );
  }

  testWidgets('Displays loading indicator while waiting for timetable entries',
      (tester) async {
    when(() => mockDatabaseMethods.getTimetableEntries(any(), any(), any()))
        .thenAnswer(
            (_) async => Future.delayed(const Duration(seconds: 1), () => []));

    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('Displays message when no timetable entries are available',
      (tester) async {
    when(() => mockDatabaseMethods.getTimetableEntries(any(), any(), any()))
        .thenAnswer((_) async => []);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Brak wpisów w planie'), findsOneWidget);
  });

  testWidgets('Displays timetable entries when data is loaded', (tester) async {
    when(() => mockDatabaseMethods.getTimetableEntries(any(), any(), any()))
        .thenAnswer((_) async => [
              {
                'id': 'entry1',
                'day': 'Poniedziałek',
                'lesson_number': '2',
                'room': '101',
              },
              {
                'id': 'entry2',
                'day': 'Wtorek',
                'lesson_number': '3',
                'room': '202',
              },
            ]);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Poniedziałek, lekcja nr 2'), findsOneWidget);
    expect(find.text('Sala: 101'), findsOneWidget);
    expect(find.text('Wtorek, lekcja nr 3'), findsOneWidget);
    expect(find.text('Sala: 202'), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsNWidgets(2));
  });

  testWidgets('Shows add entry dialog when FAB is tapped', (tester) async {
    when(() => mockDatabaseMethods.getTimetableEntries(any(), any(), any()))
        .thenAnswer((_) async => []);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Dodaj wpis do planu'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));
    expect(find.byType(TextField), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Dodaj'), findsOneWidget);
  });

  testWidgets('Shows delete confirmation dialog when delete icon is tapped',
      (tester) async {
    when(() => mockDatabaseMethods.getTimetableEntries(any(), any(), any()))
        .thenAnswer((_) async => [
              {
                'id': 'entry1',
                'day': 'Poniedziałek',
                'lesson_number': '2',
                'room': '101',
              },
            ]);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(find.text('Usuń wpis'), findsOneWidget);
    expect(find.text('Czy na pewno chcesz usunąć ten wpis z planu?'),
        findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Usuń'), findsOneWidget);
  });
}
