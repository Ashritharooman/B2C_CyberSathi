import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:b2c_app/main.dart';

void main() {
  testWidgets('App starts on the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const CyberSaathiApp());

    expect(find.text('Log in'), findsWidgets);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
