import '../models/product_model.dart';
import 'common_service.dart';

class ProductService extends CommonService {
  Future<List<Product>> getRecommendedProducts() async {
    try {
      final response = await get('/api/v1/products/recommended?size=6');
      if (response.data != null && response.data['content'] != null) {
        final List<dynamic> list = response.data['content'];
        return list.map((e) => Product.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Product>> getTrendingProducts() async {
    try {
      final response = await get('/api/v1/products/top?size=6');
      if (response.data != null && response.data['content'] != null) {
        final List<dynamic> list = response.data['content'];
        return list.map((e) => Product.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Product>> searchProducts({String? query, int? categoryId, int page = 0, int size = 10}) async {
    try {
      final response = await get(
        '/api/v1/products',
        queryParameters: {
          'search': query,
          'categoryId': categoryId,
          'page': page,
          'size': size,
        },
      );
      if (response.data != null && response.data['content'] != null) {
        final List<dynamic> list = response.data['content'];
        return list.map((e) => Product.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Product>> getProductsByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    try {
      final response = await get(
        '/api/v1/products/list',
        queryParameters: {
          'ids': ids.join(','),
        },
      );
      if (response.data != null && response.data is List) {
        final List<dynamic> list = response.data;
        return list.map((e) => Product.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Product>> getFeaturedProducts({int page = 0, int size = 10}) async {
    try {
      final response = await get(
        '/api/v1/products/featured',
        queryParameters: {
          'page': page,
          'size': size,
        },
      );
      if (response.data != null && response.data['content'] != null) {
        final List<dynamic> list = response.data['content'];
        return list.map((e) => Product.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Product?> getProductById(int id) async {
    try {
      final response = await get('/api/v1/products/$id');
      if (response.data != null) {
        final data = response.data is Map && response.data['data'] != null
            ? response.data['data']
            : response.data;
        return Product.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Product?> getProductBySlug(String slug) async {
    try {
      final response = await get('/api/v1/products/slug/$slug');
      if (response.data != null) {
        final data = response.data is Map && response.data['data'] != null
            ? response.data['data']
            : response.data;
        return Product.fromJson(data);
      }
      return null;
    } catch (e) {
      final results = await searchProducts(query: slug, size: 1);
      return results.isNotEmpty ? results.first : null;
    }
  }
}
