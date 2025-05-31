import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdi_main_project/pages/teacher/task_page.dart';
import 'package:pdi_main_project/service/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MockDatabaseMethods extends Mock implements DatabaseMethods {}

void main() {
  late MockDatabaseMethods mockDatabaseMethods;

  setUp(() {
    mockDatabaseMethods = MockDatabaseMethods();
  });

  Widget createWidgetUnderTest({
    Map<String, dynamic>? submission,
    Map<String, dynamic>? user,
    Map<String, dynamic>? task,
    int currentIndex = 0,
    List<String>? studentIds,
  }) {
    when(() => mockDatabaseMethods.getSubmission(any(), any()))
        .thenAnswer((_) async => submission ?? {});
    when(() => mockDatabaseMethods.getUser(any()))
        .thenAnswer((_) async => user ?? {});
    when(() => mockDatabaseMethods.getTask(any()))
        .thenAnswer((_) async => task ?? {});
    when(() => mockDatabaseMethods.updateSubmission(
          taskId: any(named: 'taskId'),
          studentId: any(named: 'studentId'),
          grade: any(named: 'grade'),
          comment: any(named: 'comment'),
        )).thenAnswer((_) async => Future.value());

    return MaterialApp(
      home: TaskPage(
        taskId: 'task1',
        studentIds: studentIds ?? ['student1'],
        currentIndex: currentIndex,
        databaseMethods: mockDatabaseMethods,
      ),
    );
  }

  testWidgets('Displays loading indicator while waiting for data',
      (tester) async {
    when(() => mockDatabaseMethods.getSubmission(any(), any())).thenAnswer(
        (_) async => Future.delayed(const Duration(seconds: 1), () => {}));
    when(() => mockDatabaseMethods.getUser(any())).thenAnswer(
        (_) async => Future.delayed(const Duration(seconds: 1), () => {}));
    when(() => mockDatabaseMethods.getTask(any())).thenAnswer(
        (_) async => Future.delayed(const Duration(seconds: 1), () => {}));

    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('Displays task, student and submission data', (tester) async {
    final submission = {
      'status': 'przesłane',
      'grade': '5',
      'comment': 'Dobra robota',
      'url': 'http://example.com/file.pdf',
      'submitted_at': Timestamp.fromDate(DateTime(2023, 5, 10, 12, 0)),
    };
    final user = {'name': 'Jan', 'surname': 'Kowalski'};
    final task = {
      'title': 'Testowe zadanie',
      'content': 'Zrób zadanie domowe',
      'due_date': Timestamp.fromDate(DateTime(2023, 5, 15, 23, 59)),
    };

    await tester.pumpWidget(createWidgetUnderTest(
      submission: submission,
      user: user,
      task: task,
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Zadanie: Testowe zadanie'), findsOneWidget);
    expect(find.textContaining('Uczeń: Jan Kowalski'), findsOneWidget);
    expect(find.textContaining('Termin na wykonanie: 15.05.2023 23:59'),
        findsOneWidget);
    expect(find.textContaining('Treść zadania:'), findsOneWidget);
    expect(find.text('Zrób zadanie domowe'), findsOneWidget);
    expect(find.text('Status: przesłane'), findsOneWidget);
    expect(find.text('Ocenione: Tak'), findsOneWidget);
    expect(find.text('Dobra robota'), findsOneWidget);
    expect(find.text('5'), findsWidgets);
    expect(find.text('Pobierz rozwiązanie'), findsOneWidget);
  });

  testWidgets('Navigates to previous and next student using arrow buttons',
      (tester) async {
    final submission = {
      'status': 'przesłane',
      'grade': '4',
      'comment': 'Poprawnie',
      'url': 'http://example.com/file.pdf',
      'submitted_at': Timestamp.fromDate(DateTime(2023, 5, 10, 12, 0)),
    };
    final user = {'name': 'Jan', 'surname': 'Kowalski'};
    final task = {
      'title': 'Testowe zadanie',
      'content': 'Zrób zadanie domowe',
      'due_date': Timestamp.fromDate(DateTime(2023, 5, 15, 23, 59)),
    };
    final studentIds = ['student1', 'student2', 'student3'];

    await tester.pumpWidget(createWidgetUnderTest(
      submission: submission,
      user: user,
      task: task,
      currentIndex: 1,
      studentIds: studentIds,
    ));
    await tester.pumpAndSettle();

    final prevButton = find.widgetWithIcon(IconButton, Icons.arrow_back);
    expect(tester.widget<IconButton>(prevButton).onPressed, isNotNull);

    final nextButton = find.widgetWithIcon(IconButton, Icons.arrow_forward);
    expect(tester.widget<IconButton>(nextButton).onPressed, isNotNull);
  });

  testWidgets(
      'Disables previous arrow on first student and next arrow on last student',
      (tester) async {
    final submission = {
      'status': 'przesłane',
      'grade': '4',
      'comment': 'Poprawnie',
      'url': 'http://example.com/file.pdf',
      'submitted_at': Timestamp.fromDate(DateTime(2023, 5, 10, 12, 0)),
    };
    final user = {'name': 'Jan', 'surname': 'Kowalski'};
    final task = {
      'title': 'Testowe zadanie',
      'content': 'Zrób zadanie domowe',
      'due_date': Timestamp.fromDate(DateTime(2023, 5, 15, 23, 59)),
    };
    final studentIds = ['student1', 'student2', 'student3'];

    await tester.pumpWidget(createWidgetUnderTest(
      submission: submission,
      user: user,
      task: task,
      currentIndex: 0,
      studentIds: studentIds,
    ));
    await tester.pumpAndSettle();
    final prevButton = find.widgetWithIcon(IconButton, Icons.arrow_back);
    expect(tester.widget<IconButton>(prevButton).onPressed, isNull);

    await tester.pumpWidget(createWidgetUnderTest(
      submission: submission,
      user: user,
      task: task,
      currentIndex: 2,
      studentIds: studentIds,
    ));
    await tester.pumpAndSettle();
    final nextButton = find.widgetWithIcon(IconButton, Icons.arrow_forward);
    expect(tester.widget<IconButton>(nextButton).onPressed, isNull);
  });
}
