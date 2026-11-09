import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cart_four_ways/setstate/cart_page_setstate.dart';


void main() {
  testWidgets('SetState cart flow test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SetStateCartPage()));

    // Target the ActionChip specifically
    final keyboardChip = find.widgetWithText(ActionChip, 'Keyboard \$49');
    expect(keyboardChip, findsOneWidget);
    
    // Tap it twice
    await tester.tap(keyboardChip);
    await tester.pump();
    await tester.tap(keyboardChip);
    await tester.pump();

    // Enter SAVE10 coupon and apply
    await tester.enterText(find.byType(TextField), 'SAVE10');
    await tester.tap(find.text('Apply'));
    await tester.pump();

    // Assert the total row reads $88.20 specifically
    expect(find.textContaining('Total: \$88.20'), findsOneWidget);
  });
}