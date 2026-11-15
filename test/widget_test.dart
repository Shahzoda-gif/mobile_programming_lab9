import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cart_four_ways/main.dart';

void main() {
  testWidgets('Home screen renders all four state management buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    expect(find.text('One Cart, Four Ways'), findsOneWidget);
    expect(find.text('setState'), findsOneWidget);
    expect(find.text('Riverpod'), findsOneWidget);
    expect(find.text('Cubit'), findsOneWidget);
    expect(find.text('Bloc'), findsOneWidget);
  });
}