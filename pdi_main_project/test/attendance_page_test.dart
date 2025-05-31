import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdi_main_project/pages/student/attendance_page.dart';
import 'package:pdi_main_project/service/database.dart';

// Mock classes
class MockDatabaseMethods extends Mock implements DatabaseMethods {}

void main() {
  late MockDatabaseMethods mockDatabaseMethods;

  setUp(() {
    mockDatabaseMethods = MockDatabaseMethods();

    // Register fallback values for Mocktail
    registerFallbackValue(FakeBuildContext());
    registerFallbackValue(Timestamp.now());
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: AttendancePage(
        currentUserUid: 'testUserUid',
        userRole: 'student',
        databaseMethods: mockDatabaseMethods,
      ),
    );
  }

  testWidgets('Displays loading indicator while waiting for data',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getStudentAttendance(any())).thenAnswer(
        (_) async => Future.delayed(const Duration(seconds: 2), () => {}));

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('Displays error message when data loading fails',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getStudentAttendance(any()))
        .thenThrow(Exception('Test error'));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.textContaining('Błąd: '), findsOneWidget);
  });

  testWidgets('Displays message when no attendance data is available',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getStudentAttendance(any()))
        .thenAnswer((_) async => {});

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Brak danych o frekwencji'), findsOneWidget);
  });

  testWidgets('Displays attendance data when loaded successfully',
      (WidgetTester tester) async {
    when(() => mockDatabaseMethods.getStudentAttendance(any())).thenAnswer(
      (_) async => {
        'Spóźniony': {
          Timestamp.now(): {
            'Mathematics': [
              {'time': '08:00', 'justified': true},
              {'time': '09:00', 'justified': false},
            ]
          }
        },
        'Nieobecny': {
          Timestamp.now(): {
            'Physics': [
              {'time': '10:00', 'justified': false},
            ]
          }
        }
      },
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Spóźnienia'), findsOneWidget);
    expect(find.text('Nieobecności'), findsOneWidget);
    expect(find.textContaining('Mathematics'), findsNWidgets(2));
    expect(find.textContaining('Physics'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.cancel), findsNWidgets(2));
  });
}

// Fake class for BuildContext
class FakeBuildContext extends Fake implements BuildContext {}
