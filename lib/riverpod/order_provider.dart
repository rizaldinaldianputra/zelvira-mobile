import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/checkout_model.dart';
import '../services/order_service.dart';

final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService();
});

class OrderNotifier extends StateNotifier<AsyncValue<List<OrderResponse>>> {
  final OrderService _orderService;

  OrderNotifier(this._orderService) : super(const AsyncValue.loading()) {
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      state = const AsyncValue.loading();
      // Sort DESC locally to be safe
      final orders = await _orderService.getMyOrders();

      // Auto-sync status for PENDING orders with payment tokens
      for (var o in orders) {
        if (o.status.toUpperCase() == 'PENDING' && o.paymentToken != null && o.id > 0) {
          _orderService.syncPaymentStatus(o.id).catchError((_) => null);
        }
      }

      orders.sort((a, b) {
        if (a.createdAt != null && b.createdAt != null) {
          try {
            return DateTime.parse(b.createdAt!).compareTo(DateTime.parse(a.createdAt!));
          } catch (e) {
            return b.id.compareTo(a.id);
          }
        }
        return b.id.compareTo(a.id);
      });
      state = AsyncValue.data(orders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, AsyncValue<List<OrderResponse>>>((ref) {
  final service = ref.read(orderServiceProvider);
  return OrderNotifier(service);
});
