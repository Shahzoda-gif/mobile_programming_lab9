import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/cart.dart';
import '../services/checkout_api.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit({CheckoutApi? api})
      : _api = api ?? CheckoutApi(),
        super(const CartState());

  final CheckoutApi _api;

  void _emitWithHistory(CartState next) {
    final nextHistory = [...state.history, state];
    emit(next.copyWith(history: nextHistory));
  }

  void add(Product p) {
    _emitWithHistory(state.copyWith(lines: state.lines.withProduct(p)));
  }

  void remove(String id) {
    _emitWithHistory(state.copyWith(lines: state.lines.without(id)));
  }

  void changeQty(String id, int delta) {
    _emitWithHistory(state.copyWith(lines: state.lines.changeQty(id, delta)));
  }

  void applyCoupon(String code) {
    if (code == 'SAVE10') {
      _emitWithHistory(
        state.copyWith(coupon: code, couponError: null),
      );
    } else {
      _emitWithHistory(
        state.copyWith(couponError: 'Invalid coupon'),
      );
    }
  }

  Future<void> checkout() async {
    if (state.status == CheckoutStatus.submitting || state.lines.isEmpty) {
      return;
    }
    emit(state.copyWith(status: CheckoutStatus.submitting));
    try {
      final orderId = await _api.submit(state.total);
      emit(
        state.copyWith(
          status: CheckoutStatus.success,
          orderId: orderId,
          lines: const [],
          coupon: null,
          couponError: null,
          checkoutError: null,
        ),
      );
    } on CheckoutException catch (e) {
      emit(
        state.copyWith(
          status: CheckoutStatus.failure,
          checkoutError: e.message,
        ),
      );
    }
  }

  void undo() {
    if (state.history.isEmpty) return;
    final previous = state.history.last;
    final remaining = List<CartState>.from(state.history)..removeLast();
    emit(previous.copyWith(history: remaining));
  }
}