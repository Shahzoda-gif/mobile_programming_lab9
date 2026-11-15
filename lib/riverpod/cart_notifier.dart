import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart.dart';
import '../services/checkout_api.dart';

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  void _pushHistory() {
    state = state.copyWith(
      history: [...state.history, state],
    );
  }

  void add(Product p) {
    _pushHistory();
    state = state.copyWith(lines: state.lines.withProduct(p));
  }

  void remove(String id) {
    _pushHistory();
    state = state.copyWith(lines: state.lines.without(id));
  }

  void changeQty(String id, int delta) {
    _pushHistory();
    state = state.copyWith(lines: state.lines.changeQty(id, delta));
  }

  void applyCoupon(String code) {
    _pushHistory();
    if (code == 'SAVE10') {
      state = state.copyWith(coupon: code, couponError: null);
    } else {
      state = state.copyWith(couponError: 'Invalid coupon');
    }
  }

  Future<void> checkout() async {
    state = state.copyWith(status: CheckoutStatus.submitting);
    try {
      final api = ref.read(checkoutApiProvider);
      final orderId = await api.submit(state.total);
      state = state.copyWith(
        status: CheckoutStatus.success,
        orderId: orderId,
        lines: const [],
        coupon: null,
      );
    } on CheckoutException catch (e) {
      state = state.copyWith(
        status: CheckoutStatus.failure,
        checkoutError: e.message,
      );
    }
  }

  void undo() {
    if (state.history.isEmpty) return;
    final previous = state.history.last;
    final newHistory = List<CartState>.from(state.history)..removeLast();
    state = previous.copyWith(history: newHistory);
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);

final checkoutApiProvider = Provider((ref) => CheckoutApi());

final canUndoProvider = Provider((ref) {
  final history = ref.watch(cartProvider.select((s) => s.history));
  return history.isNotEmpty;
});