import 'api_url.dart';

class UrlUtils {
  static String formatImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return '';
    if (path.contains('picsum.photos')) return '';

    // Handle data URLs directly
    if (path.startsWith('data:')) {
      return path;
    }

    // Clean storage URL (no trailing slash)
    String cleanStorageUrl = storageUrl.endsWith('/')
        ? storageUrl.substring(0, storageUrl.length - 1)
        : storageUrl;

    if (cleanStorageUrl.contains('storage.zelvira.my.id')) {
      cleanStorageUrl = cleanStorageUrl.replaceAll(
        'storage.zelvira.my.id',
        'minio.zelvira.my.id',
      );
    } else if (cleanStorageUrl.contains('storage.zelvira.my.id')) {
      cleanStorageUrl = cleanStorageUrl.replaceAll(
        'storage.zelvira.my.id',
        'minio.zelvira.my.id',
      );
    } else if (cleanStorageUrl.contains('minio.zelvira.my.id')) {
      cleanStorageUrl = cleanStorageUrl.replaceAll(
        'minio.zelvira.my.id',
        'minio.zelvira.my.id',
      );
    }

    // REPAIR LOGIC: If it contains legacy, misconfigured, or internal storage endpoints
    final List<String> legacyOrInternalEndpoints = [
      'storage.zelvira.my.id:9000',
      'storage.zelvira.my.id',
      'storage.zelvira.my.id',
      'minio.zelvira.my.id',
      'zelixa-minio:9000',
      'zelvira-minio:9000',
      'minio:9000',
      'localhost:9000',
      '127.0.0.1:9000',
    ];

    for (var endpoint in legacyOrInternalEndpoints) {
      if (path.contains(endpoint)) {
        final parts = path.split(endpoint);
        if (parts.length > 1) {
          final cleanPath = parts[1].startsWith('/')
              ? parts[1]
              : '/${parts[1]}';
          return '$cleanStorageUrl$cleanPath'.replaceAll(RegExp(r'\.$'), '');
        }
      }
    }

    // If it's already an absolute public URL (like Google or placeholder), return as is
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    // Prepend storage URL to relative paths
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$cleanStorageUrl$cleanPath';
  }
}
