import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bike_shop_user_photos/main.dart';

void main() {
  testWidgets('bike shop app renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: BikeShopApp()));

    expect(find.text('カワサキ ゼファー400'), findsOneWidget);
  });
}
