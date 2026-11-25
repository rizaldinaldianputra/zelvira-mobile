import '../models/category_model.dart';
import 'common_service.dart';

class CategoryService extends CommonService {
  Future<List<Category>> getCategories({int size = 20}) async {
    try {
      final response = await get('/api/v1/categories?size=$size');
      if (response.data != null) {
        if (response.data is List) {
          final List<dynamic> list = response.data;
          return list.map((e) => Category.fromJson(e)).toList();
        } else if (response.data['content'] != null) {
          final List<dynamic> list = response.data['content'];
          return list.map((e) => Category.fromJson(e)).toList();
        } else if (response.data['data'] != null && response.data['data'] is List) {
          final List<dynamic> list = response.data['data'];
          return list.map((e) => Category.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
