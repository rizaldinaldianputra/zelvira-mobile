import '../models/product_model.dart';
import 'common_service.dart';

class WishlistItem {
  final int id;
  final Product product;

  WishlistItem({required this.id, required this.product});

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('product') && json['product'] is Map) {
      return WishlistItem(
        id: json['id'] ?? 0,
        product: Product.fromJson(json['product'] ?? {}),
      );
    }

    final pId = json['productId'] ?? json['id'] ?? 0;
    final pName = json['productName'] ?? json['name'] ?? '';
    final pSlug = json['slug'] ?? '';
    final pPrice = (json['price'] ?? 0).toDouble();
    final pImage = json['imageUrl'] ?? '';

    return WishlistItem(
      id: json['id'] ?? 0,
      product: Product(
        id: pId,
        name: pName,
        slug: pSlug,
        categoryId: 0,
        imageUrl: pImage,
        images: pImage.isNotEmpty ? [pImage] : [],
        isActive: true,
        isFeatured: false,
        isTopProduct: false,
        isBestSeller: false,
        isRecommended: false,
        variants: [
          ProductVariant(
            id: 0,
            sku: '',
            price: pPrice,
            stock: 100,
            isActive: true,
            imageUrl: pImage,
          ),
        ],
      ),
    );
  }
}

class WishlistService extends CommonService {
  Future<List<WishlistItem>> getWishlist() async {
    try {
      final response = await get('/api/v1/wishlist');
      if (response.data != null && response.data['data'] != null) {
        final List<dynamic> list = response.data['data'];
        return list.map((e) => WishlistItem.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleWishlist(int productId) async {
    try {
      await post('/api/v1/wishlist/$productId');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeFromWishlist(int id) async {
    try {
      await delete('/api/v1/wishlist/$id');
    } catch (e) {
      rethrow;
    }
  }
}
