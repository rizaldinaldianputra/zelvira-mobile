import '../models/wallet_model.dart';
import 'common_service.dart';

class WalletService extends CommonService {
  Future<WalletResponse> getWalletInfo() async {
    try {
      final response = await get('/api/v1/wallet');
      return WalletResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> initiateTopup(double amount) async {
    try {
      final response = await post(
        '/api/v1/wallet/topup',
        data: {'amount': amount},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> resumeTopup(int transactionId) async {
    try {
      final response = await post(
        '/api/v1/wallet/topup/$transactionId/resume',
        data: {},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  /// Verify topup payment status directly from Midtrans via backend.
  /// Automatically credits balance if payment was successful.
  Future<Map<String, dynamic>> verifyTopup(int transactionId) async {
    try {
      final response = await post(
        '/api/v1/wallet/topup/$transactionId/verify',
        data: {},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}

