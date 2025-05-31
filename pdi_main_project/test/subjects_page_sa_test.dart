import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdi_main_project/pages/school_admin/subjects_page_sa.dart';
import 'package:pdi_main_project/pages/school_admin/subject_timetable_page.dart';
import 'package:pdi_main_project/service/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MockDatabaseMethods extends Mock implements DatabaseMethods {}

// ignore: subtype_of_sealed_class
class MockDocumentReference extends Mock implements DocumentReference {}

// ignore: subtype_of_sealed_class
class MockDocumentSnapshot extends Mock implements DocumentSnapshot {}

void main() {
  late MockDatabaseMethods mockDatabaseMethods;
  late MockDocumentReference mockTeacherRef;

  setUp(() {
    mockDatabaseMethods = MockDatabaseMethods();
    mockTeacherRef = MockDocumentReference();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: SubjectsPageSa(
        databaseMethods: mockDatabaseMethods,
        schoolId: 'testSchoolId',
        classId: 'testClassId',
        className: '1A',
      ),
    );
  }

  void mockTeacherName({String name = 'Jan', String surname = 'Kowalski'}) {
    final mockSnapshot = MockDocumentSnapshot();
    when(() => mockTeacherRef.get()).thenAnswer((_) async => mockSnapshot);
    when(() => mockSnapshot.data())
        .thenReturn({'name': name, 'surname': surname});
  }

  testWidgets('Displays loading indicator while waiting for subjects',
      (tester) async {
    when(() => mockDatabaseMethods.getSubjectsForClass(any(), any()))
        .thenAnswer(
            (_) async => Future.delayed(const Duration(seconds: 1), () => []));
    when(() => mockDatabaseMethods.getCurrentYear(any()))
        .thenAnswer((_) async => '2023/2024');

    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('Displays message when no subjects are available',
      (tester) async {
    when(() => mockDatabaseMethods.getSubjectsForClass(any(), any()))
        .thenAnswer((_) async => []);
    when(() => mockDatabaseMethods.getCurrentYear(any()))
        .thenAnswer((_) async => '2023/2024');

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Brak przedmiotów'), findsOneWidget);
  });

  testWidgets('Displays subject list with teacher name', (tester) async {
    mockTeacherName();
    when(() => mockDatabaseMethods.getSubjectsForClass(any(), any()))
        .thenAnswer((_) async => [
              {
                'id': 'subject1',
                'name': 'Matematyka',
                'year': '2023/2024',
                'employee': mockTeacherRef,
              }
            ]);
    when(() => mockDatabaseMethods.getCurrentYear(any()))
        .thenAnswer((_) async => '2023/2024');

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Matematyka'), findsOneWidget);
    expect(find.textContaining('Rok: 2023/2024, nauczyciel: Jan Kowalski'),
        findsOneWidget);
    expect(find.byIcon(Icons.schedule), findsOneWidget);
    expect(find.byIcon(Icons.edit), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsOneWidget);
  });

  testWidgets('Shows add subject dialog when FAB is tapped', (tester) async {
    when(() => mockDatabaseMethods.getSubjectsForClass(any(), any()))
        .thenAnswer((_) async => []);
    when(() => mockDatabaseMethods.getCurrentYear(any()))
        .thenAnswer((_) async => '2023/2024');
    when(() => mockDatabaseMethods.getTeachers(any())).thenAnswer((_) async => [
          {'ref': mockTeacherRef, 'fullName': 'Jan Kowalski'}
        ]);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Dodaj przedmiot'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.byType(DropdownButtonFormField<DocumentReference>),
        findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Dodaj'), findsOneWidget);
  });

  testWidgets('Shows edit subject dialog when edit icon is tapped',
      (tester) async {
    mockTeacherName();
    when(() => mockDatabaseMethods.getSubjectsForClass(any(), any()))
        .thenAnswer((_) async => [
              {
                'id': 'subject1',
                'name': 'Matematyka',
                'year': '2023/2024',
                'employee': mockTeacherRef,
              }
            ]);
    when(() => mockDatabaseMethods.getCurrentYear(any()))
        .thenAnswer((_) async => '2023/2024');
    when(() => mockDatabaseMethods.getTeachers(any())).thenAnswer((_) async => [
          {'ref': mockTeacherRef, 'fullName': 'Jan Kowalski'}
        ]);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    expect(find.text('Edytuj przedmiot'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.byType(DropdownButtonFormField<DocumentReference>),
        findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Zapisz'), findsOneWidget);
  });

  testWidgets('Shows delete confirmation dialog when delete icon is tapped',
      (tester) async {
    mockTeacherName();
    when(() => mockDatabaseMethods.getSubjectsForClass(any(), any()))
        .thenAnswer((_) async => [
              {
                'id': 'subject1',
                'name': 'Matematyka',
                'year': '2023/2024',
                'employee': mockTeacherRef,
              }
            ]);
    when(() => mockDatabaseMethods.getCurrentYear(any()))
        .thenAnswer((_) async => '2023/2024');

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(find.text('Usuń przedmiot'), findsOneWidget);
    expect(
        find.text('Czy na pewno chcesz usunąć ten przedmiot?'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Usuń'), findsOneWidget);
  });

  testWidgets('Navigates to SubjectTimetablePage when schedule icon is tapped',
      (tester) async {
    mockTeacherName();
    when(() => mockDatabaseMethods.getSubjectsForClass(any(), any()))
        .thenAnswer((_) async => [
              {
                'id': 'subject1',
                'name': 'Matematyka',
                'year': '2023/2024',
                'employee': mockTeacherRef,
              }
            ]);
    when(() => mockDatabaseMethods.getCurrentYear(any()))
        .thenAnswer((_) async => '2023/2024');
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

    await tester.tap(find.byIcon(Icons.schedule));
    await tester.pumpAndSettle();

    expect(find.byType(SubjectTimetablePage), findsOneWidget);
  });
}
