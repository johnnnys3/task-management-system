// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:task_management/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TaskManagementApp());

    // No real Firebase backend in tests, so the auth stream never resolves
    // and AuthenticationWrapper shows a perpetual loading spinner — pump a
    // bounded number of frames rather than pumpAndSettle (which would never
    // return while that spinner keeps animating).
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Basic smoke test - just verify the app builds successfully
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
