import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart.dart';
import '../widgets/cart_body.dart';
import 'cart_notifier.dart';

class RiverpodCartPage extends ConsumerStatefulWidget {
  const RiverpodCartPage({super.key});

  @override
  ConsumerState<RiverpodCartPage> createState() => _RiverpodCartPageState();
}

class _RiverpodCartPageState extends ConsumerState<RiverpodCartPage> {
  final TextEditingController _couponController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);
    final canUndo = ref.watch(canUndoProvider);

    // Listen to checkout status changes for snackbars/banners (T4)
    ref.listen(cartProvider.select((s) => s.status), (prev, next) {
      if (next == CheckoutStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Success! Order ID: ${state.orderId}')),
        );
      } else if (next == CheckoutStatus.failure) {
        showModalBottomSheet(
          context: context,
          builder: (_) => Container(
            padding: const EdgeInsets.all(16),
            color: Colors.red[100],
            child: Text(
              'Checkout Failed: ${state.checkoutError}',
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart Riverpod'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: canUndo ? notifier.undo : null,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: CartBody(
              lines: state.lines,
              onAdd: notifier.add,
              onRemove: notifier.remove,
            ),
          ),
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
                  onPressed: () => notifier.applyCoupon(_couponController.text),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ),
          // Optimized Summary Card showing selective rebuilds (T3)
          const SummaryCard(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: state.status == CheckoutStatus.submitting || state.lines.isEmpty
                  ? null
                  : notifier.checkout,
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

class SummaryCard extends ConsumerWidget {
  const SummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Select only total to demonstrate selective rebuilds (T3)
    final total = ref.watch(cartProvider.select((s) => s.total));
    final itemCount = ref.watch(cartProvider.select((s) => s.itemCount));
    final subtotal = ref.watch(cartProvider.select((s) => s.subtotal));
    final discount = ref.watch(cartProvider.select((s) => s.discount));

    debugPrint('SummaryCard rebuilt!'); // Confirms it doesn't rebuild on unrelated changes

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Items: $itemCount'),
            Text('Subtotal: \$${subtotal.toStringAsFixed(2)}'),
            Text('Discount: \$${discount.toStringAsFixed(2)}'),
            Text('Total: \$${total.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}