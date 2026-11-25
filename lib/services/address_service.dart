import '../models/address_model.dart';
import 'common_service.dart';

class AddressService extends CommonService {
  Future<List<AddressResponse>> getUserAddresses() async {
    try {
      final response = await get('/api/v1/addresses');
      if (response.data != null && response.data['data'] != null) {
        final List<dynamic> list = response.data['data'];
        return list.map((e) => AddressResponse.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<AddressResponse> createAddress(AddressRequest request) async {
    try {
      final response = await post('/api/v1/addresses', data: request.toJson());
      if (response.data != null && response.data['data'] != null) {
        return AddressResponse.fromJson(response.data['data']);
      }
      throw Exception('Failed to create address');
    } catch (e) {
      rethrow;
    }
  }

  Future<AddressResponse> updateAddress(int id, AddressRequest request) async {
    try {
      final response = await put('/api/v1/addresses/$id', data: request.toJson());
      if (response.data != null && response.data['data'] != null) {
        return AddressResponse.fromJson(response.data['data']);
      }
      throw Exception('Failed to update address');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAddress(int id) async {
    try {
      await delete('/api/v1/addresses/$id');
    } catch (e) {
      rethrow;
    }
  }
}
