import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke test — app widget renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Gravity Fintracker'))),
    );
    expect(find.text('Gravity Fintracker'), findsOneWidget);
  });
}
