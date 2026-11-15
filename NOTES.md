# One Cart, Four Ways — Notes

## Overview
Implemented the same shopping cart flow (`Product`, `CartLine`, `CartState`, `CheckoutApi`) across four Flutter state management approaches: `setState`, Riverpod, Cubit, and Bloc, with unit tests and sequential Git tags (`p1-shared` through `p5-bloc`).

## Checkpoint Notes

### Shared Models & Equality (`p1-shared`)
- Implemented value equality (`==` and `hashCode`) on `Product`, `CartLine`, and `CartState` so state comparisons compare field values rather than object references.
- Updated `CartState.copyWith` with sentinel defaults so nullable fields (`coupon`, `couponError`, `orderId`, `checkoutError`) can either preserve existing values or be explicitly cleared (for example, clearing cart lines and coupon after a successful checkout).

### `setState` (`p2-setstate`)
- Managed `CartState` inside a `StatefulWidget` and updated it via `setState(...)`.
- Calling `setState` rebuilds the entire widget subtree under that `State`, and keeping cart logic inside the widget makes testing business logic independently harder than with dedicated state holders.

### Riverpod (`p3-riverpod`)
- **`ref.read` vs `ref.watch`:** In `RiverpodCartPage`, `ref.watch(cartProvider)` and `ref.watch(canUndoProvider)` subscribe the page to state changes, while `ref.read(cartProvider.notifier)` retrieves the notifier instance to wire callbacks (`notifier.add`, `notifier.remove`, `notifier.undo`, `notifier.checkout`) without subscribing to rebuilds.
- **Selective rebuilds (`SummaryCard`):** `SummaryCard` uses `ref.watch(cartProvider.select(...))` for `total`, `itemCount`, `subtotal`, and `discount`. Because `SummaryCard` only selects pricing/count fields rather than watching the whole `CartState`, it skips rebuilding when unrelated fields (such as `status`, `couponError`, `checkoutError`, or `orderId`) change.
- **Side effects:** `ref.listen` watches `cartProvider.select((s) => s.status)` to trigger a `SnackBar` on `CheckoutStatus.success` and a bottom sheet on `CheckoutStatus.failure`, reading `ref.read(cartProvider)` inside the listener for the latest `orderId` / `checkoutError`.

### Cubit (`p4-cubit`)
- `CartCubit` extends `Cubit<CartState>` and exposes direct methods (`add`, `remove`, `changeQty`, `applyCoupon`, `checkout`, `undo`) that emit new immutable `CartState` instances via `emit(...)`.
- Wired into the widget tree with `BlocProvider`, read with `context.read<CartCubit>()`, rendered with `BlocBuilder`, and listened to for checkout side effects with `BlocListener` (`listenWhen` guarding status transitions).

### Bloc (`p5-bloc`)
- **Cubit vs Bloc:** Cubit invokes methods directly on the cubit (`cubit.add(...)`, `cubit.applyCoupon(...)`), keeping setup concise. Bloc decouples UI actions from state transitions via explicit `CartEvent` subclasses (`CartItemAdded`, `CartItemRemoved`, `CartQtyChanged`, `CartCouponApplied`, `CartCheckoutRequested`, `CartUndoRequested`) dispatched with `bloc.add(...)` and handled by `on<Event>` handlers, making event flow explicit at the cost of extra event boilerplate.

## Comparison Table

| Criteria | `setState` | Riverpod | Cubit | Bloc |
| :--- | :--- | :--- | :--- | :--- |
| Boilerplate | Lowest | Moderate | Moderate | Higher (`CartEvent` classes + `on<Event>`) |
| Separation of UI & logic | Tightly coupled | Separated (`CartNotifier`) | Separated (`CartCubit`) | Separated (`CartBloc` + `CartEvent`) |
| Unit testability | Widget-bound | High (`ProviderContainer` + overrides) | High (`CartCubit` + injected `CheckoutApi`) | High (`CartBloc` + event stream) |
| Rebuild granularity | Subtree-wide on `setState` | Fine-grained via `.select` | `BlocBuilder` / `buildWhen` | `BlocBuilder` / `buildWhen` |
| Side effects | Inside async/event handlers | `ref.listen` | `BlocListener` | `BlocListener` |