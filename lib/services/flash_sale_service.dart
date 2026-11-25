import '../models/flash_sale_model.dart';
import 'common_service.dart';

class FlashSaleService extends CommonService {
  Future<List<FlashSale>> getActiveFlashSales() async {
    try {
      final response = await get('/api/flash-sales/active');
      if (response.data != null && response.data is List) {
        final List<dynamic> list = response.data;
        return list.map((e) => FlashSale.fromJson(e)).toList();
      } else if (response.data != null && response.data['data'] != null) {
        final List<dynamic> list = response.data['data'];
        return list.map((e) => FlashSale.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}
