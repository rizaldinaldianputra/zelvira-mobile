import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shipping_model.dart';
import '../services/shipping_service.dart';
import '../models/address_model.dart';
import 'address_provider.dart';

final shippingServiceProvider = Provider<ShippingService>((ref) {
  return ShippingService();
});

final userAddressesProvider = FutureProvider<List<AddressResponse>>((ref) async {
  final service = ref.read(addressServiceProvider);
  return service.getUserAddresses();
});

final provincesProvider = FutureProvider<List<Province>>((ref) async {
  final service = ref.read(shippingServiceProvider);
  return service.getProvinces();
});

final citiesProvider = FutureProvider.family<List<City>, String>((ref, provinceId) async {
  final service = ref.read(shippingServiceProvider);
  return service.getCities(provinceId);
});

final districtsProvider = FutureProvider.family<List<District>, String>((ref, cityId) async {
  final service = ref.read(shippingServiceProvider);
  return service.getDistricts(cityId);
});

class ShippingNotifier extends StateNotifier<AsyncValue<List<ShippingCourierResponse>>> {
  final ShippingService _shippingService;

  ShippingNotifier(this._shippingService) : super(const AsyncValue.data([]));

  Future<void> calculateCost(String destinationId) async {
    state = const AsyncValue.loading();
    try {
      final couriers = ['jne', 'pos', 'tiki'];
      final responses = await Future.wait(
        couriers.map((courier) async {
          try {
            return await _shippingService
                .calculateCost(
                  origin: '501',
                  destination: destinationId,
                  weight: 1000,
                  courier: courier,
                )
                .timeout(const Duration(seconds: 4));
          } catch (_) {
            return <ShippingCourierResponse>[];
          }
        }),
      );

      List<ShippingCourierResponse> allResults = [];
      for (var list in responses) {
        allResults.addAll(list);
      }

      state = AsyncValue.data(allResults);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final shippingProvider = StateNotifierProvider<ShippingNotifier, AsyncValue<List<ShippingCourierResponse>>>((ref) {
  final service = ref.read(shippingServiceProvider);
  return ShippingNotifier(service);
});
