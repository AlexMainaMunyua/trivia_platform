class AppNotification {
  final int id;
  final int userId;
  final String type;
  final String message;
  final bool isRead;
  final Map<String, dynamic>? data;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    required this.isRead,
    this.data,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'],
      message: json['message'],
      isRead: json['is_read'],
      data: json['data'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}