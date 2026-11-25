import 'package:flutter/material.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeatureIds {
  static const String search = 'feature_search';
  static const String notification = 'feature_notification';
  static const String chatSupport = 'feature_chat_support';
  static const String wishlist = 'feature_wishlist';
  static const String bottomNav = 'feature_bottom_nav';

  static const List<String> allSteps = [
    search,
    notification,
    chatSupport,
    wishlist,
    bottomNav,
  ];
}

class FeatureDiscoveryHelper {
  static const String prefKey = 'has_seen_feature_discovery';

  /// Trigger feature discovery overlay for first-time users
  static Future<void> checkAndStartDiscovery(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool(prefKey) ?? false;
    if (!hasSeen && context.mounted) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!context.mounted) return;
      FeatureDiscovery.discoverFeatures(context, FeatureIds.allSteps);
      await prefs.setBool(prefKey, true);
    }
  }

  /// Replay the feature discovery tour (e.g. from Settings or Help)
  static Future<void> replayDiscovery(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKey, false);
    if (context.mounted) {
      await FeatureDiscovery.clearPreferences(context, FeatureIds.allSteps);
      if (context.mounted) {
        FeatureDiscovery.discoverFeatures(context, FeatureIds.allSteps);
      }
    }
  }
}
