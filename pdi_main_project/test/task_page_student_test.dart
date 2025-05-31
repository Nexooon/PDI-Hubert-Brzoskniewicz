import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdi_main_project/pages/student/task_page_student.dart';
import 'package:pdi_main_project/service/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

class MockDatabaseMethods extends Mock implements DatabaseMethods {}

class MockPlatformFile extends Fake implements PlatformFile {}

void main() {
  late MockDatabaseMethods mockDatabaseMethods;

  setUp(() {
    mockDatabaseMethods = MockDatabaseMethods();
  });

  Widget createWidgetUnderTest({
    Map<String, dynamic>? submission,
    Map<String, dynamic>? task,
  }) {
    when(() => mockDatabaseMethods.getSubmission(any(), any()))
        .thenAnswer((_) async => {
              'status': submission?['status'] ?? 'nieprzesłane',
              'grade': submission?['grade'],
              'comment': submission?['comment'],
              'file_name': submission?['file_name'],
              'url': submission?['url'],
              'submitted_at': submission?['submitted_at'] ??
                  Timestamp.fromDate(DateTime(2023, 5, 10, 12, 0)),
            });
    when(() => mockDatabaseMethods.getTask(any())).thenAnswer((_) async => {
          'title': task?['title'] ?? 'Testowe zadanie',
          'content': task?['content'] ?? 'Zrób zadanie domowe',
          'due_date': task?['due_date'] ??
              Timestamp.fromDate(DateTime(2023, 5, 15, 23, 59)),
        });
    return MaterialApp(
      home: TaskPageStudent(
        taskId: 'task1',
        studentId: 'student1',
        databaseMethods: mockDatabaseMethods,
      ),
    );
  }

  testWidgets('Shows loading indicator while waiting for data', (tester) async {
    when(() => mockDatabaseMethods.getSubmission(any(), any()))
        .thenAnswer((_) async => {});
    when(() => mockDatabaseMethods.getTask(any())).thenAnswer((_) async => {});

    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Displays task and submission data', (tester) async {
    final submission = {
      'status': 'przesłane',
      'grade': '5',
      'comment': 'Dobra robota',
      'file_name': 'zadanie.pdf',
      'url': 'http://example.com/file.pdf',
      'submitted_at': Timestamp.fromDate(DateTime(2023, 5, 10, 12, 0)),
    };
    final task = {
      'title': 'Testowe zadanie',
      'content': 'Zrób zadanie domowe',
      'due_date': Timestamp.fromDate(DateTime(2023, 5, 15, 23, 59)),
    };

    await tester
        .pumpWidget(createWidgetUnderTest(submission: submission, task: task));
    await tester.pumpAndSettle();

    expect(find.textContaining('Zadanie: Testowe zadanie'), findsOneWidget);
    expect(find.textContaining('Zrób zadanie domowe'), findsOneWidget);
    expect(find.textContaining('Status: przesłane'), findsOneWidget);
    expect(find.textContaining('Ocena:'), findsWidgets);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('Dobra robota'), findsOneWidget);
    expect(find.text('Plik został przesłany:'), findsOneWidget);
    expect(find.text('zadanie.pdf'), findsOneWidget);
    expect(find.text('Wyślij ponownie'), findsOneWidget);
  });

  testWidgets('Shows "Wybierz plik" button if no file submitted',
      (tester) async {
    final submission = {
      'status': 'nieprzesłane',
      'grade': '',
      'comment': null,
      'file_name': null,
      'url': null,
      'submitted_at': null,
    };
    final task = {
      'title': 'Testowe zadanie',
      'content': 'Zrób zadanie domowe',
      'due_date': Timestamp.fromDate(DateTime(2023, 5, 15, 23, 59)),
    };

    await tester
        .pumpWidget(createWidgetUnderTest(submission: submission, task: task));
    await tester.pumpAndSettle();

    expect(find.text('Wybierz plik'), findsOneWidget);
    expect(find.text('Prześlij zadanie'), findsOneWidget);
  });

  testWidgets('Displays "Brak oceny" and "Brak komentarza" if not graded',
      (tester) async {
    final submission = {
      'status': 'przesłane',
      'grade': null,
      'comment': null,
      'file_name': 'zadanie.pdf',
      'url': 'http://example.com/file.pdf',
      'submitted_at': Timestamp.fromDate(DateTime(2023, 5, 10, 12, 0)),
    };
    final task = {
      'title': 'Testowe zadanie',
      'content': 'Zrób zadanie domowe',
      'due_date': Timestamp.fromDate(DateTime(2023, 5, 15, 23, 59)),
    };

    await tester
        .pumpWidget(createWidgetUnderTest(submission: submission, task: task));
    await tester.pumpAndSettle();

    expect(find.text('Brak oceny'), findsOneWidget);
    expect(find.text('Brak komentarza'), findsOneWidget);
  });
}
