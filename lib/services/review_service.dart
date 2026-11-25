import 'common_service.dart';

class ReviewRequest {
  final int productId;
  final int rating;
  final String comment;
  final String userName;
  final int orderItemId;

  ReviewRequest({
    required this.productId,
    required this.rating,
    required this.comment,
    required this.userName,
    required this.orderItemId,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'rating': rating,
      'comment': comment,
      'userName': userName,
      'orderItemId': orderItemId,
    };
  }
}

class ReviewService extends CommonService {
  Future<void> submitReview(ReviewRequest request) async {
    try {
      await post('/api/v1/reviews', data: request.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getProductReviews(int productId, {int page = 0, int size = 20}) async {
    try {
      final response = await get('/api/v1/reviews/product/$productId', queryParameters: {'page': page, 'size': size});
      if (response.data != null) {
        if (response.data is Map && response.data['content'] != null) {
          return List<Map<String, dynamic>>.from(response.data['content']);
        } else if (response.data is Map && response.data['data'] != null) {
          final data = response.data['data'];
          if (data is Map && data['content'] != null) {
            return List<Map<String, dynamic>>.from(data['content']);
          } else if (data is List) {
            return List<Map<String, dynamic>>.from(data);
          }
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
