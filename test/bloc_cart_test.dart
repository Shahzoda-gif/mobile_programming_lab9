import 'package:flutter_test/flutter_test.dart';
import 'package:cart_four_ways/bloc/cart_bloc.dart';
import 'package:cart_four_ways/bloc/cart_event.dart';
import 'package:cart_four_ways/models/cart.dart';
import 'package:cart_four_ways/services/checkout_api.dart';

class _FailingCheckoutApi extends CheckoutApi {
  @override
  Future<String> submit(double total) async {
    throw const CheckoutException('Card declined');
  }
}

void main() {
  test('Bloc dispatches events and calculates discounted total', () async {
    final bloc = CartBloc();
    addTearDown(bloc.close);

    bloc.add(CartItemAdded(catalog[0]));
    bloc.add(CartItemAdded(catalog[0]));
    bloc.add(const CartCouponApplied('SAVE10'));

    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.total, 88.2);
  });

  test('Bloc checkout failure keeps lines', () async {
    final bloc = CartBloc(api: _FailingCheckoutApi());
    addTearDown(bloc.close);

    bloc.add(CartItemAdded(catalog[2]));
    bloc.add(const CartCheckoutRequested());

    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.status, CheckoutStatus.failure);
    expect(bloc.state.lines.length, 1);
  });
}