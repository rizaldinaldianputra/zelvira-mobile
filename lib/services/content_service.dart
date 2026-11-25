import '../models/content_section_model.dart';
import 'common_service.dart';

class ContentService extends CommonService {
  Future<List<ContentItem>> getItemsByType(String type, {bool activeOnly = false}) async {
    try {
      // Fetch MOBILE-specific + ALL-platform items for this type
      final responses = await Future.wait([
        get('/api/v1/content/items/type/$type', queryParameters: {
          'platform': 'MOBILE',
          'activeOnly': activeOnly.toString(),
        }),
        get('/api/v1/content/items/type/$type', queryParameters: {
          'platform': 'ALL',
          'activeOnly': activeOnly.toString(),
        }),
      ]);

      final List<ContentItem> items = [];
      for (final response in responses) {
        if (response.data != null && response.data is List) {
          final List<dynamic> list = response.data;
          items.addAll(list.map((e) => ContentItem.fromJson(e)).toList());
        }
      }
      // Deduplicate by id
      final seen = <int>{};
      return items.where((e) => e.id == null || seen.add(e.id!)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<ContentItem>> getAllMobileItems() async {
    try {
      final response = await get('/api/v1/content/items?platform=MOBILE');
      if (response.data != null && response.data is List) {
        final List<dynamic> list = response.data;
        return list.map((e) => ContentItem.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ContentSection>> getSections() async {
    try {
      final response = await get('/api/v1/content/sections?platform=MOBILE');
      if (response.data != null && response.data is List) {
        final List<dynamic> list = response.data;
        return list.map((e) => ContentSection.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}
