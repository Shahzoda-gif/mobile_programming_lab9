import 'package:flutter/material.dart';
import '../models/cart.dart';
import '../services/checkout_api.dart';
import '../widgets/cart_body.dart';

class SetStateCartPage extends StatefulWidget {
  const SetStateCartPage({super.key});

  @override
  State<SetStateCartPage> createState() => _SetStateCartPageState();
}

class _SetStateCartPageState extends State<SetStateCartPage> {
  CartState state = const CartState();
  final CheckoutApi _checkoutApi = CheckoutApi();
  final TextEditingController _couponController = TextEditingController();

  void _pushHistory() {
    setState(() {
      state = state.copyWith(
        history: [...state.history, state],
      );
    });
  }

  void add(Product p) {
    _pushHistory();
    setState(() => state = state.copyWith(lines: state.lines.withProduct(p)));
  }

  void remove(String id) {
    _pushHistory();
    setState(() => state = state.copyWith(lines: state.lines.without(id)));
  }

  void changeQty(String id, int delta) {
    _pushHistory();
    setState(() => state = state.copyWith(lines: state.lines.changeQty(id, delta)));
  }

  void applyCoupon(String code) {
    _pushHistory();
    if (code == 'SAVE10') {
      setState(() => state = state.copyWith(coupon: code, couponError: null));
    } else {
      setState(() => state = state.copyWith(couponError: 'Invalid coupon'));
    }
  }

  Future<void> checkout() async {
    setState(() => state = state.copyWith(status: CheckoutStatus.submitting));
    try {
      final orderId = await _checkoutApi.submit(state.total);
      if (!mounted) return;
      setState(() {
        state = state.copyWith(
          status: CheckoutStatus.success,
          orderId: orderId,
          lines: const [],
          coupon: null,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Success! Order ID: $orderId')),
      );
    } on CheckoutException catch (e) {
      if (!mounted) return;
      setState(() => state = state.copyWith(status: CheckoutStatus.failure, checkoutError: e.message));
      showModalBottomSheet(
        context: context,
        builder: (_) => Container(
          padding: const EdgeInsets.all(16),
          color: Colors.red[100],
          child: Text('Checkout Failed: ${e.message}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ),
      );
    }
  }

  void undo() {
    if (state.history.isEmpty) return;
    final previous = state.history.last;
    final newHistory = List<CartState>.from(state.history)..removeLast();
    setState(() {
      state = previous.copyWith(history: newHistory);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart setState'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: state.history.isEmpty ? null : undo,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: CartBody(
              lines: state.lines,
              onAdd: add,
              onRemove: remove,
            ),
          ),
          // Coupon section (T2)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    decoration: InputDecoration(
                      labelText: 'Coupon Code',
                      errorText: state.couponError,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => applyCoupon(_couponController.text),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ),
          // Derived Summary Card (T3)
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Items: ${state.itemCount}'),
                  Text('Subtotal: \$${state.subtotal.toStringAsFixed(2)}'),
                  Text('Discount: \$${state.discount.toStringAsFixed(2)}'),
                  Text('Total: \$${state.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          // Checkout Button (T4)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: state.status == CheckoutStatus.submitting || state.lines.isEmpty ? null : checkout,
              child: state.status == CheckoutStatus.submitting
                  ? const CircularProgressIndicator()
                  : Text('Checkout (\$${state.total.toStringAsFixed(2)})'),
            ),
          ),
        ],
      ),
    );
  }
}