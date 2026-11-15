import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cart_four_ways/cubit/cart_cubit.dart';
import 'package:cart_four_ways/models/cart.dart';
import 'package:cart_four_ways/services/checkout_api.dart';

class _FailingCheckoutApi extends CheckoutApi {
  @override
  Future<String> submit(double total) async {
    throw const CheckoutException('Card declined');
  }
}

void main() {
  blocTest<CartCubit, CartState>(
    'adds items and applies SAVE10 coupon',
    build: () => CartCubit(),
    act: (cubit) {
      cubit.add(catalog[0]);
      cubit.add(catalog[0]);
      cubit.applyCoupon('SAVE10');
    },
    verify: (cubit) {
      expect(cubit.state.total, 88.2);
    },
  );

  blocTest<CartCubit, CartState>(
    'emits failure on declined checkout and keeps items',
    build: () => CartCubit(api: _FailingCheckoutApi()),
    seed: () => CartState(lines: [CartLine(product: catalog[2], qty: 1)]),
    act: (cubit) => cubit.checkout(),
    verify: (cubit) {
      expect(cubit.state.status, CheckoutStatus.failure);
      expect(cubit.state.lines.length, 1);
    },
  );
}