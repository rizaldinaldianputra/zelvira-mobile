import '../models/digital_order_model.dart';
import 'common_service.dart';

class DigitalOrderService extends CommonService {
  Future<DigitalOrderResponse> createDigitalOrder(DigitalOrderRequest request) async {
    try {
      final response = await post(
        '/api/orders/digital/create',
        data: request.toJson(),
      );
      if (response.data != null) {
        return DigitalOrderResponse.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Gagal membuat pesanan digital');
    } catch (e) {
      rethrow;
    }
  }

  Future<DigitalOrderResponse> getDigitalOrderStatus(String orderNumber) async {
    try {
      final response = await get('/api/orders/digital/$orderNumber');
      if (response.data != null) {
        return DigitalOrderResponse.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Pesanan tidak ditemukan');
    } catch (e) {
      rethrow;
    }
  }

  Future<DigiflazzResponse<DigiflazzTransactionResponse>> processPrepaidOrder(DigitalOrderRequest request) async {
    try {
      final response = await post(
        '/api/orders/prepaid',
        data: request.toJson(),
      );
      return DigiflazzResponse.fromJson(
        response.data,
        (json) => DigiflazzTransactionResponse.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<DigiflazzResponse<DigiflazzTransactionResponse>> processPostpaidInquiry(DigitalOrderRequest request) async {
    try {
      final response = await post(
        '/api/orders/postpaid/inquiry',
        data: request.toJson(),
      );
      return DigiflazzResponse.fromJson(
        response.data,
        (json) => DigiflazzTransactionResponse.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<DigiflazzResponse<DigiflazzTransactionResponse>> processPostpaidPay(
      String skuCode, String customerNo, double amount, String refId) async {
    try {
      final response = await post(
        '/api/orders/postpaid/pay',
        data: {
          'skuCode': skuCode,
          'customerNo': customerNo,
          'amount': amount,
          'refId': refId,
        },
      );
      return DigiflazzResponse.fromJson(
        response.data,
        (json) => DigiflazzTransactionResponse.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }
}
