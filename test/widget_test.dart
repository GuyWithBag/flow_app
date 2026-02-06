// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:flow_app/main.dart';

void main() {
  testWidgets('FlowApp boots', (WidgetTester tester) async {
    // This app doesn't use the default counter template; just verify it renders.
    await tester.pumpWidget(const FlowApp());
    await tester.pumpAndSettle();

    expect(find.text('Flow'), findsWidgets);
  });
}
