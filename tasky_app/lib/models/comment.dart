class Comment {
  Comment({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.userName,
    this.userAvatar,
  });

  final int id;
  final int taskId;
  final int userId;
  final String content;
  final DateTime createdAt;
  final String? userName;
  final String? userAvatar;

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
    id: json['id'] as int,
    taskId: json['task_id'] as int? ?? json['taskId'] as int? ?? 0,
    userId: json['user_id'] as int? ?? json['userId'] as int? ?? 0,
    content: json['content'] as String,
    createdAt: DateTime.parse(
      json['created_at'] as String? ?? json['createdAt'] as String,
    ),
    userName: json['name'] as String? ?? json['user_name'] as String?,
    userAvatar: json['avatar'] as String? ?? json['user_avatar'] as String?,
  );
}
