import 'common_service.dart';

class NotificationModel {
  final int id;
  final String title;
  final String body;
  final String? type;
  final bool isRead;
  final String? dataPayload;
  final String? createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.type,
    required this.isRead,
    this.dataPayload,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'],
      isRead: json['isRead'] ?? false,
      dataPayload: json['dataPayload'],
      createdAt: json['createdAt']?.toString(),
    );
  }
}

class NotificationService extends CommonService {
  Future<List<NotificationModel>> getMyNotifications() async {
    try {
      final response = await get('/api/v1/notifications');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data is List) {
          return data.map((e) => NotificationModel.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await get('/api/v1/notifications/unread-count');
      if (response.statusCode == 200 && response.data != null) {
        return (response.data['data'] as num?)?.toInt() ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await patch('/api/v1/notifications/$id/read');
    } catch (e) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await patch('/api/v1/notifications/read-all');
    } catch (e) {}
  }

  Future<void> clearNotifications() async {
    try {
      await delete('/api/v1/notifications/clear');
    } catch (e) {}
  }
}
