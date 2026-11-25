import '../models/shipping_model.dart';
import 'common_service.dart';

class ShippingService extends CommonService {
  Future<List<Province>> getProvinces() async {
    try {
      final response = await get('/api/v1/shipping/provinces');
      if (response.data != null && response.data['data'] != null) {
        final List<dynamic> list = response.data['data'];
        return list.map((e) => Province.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<City>> getCities(String provinceId) async {
    try {
      final response = await get('/api/v1/shipping/cities', queryParameters: {'provinceId': provinceId});
      if (response.data != null && response.data['data'] != null) {
        final List<dynamic> list = response.data['data'];
        return list.map((e) => City.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<District>> getDistricts(String cityId) async {
    try {
      final response = await get('/api/v1/shipping/districts', queryParameters: {'cityId': cityId});
      if (response.data != null && response.data['data'] != null) {
        final List<dynamic> list = response.data['data'];
        return list.map((e) => District.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Subdistrict>> getSubdistricts(String districtId) async {
    try {
      final response = await get('/api/v1/shipping/sub-districts', queryParameters: {'districtId': districtId});
      if (response.data != null && response.data['data'] != null) {
        final List<dynamic> list = response.data['data'];
        return list.map((e) => Subdistrict.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ShippingCourierResponse>> calculateCost({
    required String origin,
    required String destination,
    required int weight,
    required String courier,
  }) async {
    try {
      final response = await post('/api/v1/shipping/cost', data: {
        'origin': origin,
        'destination': destination,
        'weight': weight,
        'courier': courier,
      });

      if (response.data != null && response.data['data'] != null) {
        final List<dynamic> list = response.data['data'];
        return list.map((e) => ShippingCourierResponse.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> trackWaybill(String awb, String courier, {String? phone}) async {
    try {
      final queryParams = <String, dynamic>{
        'awb': awb.trim(),
        'courier': courier.toLowerCase().trim(),
      };
      if (phone != null && phone.trim().isNotEmpty) {
        final clean = phone.replaceAll(RegExp(r'\D'), '');
        final last5 = clean.length >= 5 ? clean.substring(clean.length - 5) : clean;
        if (last5.isNotEmpty) {
          queryParams['phone'] = last5;
        }
      }
      final response = await post('/api/v1/shipping/track', queryParameters: queryParams);
      if (response.data != null && response.data['data'] != null) {
        final rawData = response.data['data'];
        if (rawData is Map<String, dynamic>) {
          if (rawData['data'] is Map<String, dynamic>) {
            return Map<String, dynamic>.from(rawData['data']);
          }
          if (rawData['rajaongkir'] != null && rawData['rajaongkir']['result'] is Map<String, dynamic>) {
            return Map<String, dynamic>.from(rawData['rajaongkir']['result']);
          }
          return rawData;
        }
      }
      return {};
    } catch (e) {
      rethrow;
    }
  }
}
