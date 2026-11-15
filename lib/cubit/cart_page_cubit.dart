import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/cart.dart';
import '../widgets/cart_body.dart';
import 'cart_cubit.dart';

class CubitCartPage extends StatelessWidget {
  const CubitCartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CartCubit(),
      child: const _CubitCartView(),
    );
  }
}

class _CubitCartView extends StatefulWidget {
  const _CubitCartView();

  @override
  State<_CubitCartView> createState() => _CubitCartViewState();
}

class _CubitCartViewState extends State<_CubitCartView> {
  final TextEditingController _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CartCubit, CartState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == CheckoutStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Success! Order ID: ${state.orderId}')),
          );
        } else if (state.status == CheckoutStatus.failure) {
          showModalBottomSheet(
            context: context,
            builder: (_) => Container(
              padding: const EdgeInsets.all(16),
              color: Colors.red[100],
              child: Text(
                'Checkout Failed: ${state.checkoutError}',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }
      },
      child: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          final cubit = context.read<CartCubit>();
          return Scaffold(
            appBar: AppBar(
              title: const Text('Cart Cubit'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.undo),
                  onPressed: state.history.isEmpty ? null : cubit.undo,
                ),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: CartBody(
                    lines: state.lines,
                    onAdd: cubit.add,
                    onRemove: cubit.remove,
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
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () =>
                            cubit.applyCoupon(_couponController.text),
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ),
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
                        Text(
                          'Total: \$${state.total.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: state.status == CheckoutStatus.submitting ||
                            state.lines.isEmpty
                        ? null
                        : cubit.checkout,
                    child: state.status == CheckoutStatus.submitting
                        ? const CircularProgressIndicator()
                        : Text('Checkout (\$${state.total.toStringAsFixed(2)})'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}