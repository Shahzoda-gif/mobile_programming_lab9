import '../models/cart.dart';

sealed class CartEvent {
  const CartEvent();
}

final class CartItemAdded extends CartEvent {
  const CartItemAdded(this.product);
  final Product product;
}

final class CartItemRemoved extends CartEvent {
  const CartItemRemoved(this.productId);
  final String productId;
}

final class CartQtyChanged extends CartEvent {
  const CartQtyChanged(this.productId, this.delta);
  final String productId;
  final int delta;
}

final class CartCouponApplied extends CartEvent {
  const CartCouponApplied(this.code);
  final String code;
}

final class CartCheckoutRequested extends CartEvent {
  const CartCheckoutRequested();
}

final class CartUndoRequested extends CartEvent {
  const CartUndoRequested();
}