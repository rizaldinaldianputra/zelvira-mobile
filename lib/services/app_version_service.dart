import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_url.dart';
import '../models/app_version_model.dart';

enum AppUpdateType {
  none, // tidak muncul update
  optional, // boleh lewati update
  force, // wajib update
}

class AppUpdateCheckResult {
  final AppUpdateType type;
  final AppVersionModel model;
  final String currentVersion;

  AppUpdateCheckResult({
    required this.type,
    required this.model,
    required this.currentVersion,
  });
}

class AppVersionService {
  // Current installed app version (from pubspec 1.0.0+1)
  static const String currentAppVersion = '1.0.0';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
      },
    ),
  );

  /// Fetch version policy from backend
  Future<AppVersionModel?> fetchMobileSettings() async {
    try {
      final response = await _dio.get('/api/settings/mobile');
      if (response.statusCode == 200 && response.data != null) {
        return AppVersionModel.fromJson(response.data);
      }
    } catch (e) {
      debugPrint('Error fetching mobile settings: $e');
    }
    return null;
  }

  /// Check whether an update is available and determine the update policy
  Future<AppUpdateCheckResult?> checkUpdate({String? installedVersion}) async {
    final version = installedVersion ?? currentAppVersion;
    final model = await fetchMobileSettings();
    if (model == null) return null;

    final isBelowMin = isVersionLower(version, model.minVersion);
    final isBelowLatest = isVersionLower(version, model.latestVersion);

    AppUpdateType type;
    if (isBelowMin || (model.forceUpdate && isBelowLatest)) {
      type = AppUpdateType.force; // Wajib update
    } else if (isBelowLatest) {
      type = AppUpdateType.optional; // Boleh lewati update
    } else {
      type = AppUpdateType.none; // Tidak muncul update
    }

    return AppUpdateCheckResult(
      type: type,
      model: model,
      currentVersion: version,
    );
  }

  /// Robust Semantic Version comparison: returns true if v1 < v2
  static bool isVersionLower(String v1, String v2) {
    try {
      // Remove build metadata (e.g., 1.0.0+1 -> 1.0.0)
      final cleanV1 = v1.split('+').first.trim();
      final cleanV2 = v2.split('+').first.trim();

      final parts1 = cleanV1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final parts2 = cleanV2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      final maxLength = parts1.length > parts2.length ? parts1.length : parts2.length;
      while (parts1.length < maxLength) {
        parts1.add(0);
      }
      while (parts2.length < maxLength) {
        parts2.add(0);
      }

      for (int i = 0; i < maxLength; i++) {
        if (parts1[i] < parts2[i]) return true;
        if (parts1[i] > parts2[i]) return false;
      }
      return false; // Equal versions
    } catch (e) {
      debugPrint('Version compare error: $e');
      return false;
    }
  }
}
