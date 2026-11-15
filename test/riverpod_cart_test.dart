import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cart_four_ways/models/cart.dart';
import 'package:cart_four_ways/riverpod/cart_notifier.dart';
import 'package:cart_four_ways/services/checkout_api.dart';

class _FailingCheckoutApi extends CheckoutApi {
  @override
  Future<String> submit(double total) async {
    throw const CheckoutException('Card declined');
  }
}

void main() {
  test('Riverpod cart add and coupon test', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(cartProvider.notifier);
    notifier.add(catalog[0]); // Keyboard $49
    notifier.add(catalog[0]); // Keyboard $49
    notifier.applyCoupon('SAVE10');

    final state = container.read(cartProvider);
    expect(state.total, 88.2);
  });

  test('Riverpod checkout failure keeps lines', () async {
    final container = ProviderContainer(
      overrides: [
        checkoutApiProvider.overrideWithValue(_FailingCheckoutApi()),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(cartProvider.notifier);
    notifier.add(catalog[2]); // Monitor $199

    await notifier.checkout();

    final state = container.read(cartProvider);
    expect(state.status, CheckoutStatus.failure);
    expect(state.lines.length, 1);
  });
}