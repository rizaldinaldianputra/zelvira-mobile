import '../models/digital_product_model.dart';
import 'common_service.dart';

class DigitalProductConfig {
  final bool enabled;
  final String title;
  final String iconUrl;
  final int activeCount;
  final bool hasActiveProducts;

  DigitalProductConfig({
    required this.enabled,
    required this.title,
    required this.iconUrl,
    required this.activeCount,
    required this.hasActiveProducts,
  });

  factory DigitalProductConfig.fromJson(Map<String, dynamic> json) {
    final enabled = json['enabled'] == true || json['enabled']?.toString() == 'true';
    final activeCount = json['activeCount'] is num
        ? (json['activeCount'] as num).toInt()
        : int.tryParse(json['activeCount']?.toString() ?? '0') ?? 0;
    final hasActive = json['hasActiveProducts'] == true ||
        (enabled && activeCount > 0);

    return DigitalProductConfig(
      enabled: enabled,
      title: json['title']?.toString().isNotEmpty == true ? json['title'].toString() : 'Digital Produk',
      iconUrl: json['iconUrl']?.toString() ?? '',
      activeCount: activeCount,
      hasActiveProducts: hasActive,
    );
  }
}


class DigitalCategoryItem {
  final int id;
  final String code;
  final String name;
  final bool isPostpaid;
  final bool isActive;
  final String? iconName;
  final String? iconUrl;
  final String? colorHex;

  DigitalCategoryItem({
    required this.id,
    required this.code,
    required this.name,
    required this.isPostpaid,
    required this.isActive,
    this.iconName,
    this.iconUrl,
    this.colorHex,
  });

  factory DigitalCategoryItem.fromJson(Map<String, dynamic> json) {
    return DigitalCategoryItem(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      isPostpaid: json['isPostpaid'] ?? json['is_postpaid'] ?? false,
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      iconName: json['iconName']?.toString() ?? json['icon_name']?.toString(),
      iconUrl: json['iconUrl']?.toString() ?? json['icon_url']?.toString(),
      colorHex: json['colorHex']?.toString() ?? json['color_hex']?.toString(),
    );
  }
}

class DigitalProductService extends CommonService {
  Future<List<DigitalProduct>> getProducts({String? category, bool? isPostpaid}) async {
    try {
      final Map<String, dynamic> params = {};
      if (category != null && category.isNotEmpty) {
        params['category'] = category;
      }
      if (isPostpaid != null) {
        params['isPostpaid'] = isPostpaid;
      }

      final response = await get(
        '/api/products/digital',
        queryParameters: params.isNotEmpty ? params : null,
      );
      if (response.data != null && response.data is List) {
        final List<dynamic> list = response.data;
        return list.map((e) => DigitalProduct.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> getCategories({bool? isPostpaid, bool onlyActive = true}) async {
    try {
      final Map<String, dynamic> params = {'onlyActive': onlyActive};
      if (isPostpaid != null) {
        params['isPostpaid'] = isPostpaid;
      }
      final response = await get(
        '/api/products/digital/categories',
        queryParameters: params,
      );
      if (response.data != null && response.data is List) {
        return (response.data as List).map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<DigitalCategoryItem>> getCategoriesList({bool? isPostpaid, bool onlyActive = true}) async {
    try {
      final Map<String, dynamic> params = {'onlyActive': onlyActive};
      if (isPostpaid != null) {
        params['isPostpaid'] = isPostpaid;
      }
      final response = await get(
        '/api/products/digital/categories-list',
        queryParameters: params,
      );
      if (response.data != null && response.data is List) {
        return (response.data as List)
            .map((e) => DigitalCategoryItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<DigitalProductConfig> getConfig() async {
    try {
      final response = await get('/api/products/digital/config');
      if (response.data != null && response.data is Map<String, dynamic>) {
        return DigitalProductConfig.fromJson(response.data as Map<String, dynamic>);
      }
      return DigitalProductConfig(
        enabled: true,
        title: 'Digital Produk',
        iconUrl: '',
        activeCount: 0,
        hasActiveProducts: false,
      );
    } catch (e) {
      return DigitalProductConfig(
        enabled: true,
        title: 'Digital Produk',
        iconUrl: '',
        activeCount: 0,
        hasActiveProducts: false,
      );
    }
  }

  Future<DigitalProduct?> getProductBySku(String sku) async {
    try {
      final response = await get('/api/products/digital/$sku');
      if (response.data != null) {
        return DigitalProduct.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
