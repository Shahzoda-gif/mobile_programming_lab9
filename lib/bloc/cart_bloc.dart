import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/cart.dart';
import '../services/checkout_api.dart';
import 'cart_event.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc({CheckoutApi? api})
      : _api = api ?? CheckoutApi(),
        super(const CartState()) {
    on<CartItemAdded>(_onItemAdded);
    on<CartItemRemoved>(_onItemRemoved);
    on<CartQtyChanged>(_onQtyChanged);
    on<CartCouponApplied>(_onCouponApplied);
    on<CartCheckoutRequested>(_onCheckoutRequested);
    on<CartUndoRequested>(_onUndoRequested);
  }

  final CheckoutApi _api;

  void _emitWithHistory(Emitter<CartState> emit, CartState next) {
    final nextHistory = [...state.history, state];
    emit(next.copyWith(history: nextHistory));
  }

  void _onItemAdded(CartItemAdded event, Emitter<CartState> emit) {
    _emitWithHistory(
      emit,
      state.copyWith(lines: state.lines.withProduct(event.product)),
    );
  }

  void _onItemRemoved(CartItemRemoved event, Emitter<CartState> emit) {
    _emitWithHistory(
      emit,
      state.copyWith(lines: state.lines.without(event.productId)),
    );
  }

  void _onQtyChanged(CartQtyChanged event, Emitter<CartState> emit) {
    _emitWithHistory(
      emit,
      state.copyWith(lines: state.lines.changeQty(event.productId, event.delta)),
    );
  }

  void _onCouponApplied(CartCouponApplied event, Emitter<CartState> emit) {
    if (event.code == 'SAVE10') {
      _emitWithHistory(
        emit,
        state.copyWith(coupon: event.code, couponError: null),
      );
    } else {
      _emitWithHistory(
        emit,
        state.copyWith(couponError: 'Invalid coupon'),
      );
    }
  }

  Future<void> _onCheckoutRequested(
    CartCheckoutRequested event,
    Emitter<CartState> emit,
  ) async {
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

  void _onUndoRequested(CartUndoRequested event, Emitter<CartState> emit) {
    if (state.history.isEmpty) return;
    final previous = state.history.last;
    final remaining = List<CartState>.from(state.history)..removeLast();
    emit(previous.copyWith(history: remaining));
  }
}