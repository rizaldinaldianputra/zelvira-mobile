import 'common_service.dart';

class SupportService extends CommonService {
  Future<List<dynamic>> getHelpArticles() async {
    try {
      final response = await get('/api/v1/help-articles/active');
      if (response.data != null && response.data is List) {
        return response.data;
      }
      final fallback = await get('/api/v1/help-articles?onlyActive=true');
      if (fallback.data != null && fallback.data is List) {
        return fallback.data;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getFaqs() async {
    try {
      final response = await get('/api/v1/faqs/active');
      if (response.data != null && response.data is List) {
        return response.data;
      }
      final fallback = await get('/api/v1/faqs?onlyActive=true');
      if (fallback.data != null && fallback.data is List) {
        return fallback.data;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getPrivacyPolicy() async {
    try {
      final response = await get('/api/v1/privacy-policy/active');
      if (response.data != null && response.data is Map<String, dynamic>) {
        return response.data;
      }
      if (response.data != null && response.data is List && (response.data as List).isNotEmpty) {
        return (response.data as List).first as Map<String, dynamic>;
      }
    } catch (_) {}

    try {
      final response = await get('/api/v1/privacy-policy/current');
      if (response.data != null && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['isActive'] != false) {
          return data;
        }
      }
    } catch (_) {}

    try {
      final fallback = await get('/api/v1/privacy-policy?onlyActive=true');
      if (fallback.data != null && fallback.data is List && (fallback.data as List).isNotEmpty) {
        return (fallback.data as List).first as Map<String, dynamic>;
      }
      if (fallback.data != null && fallback.data is Map<String, dynamic>) {
        return fallback.data;
      }
    } catch (_) {}

    return null;
  }
}
