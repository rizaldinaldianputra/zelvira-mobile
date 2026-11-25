import 'package:flutter/material.dart';
import '../routes/app_router.dart';
import 'order_service.dart';

class NotificationNavigationService {
  static String? pendingRoute;
  static dynamic pendingExtra;

  /// Call this when a notification is clicked or tapped (foreground, background, or terminated)
  static Future<void> handleNotificationClick(Map<String, dynamic> data) async {
    debugPrint("🔔 [NotificationNavigationService] Handling payload: $data");

    String? targetRoute;
    dynamic targetExtra;

    final type = (data['type'] ?? '').toString().toUpperCase();
    final clickAction = (data['click_action'] ?? '').toString().toUpperCase();
    final route = (data['route'] ?? '').toString();
    final orderNumber = (data['orderNumber'] ?? data['order_number'])?.toString();
    final orderId = (data['orderId'] ?? data['order_id'])?.toString();

    // 1. Explicit in-app route provided
    if (route.isNotEmpty && route.startsWith('/')) {
      targetRoute = route;
    }
    // 2. Chat / CS Support
    else if (type == 'CHAT' ||
        clickAction == 'CHAT_SUPPORT' ||
        route == '/support/chat') {
      targetRoute = '/support/chat';
    }
    // 3. Order detail or Order list
    else if (type == 'ORDER' ||
        clickAction == 'ORDER_DETAIL' ||
        orderNumber != null ||
        orderId != null) {
      if (orderNumber != null && orderNumber.isNotEmpty) {
        try {
          final order = await OrderService().getOrderByNumber(orderNumber);
          if (order != null) {
            targetRoute = '/order-detail';
            targetExtra = order;
          } else {
            targetRoute = '/home/3'; // Tab Pesanan fallback
          }
        } catch (e) {
          debugPrint("Failed to fetch order detail for notification: $e");
          targetRoute = '/home/3'; // Tab Pesanan fallback
        }
      } else {
        targetRoute = '/home/3'; // Tab Pesanan
      }
    }
    // 4. News
    else if (type == 'NEWS' || clickAction == 'NEWS_DETAIL') {
      targetRoute = '/home/1'; // Tab News
    }
    // 5. Promo / Voucher
    else if (type == 'PROMO' ||
        type == 'VOUCHER' ||
        clickAction == 'VOUCHER_LIST') {
      targetRoute = '/profile/vouchers';
    }
    // 6. Generic Notification
    else {
      targetRoute = '/notifications';
    }

    pendingRoute = targetRoute;
    pendingExtra = targetExtra;
    _dispatchNavigation(targetRoute, targetExtra);
  }

  static void _dispatchNavigation(String route, dynamic extra) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (extra != null) {
          AppRouter.router.push(route, extra: extra);
        } else {
          AppRouter.router.push(route);
        }
      } catch (e) {
        debugPrint("[NotificationNavigationService] Navigation dispatch error: $e");
      }
    });
  }

  /// Consume pending route when splash screen finishes
  static String? consumePendingRoute() {
    final route = pendingRoute;
    pendingRoute = null;
    return route;
  }

  /// Consume pending extra arguments when splash screen finishes
  static dynamic consumePendingExtra() {
    final extra = pendingExtra;
    pendingExtra = null;
    return extra;
  }
}
