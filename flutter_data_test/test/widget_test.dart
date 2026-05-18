import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_data_test/constants/colors.dart';
import 'package:flutter_data_test/pages/auth_page.dart';
import 'package:flutter_data_test/services/theme_service.dart';
import 'package:flutter_data_test/widgets/featured_channels_widget.dart';
import 'package:flutter_data_test/widgets/retro_ui.dart';

void main() {
  testWidgets('auth screen renders login controls', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildAuroraTheme(), home: const AuthPage()),
    );

    expect(find.text('AuroraTV'), findsOneWidget);
    expect(find.text('Member Login'), findsOneWidget);
    expect(find.text('Continue as guest'), findsOneWidget);
  });

  testWidgets('start watching shelf renders added tapes', (tester) async {
    TapeData? pressedTape;
    const addedTape = TapeData(
      title: 'Shared',
      keyword: 'shared channel',
      color: auroraGreen,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAuroraTheme(),
        home: Scaffold(
          body: FeaturedChannelsWidget(
            addedTapes: const [addedTape],
            onTapePressed: (tape) => pressedTape = tape,
          ),
        ),
      ),
    );

    expect(find.text('Start Watching'), findsOneWidget);
    expect(find.text('Shared'), findsOneWidget);

    await tester.tap(find.text('Shared'));

    expect(pressedTape, same(addedTape));
  });
}
