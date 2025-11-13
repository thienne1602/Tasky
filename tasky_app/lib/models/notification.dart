class TaskyNotification {
  TaskyNotification({
    required this.id,
    required this.userId,
    this.taskId,
    required this.type,
    required this.title,
    this.message,
    required this.isRead,
    required this.createdAt,
    this.taskTitle,
  });

  final int id;
  final int userId;
  final int? taskId;
  final String type;
  final String title;
  final String? message;
  final bool isRead;
  final DateTime createdAt;
  final String? taskTitle;

  factory TaskyNotification.fromJson(Map<String, dynamic> json) {
    return TaskyNotification(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      taskId: json['task_id'] as int?,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String?,
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: DateTime.parse(json['created_at'] as String),
      taskTitle: json['task_title'] as String?,
    );
  }

  TaskyNotification copyWith({
    int? id,
    int? userId,
    int? taskId,
    String? type,
    String? title,
    String? message,
    bool? isRead,
    DateTime? createdAt,
    String? taskTitle,
  }) {
    return TaskyNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      taskId: taskId ?? this.taskId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      taskTitle: taskTitle ?? this.taskTitle,
    );
  }
}
