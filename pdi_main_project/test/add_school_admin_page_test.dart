import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdi_main_project/pages/super_admin/add_school_admin_page.dart';
import 'package:pdi_main_project/service/database.dart';

class MockDatabaseMethods extends Mock implements DatabaseMethods {}

void main() {
  late MockDatabaseMethods mockDatabaseMethods;

  setUp(() {
    mockDatabaseMethods = MockDatabaseMethods();
  });

  Widget createWidgetUnderTest({Map<String, dynamic>? schoolsData}) {
    return MaterialApp(
      home: AddSchoolAdminPage(
        databaseMethods: mockDatabaseMethods,
      ),
    );
  }

  testWidgets('Displays loading indicator while waiting for schools',
      (tester) async {
    when(() => mockDatabaseMethods.getSchools()).thenAnswer((_) async =>
        Future.delayed(
            const Duration(seconds: 1), () => {'school1': 'Szkoła 1'}));

    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('Displays all input fields and school dropdown', (tester) async {
    when(() => mockDatabaseMethods.getSchools()).thenAnswer(
        (_) async => {'school1': 'Szkoła 1', 'school2': 'Szkoła 2'});

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Dodaj administratora szkoły'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(4));
    expect(find.widgetWithText(DropdownButtonFormField<String>, 'Szkoła'),
        findsOneWidget);
    expect(
        find.widgetWithText(ElevatedButton, 'Dodaj szkolnego administratora'),
        findsOneWidget);
  });

  testWidgets('Shows validation errors if fields are empty', (tester) async {
    when(() => mockDatabaseMethods.getSchools())
        .thenAnswer((_) async => {'school1': 'Szkoła 1'});

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(
        find.widgetWithText(ElevatedButton, 'Dodaj szkolnego administratora'));
    await tester.pumpAndSettle();

    expect(find.text('Proszę wpisać imię'), findsOneWidget);
    expect(find.text('Proszę wpisać nazwisko'), findsOneWidget);
    expect(find.text('Proszę wpisać email'), findsOneWidget);
    expect(find.text('Proszę wpisać hasło'), findsOneWidget);
    expect(find.text('Proszę wybrać szkołę'), findsOneWidget);
  });
}
