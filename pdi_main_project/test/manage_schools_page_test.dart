import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdi_main_project/pages/super_admin/manage_schools_page.dart';
import 'package:pdi_main_project/service/database.dart';

class MockDatabaseMethods extends Mock implements DatabaseMethods {}

void main() {
  late MockDatabaseMethods mockDatabaseMethods;

  setUp(() {
    mockDatabaseMethods = MockDatabaseMethods();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: ManageSchoolsPage(databaseMethods: mockDatabaseMethods),
    );
  }

  testWidgets('Displays loading indicator while waiting for schools', (tester) async {
    when(() => mockDatabaseMethods.getSchoolsWithDetails())
        .thenAnswer((_) async => Future.delayed(const Duration(seconds: 1), () => {}));

    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('Displays error message when loading schools fails', (tester) async {
    when(() => mockDatabaseMethods.getSchoolsWithDetails())
        .thenThrow(Exception('Test error'));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.textContaining('Błąd:'), findsOneWidget);
  });

  testWidgets('Displays list of schools when data is loaded', (tester) async {
    when(() => mockDatabaseMethods.getSchoolsWithDetails())
        .thenAnswer((_) async => {
              'school1': {
                'name': 'Szkoła Podstawowa 1',
                'address': 'ul. Szkolna 1',
                'contact': '123456789',
                'current_year': '2023/2024'
              },
              'school2': {
                'name': 'Liceum Ogólnokształcące',
                'address': 'ul. Licealna 2',
                'contact': '987654321',
                'current_year': '2023/2024'
              }
            });

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Szkoła Podstawowa 1'), findsOneWidget);
    expect(find.text('Liceum Ogólnokształcące'), findsOneWidget);
    expect(find.textContaining('ul. Szkolna 1'), findsOneWidget);
    expect(find.textContaining('ul. Licealna 2'), findsOneWidget);
    expect(find.byIcon(Icons.edit), findsNWidgets(2));
    expect(find.byIcon(Icons.delete), findsNWidgets(2));
  });

  testWidgets('Shows add school dialog when FAB is tapped', (tester) async {
    when(() => mockDatabaseMethods.getSchoolsWithDetails())
        .thenAnswer((_) async => {});

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Dodaj szkołę'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(4));
    expect(find.widgetWithText(ElevatedButton, 'Zapisz'), findsOneWidget);
  });

  testWidgets('Shows edit school dialog when edit icon is tapped', (tester) async {
    when(() => mockDatabaseMethods.getSchoolsWithDetails())
        .thenAnswer((_) async => {
              'school1': {
                'name': 'Szkoła Podstawowa 1',
                'address': 'ul. Szkolna 1',
                'contact': '123456789',
                'current_year': '2023/2024'
              }
            });

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    expect(find.text('Edytuj szkołę'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(4));
    expect(find.widgetWithText(ElevatedButton, 'Zapisz'), findsOneWidget);
  });

  testWidgets('Shows delete confirmation dialog when delete icon is tapped', (tester) async {
    when(() => mockDatabaseMethods.getSchoolsWithDetails())
        .thenAnswer((_) async => {
              'school1': {
                'name': 'Szkoła Podstawowa 1',
                'address': 'ul. Szkolna 1',
                'contact': '123456789',
                'current_year': '2023/2024'
              }
            });

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(find.text('Potwierdzenie'), findsOneWidget);
    expect(find.text('Czy na pewno chcesz usunąć tę szkołę?'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Usuń'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Anuluj'), findsOneWidget);
  });
}