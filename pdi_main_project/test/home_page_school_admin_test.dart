import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdi_main_project/pages/school_admin/home_page_school_admin.dart';
import 'package:pdi_main_project/pages/school_admin/add_user_page_sa.dart';
import 'package:pdi_main_project/pages/school_admin/manage_classes_page_sa.dart';
import 'package:pdi_main_project/service/database.dart';

class MockDatabaseMethods extends Mock implements DatabaseMethods {}

void main() {
  late MockDatabaseMethods mockDatabaseMethods;

  setUp(() {
    mockDatabaseMethods = MockDatabaseMethods();
    when(() => mockDatabaseMethods.getSchoolId())
        .thenAnswer((_) async => 'school1');
    when(() => mockDatabaseMethods.getCurrentYear(any()))
        .thenAnswer((_) async => '2023/2024');
    when(() => mockDatabaseMethods.getLessonTimes(any()))
        .thenAnswer((_) async => {
              1: {'start': '8:00', 'end': '8:45'}
            });
    when(() => mockDatabaseMethods.getSchoolName(any()))
        .thenAnswer((_) async => 'Test School');
    when(() => mockDatabaseMethods.updateCurrentYear(any(), any()))
        .thenAnswer((_) async => Future.value());
    when(() => mockDatabaseMethods.updateLessonTimes(any(), any()))
        .thenAnswer((_) async => Future.value());
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: HomePageSchoolAdmin(databaseMethods: mockDatabaseMethods),
    );
  }

  testWidgets('Displays loading indicator while waiting for school info',
      (tester) async {
    when(() => mockDatabaseMethods.getSchoolId()).thenAnswer((_) async =>
        Future.delayed(const Duration(seconds: 1), () => 'school1'));
    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('Displays error message when loading fails', (tester) async {
    when(() => mockDatabaseMethods.getSchoolId())
        .thenThrow(Exception('Test error'));
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();
    expect(find.textContaining('Błąd:'), findsOneWidget);
  });

  testWidgets('Opens change year dialog and validates input', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Zmień rok szkolny'));
    await tester.pumpAndSettle();

    expect(find.text('Zmień aktualny rok szkolny'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'badformat');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Zapisz'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Nieprawidłowy format'), findsOneWidget);
  });

  testWidgets('Calls updateCurrentYear when valid year entered',
      (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Zmień rok szkolny'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '2024/2025');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Zapisz'));
    await tester.pumpAndSettle();

    verify(() => mockDatabaseMethods.updateCurrentYear('school1', '2024/2025'))
        .called(1);
  });

  testWidgets('Opens edit lesson times dialog and saves changes',
      (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Godziny zajęć'));

    await tester.pumpAndSettle();

    expect(find.text('Edytuj godziny lekcji'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '7:55');
    await tester.enterText(find.byType(TextField).last, '8:40');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Zapisz'));
    await tester.pumpAndSettle();

    verify(() => mockDatabaseMethods.updateLessonTimes('school1', any()))
        .called(1);
  });

  testWidgets('Navigates to AddUserPageSa when "Dodaj użytkownika" tapped',
      (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dodaj użytkownika'));

    await tester.pumpAndSettle();

    expect(find.byType(AddUserPageSa), findsOneWidget);
  });

  testWidgets(
      'Navigates to ManageClassesPageSa when "Zarządzaj klasami" tapped',
      (tester) async {
    when(() => mockDatabaseMethods.getClassesForSchool(any()))
        .thenAnswer((_) async => [
              {'id': 'class1', 'name': 'Klasa 1A'},
              {'id': 'class2', 'name': 'Klasa 2B'}
            ]);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Zarządzaj klasami'));

    await tester.pumpAndSettle();

    expect(find.byType(ManageClassesPageSa), findsOneWidget);
  });
}
