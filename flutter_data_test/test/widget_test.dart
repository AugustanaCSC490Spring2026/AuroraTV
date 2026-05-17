import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_data_test/pages/auth_page.dart';
import 'package:flutter_data_test/services/theme_service.dart';

void main() {
  testWidgets('auth screen renders login controls', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildAuroraTheme(), home: const AuthPage()),
    );

    expect(find.text('AuroraTV'), findsOneWidget);
    expect(find.text('Member Login'), findsOneWidget);
    expect(find.text('Continue as guest'), findsOneWidget);
  });
}
