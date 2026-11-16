import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tunisie_tv_live/main.dart';

void main() {
  testWidgets('Home screen renders the header and channel grid', (WidgetTester tester) async {
    await tester.pumpWidget(const TunisieTvLiveApp());
    await tester.pump();

    expect(find.text('Tunisie TV '), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
  });
}
