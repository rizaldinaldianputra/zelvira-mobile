import '../models/checkout_model.dart'; // Contains OrderResponse
import 'common_service.dart';

class OrderService extends CommonService {
  Future<List<OrderResponse>> getMyOrders() async {
    try {
      final response = await get('/api/v1/orders/my');
      final digitalResponse = await get('/api/orders/digital/my');

      List<OrderResponse> allOrders = [];

      // Parse Physical Orders
      if (response.statusCode == 200) {
        List<dynamic> list;
        if (response.data is Map && response.data['data'] != null) {
          list = response.data['data'];
        } else if (response.data is List) {
          list = response.data;
        } else {
          list = [];
        }
        allOrders.addAll(list.map((e) => OrderResponse.fromJson(e)).toList());
      }

      // Parse Digital Orders
      if (digitalResponse.statusCode == 200) {
        List<dynamic> dList;
        if (digitalResponse.data is Map &&
            digitalResponse.data['data'] != null) {
          dList = digitalResponse.data['data'];
        } else if (digitalResponse.data is List) {
          dList = digitalResponse.data;
        } else {
          dList = [];
        }

        for (var digitalOrder in dList) {
          String status = 'PENDING';
          String paymentStatus = digitalOrder['paymentStatus'] ?? '';
          String dStatus = digitalOrder['digiflazzStatus'] ?? '';

          if (paymentStatus == 'PAID' && dStatus == 'SUCCESS') {
            status = 'SELESAI';
          } else if (paymentStatus == 'FAILED' ||
              paymentStatus == 'EXPIRED' ||
              dStatus == 'FAILED') {
            status = 'DIBATALKAN';
          }

          allOrders.add(
            OrderResponse(
              id: digitalOrder['id'] ?? 0,
              orderNumber: digitalOrder['orderNumber'] ?? '',
              userId: digitalOrder['userId'] ?? 0,
              totalAmount: (digitalOrder['price'] ?? 0).toDouble(),
              status: status,
              trackingNumber: digitalOrder['digiflazzSn'],
              paymentToken: digitalOrder['paymentToken'],
              paymentUrl: digitalOrder['paymentUrl'],
              shippingAmount: 0.0,
              shippingService: 'Digital Produk',
              createdAt: digitalOrder['createdAt'],
              updatedAt: digitalOrder['updatedAt'],
              items: [
                OrderItemResponse(
                  id: digitalOrder['id'] ?? 0,
                  productId: 0,
                  productName: digitalOrder['productName'] ?? '',
                  groupName: digitalOrder['category'] ?? 'Digital',
                  size: digitalOrder['brand'] ?? '',
                  color: digitalOrder['customerNo'] ?? '',
                  imageUrl: 'https://placehold.co/200x200/png?text=Digital',
                  quantity: 1,
                  price: (digitalOrder['price'] ?? 0).toDouble(),
                ),
              ],
            ),
          );
        }
      }

      return allOrders;
    } catch (e) {
      rethrow;
    }
  }

    Future<OrderResponse?> getOrderByNumber(String orderNumber) async {
    try {
      final response = await get('/api/v1/orders/number/$orderNumber');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        if (data is Map<String, dynamic>) {
          return OrderResponse.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<OrderResponse> checkout(CheckoutRequest request) async {
    try {
      final response = await post('/api/v1/checkout', data: request.toJson());
      if (response.data != null && response.data['data'] != null) {
        return OrderResponse.fromJson(response.data['data']);
      }
      throw Exception('Failed to create order: Invalid response');
    } catch (e) {
      rethrow;
    }
  }

  Future<OrderResponse?> syncPaymentStatus(int orderId) async {
    try {
      final response = await post('/api/v1/orders/$orderId/sync-payment');
      if (response.data != null) {
        return OrderResponse.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<OrderResponse?> updateOrderStatus(int orderId, String status) async {
    try {
      final response = await patch(
        '/api/v1/orders/$orderId/status',
        data: {'status': status},
      );
      if (response.data != null) {
        return OrderResponse.fromJson(response.data);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
