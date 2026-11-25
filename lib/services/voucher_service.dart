import '../models/voucher_model.dart';
import '../models/user_voucher_model.dart';
import 'common_service.dart';

class VoucherService extends CommonService {
  Future<List<VoucherModel>> getAvailableVouchers() async {
    try {
      final response = await get('/api/vouchers/available');
      if (response.data != null) {
        final List<dynamic> list = response.data;
        return list.map((e) => VoucherModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<UserVoucherModel>> getMyVouchers() async {
    try {
      final response = await get('/api/vouchers/my-vouchers');
      if (response.data != null) {
        final List<dynamic> list = response.data;
        return list.map((e) => UserVoucherModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<UserVoucherModel> claimVoucher(String code) async {
    try {
      final response = await post('/api/vouchers/claim/$code');
      return UserVoucherModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
