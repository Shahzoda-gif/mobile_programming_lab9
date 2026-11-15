class Product {
  const Product({required this.id, required this.name, required this.price});
  final String id;
  final String name;
  final double price;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          other.id == id &&
          other.name == name &&
          other.price == price;

  @override
  int get hashCode => Object.hash(id, name, price);
}


const catalog = [
  Product(id: 'p1', name: 'Keyboard', price: 49),
  Product(id: 'p2', name: 'Mouse', price: 25),
  Product(id: 'p3', name: 'Monitor', price: 199),
];

class CartLine {
  const CartLine({required this.product, required this.qty});
  final Product product;
  final int qty;

  double get subtotal => product.price * qty;

  CartLine copyWith({int? qty}) => CartLine(product: product, qty: qty ?? this.qty);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartLine && other.product == product && other.qty == qty;

  @override
  int get hashCode => Object.hash(product, qty);
}

extension CartLines on List<CartLine> {
  List<CartLine> withProduct(Product p) {
    final i = indexWhere((l) => l.product.id == p.id);
    if (i == -1) return [...this, CartLine(product: p, qty: 1)];
    return [
      for (final l in this)
        l.product.id == p.id ? l.copyWith(qty: l.qty + 1) : l
    ];
  }

  List<CartLine> without(String productId) =>
      [for (final l in this) if (l.product.id != productId) l];

  List<CartLine> changeQty(String productId, int delta) {
    return [
      for (final l in this)
        if (l.product.id == productId)
          if (l.qty + delta > 0) l.copyWith(qty: l.qty + delta) else null
        else
          l
    ].whereType<CartLine>().toList();
  }

  double get subtotal => fold(0, (s, l) => s + l.subtotal);
  int get itemCount => fold(0, (s, l) => s + l.qty);
}

const _unset = Object();

class CartState {
  const CartState({
    this.lines = const [],
    this.coupon,
    this.couponError,
    this.status = CheckoutStatus.idle,
    this.orderId,
    this.checkoutError,
    this.history = const [],
  });

  final List<CartLine> lines;
  final String? coupon;
  final String? couponError;
  final CheckoutStatus status;
  final String? orderId;
  final String? checkoutError;
  final List<CartState> history;

  int get itemCount => lines.itemCount;
  double get subtotal => lines.subtotal;

  double get discount {
    if (coupon == 'SAVE10') return subtotal * 0.10;
    return 0.0;
  }

  double get total => subtotal - discount;

  CartState copyWith({
    List<CartLine>? lines,
    Object? coupon = _unset,
    Object? couponError = _unset,
    CheckoutStatus? status,
    Object? orderId = _unset,
    Object? checkoutError = _unset,
    List<CartState>? history,
  }) {
    return CartState(
      lines: lines ?? this.lines,
      coupon: coupon == _unset ? this.coupon : coupon as String?,
      couponError:
          couponError == _unset ? this.couponError : couponError as String?,
      status: status ?? this.status,
      orderId: orderId == _unset ? this.orderId : orderId as String?,
      checkoutError: checkoutError == _unset
          ? this.checkoutError
          : checkoutError as String?,
      history: history ?? this.history,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CartState) return false;
    if (lines.length != other.lines.length) return false;
    for (var i = 0; i < lines.length; i++) {
      if (lines[i] != other.lines[i]) return false;
    }
    return other.coupon == coupon &&
        other.couponError == couponError &&
        other.status == status &&
        other.orderId == orderId &&
        other.checkoutError == checkoutError &&
        other.history.length == history.length;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(lines),
        coupon,
        couponError,
        status,
        orderId,
        checkoutError,
        history.length,
      );
}

enum CheckoutStatus { idle, submitting, success, failure }