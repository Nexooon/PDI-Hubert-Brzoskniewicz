import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdi_main_project/pages/school_admin/add_class_page_sa.dart';
import 'package:pdi_main_project/service/database.dart';

class MockDatabaseMethods extends Mock implements DatabaseMethods {}

void main() {
  late MockDatabaseMethods mockDatabaseMethods;

  setUp(() {
    mockDatabaseMethods = MockDatabaseMethods();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: AddClassPageSa(
        databaseMethods: mockDatabaseMethods,
        schoolId: 'testSchoolId',
      ),
    );
  }

  testWidgets('Displays title and input field', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Dodaj klasę'), findsWidgets);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Dodaj klasę'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('Shows error if class name is empty',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.widgetWithText(ElevatedButton, 'Dodaj klasę'));
    await tester.pumpAndSettle();

    expect(find.text('Nazwa klasy nie może być pusta'), findsOneWidget);
  });

  testWidgets('Calls addClassToSchool and pops when valid',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.addClassToSchool(any(), any(), any()))
        .thenAnswer((_) async => Future.value());

    await tester.pumpWidget(createWidgetUnderTest());

    await tester.enterText(find.byType(TextField), '2B');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Dodaj klasę'));
    await tester.pumpAndSettle();

    expect(find.byType(AddClassPageSa), findsNothing);
  });
}
