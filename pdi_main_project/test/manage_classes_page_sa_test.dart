import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdi_main_project/pages/school_admin/manage_classes_page_sa.dart';
import 'package:pdi_main_project/service/database.dart';

class MockDatabaseMethods extends Mock implements DatabaseMethods {}

void main() {
  late MockDatabaseMethods mockDatabaseMethods;

  setUp(() {
    mockDatabaseMethods = MockDatabaseMethods();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: ManageClassesPageSa(
        databaseMethods: mockDatabaseMethods,
        schoolId: 'testSchoolId',
      ),
    );
  }

  testWidgets('Displays loading indicator while waiting for classes',
      (tester) async {
    when(() => mockDatabaseMethods.getClassesForSchool(any())).thenAnswer(
        (_) async => Future.delayed(const Duration(seconds: 1), () => []));

    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('Displays message when no classes are available', (tester) async {
    when(() => mockDatabaseMethods.getClassesForSchool(any()))
        .thenAnswer((_) async => []);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Brak klas'), findsOneWidget);
  });

  testWidgets('Displays class list when data is loaded', (tester) async {
    when(() => mockDatabaseMethods.getClassesForSchool(any()))
        .thenAnswer((_) async => [
              {'id': 'class1', 'name': '1A'},
              {'id': 'class2', 'name': '2B'},
            ]);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('1A'), findsOneWidget);
    expect(find.text('2B'), findsOneWidget);
    expect(find.byIcon(Icons.edit), findsNWidgets(2));
    expect(find.byIcon(Icons.delete), findsNWidgets(2));
    expect(find.byIcon(Icons.arrow_forward_rounded), findsNWidgets(2));
  });

  testWidgets('Shows edit dialog when edit icon is tapped', (tester) async {
    when(() => mockDatabaseMethods.getClassesForSchool(any()))
        .thenAnswer((_) async => [
              {'id': 'class1', 'name': '1A'},
            ]);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();

    expect(find.text('Edytuj nazwę klasy'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Zapisz'), findsOneWidget);
  });

  testWidgets('Shows delete confirmation dialog when delete icon is tapped',
      (tester) async {
    when(() => mockDatabaseMethods.getClassesForSchool(any()))
        .thenAnswer((_) async => [
              {'id': 'class1', 'name': '1A'},
            ]);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(find.text('Usuń klasę'), findsOneWidget);
    expect(find.text('Czy na pewno chcesz usunąć tę klasę?'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Usuń'), findsOneWidget);
  });
}
