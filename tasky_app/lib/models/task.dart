import 'comment.dart';

class Task {
  Task({
    required this.id,
    required this.title,
    required this.status,
    this.description,
    this.deadline,
    this.assignedTo,
    this.teamId,
    this.teamName,
    this.assigneeName,
    this.assigneeEmail,
    this.assigneeAvatar,
    this.createdBy,
    this.creatorName,
    this.creatorEmail,
    this.creatorAvatar,
    this.comments = const [],
  });

  final int id;
  final String title;
  final String status;
  final String? description;
  final DateTime? deadline;
  final int? assignedTo;
  final int? teamId;
  final String? teamName;
  final String? assigneeName;
  final String? assigneeEmail;
  final String? assigneeAvatar;
  final int? createdBy;
  final String? creatorName;
  final String? creatorEmail;
  final String? creatorAvatar;
  final List<Comment> comments;

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as int,
        title: json['title'] as String,
        status: json['status'] as String? ?? 'todo',
        description: json['description'] as String?,
        deadline: json['deadline'] != null
            ? DateTime.tryParse(json['deadline'].toString())
            : null,
        assignedTo: json['assigned_to'] as int?,
        teamId: json['team_id'] as int?,
        teamName: json['team_name'] as String?,
        assigneeName: json['assignee_name'] as String?,
        assigneeEmail: json['assignee_email'] as String?,
        assigneeAvatar: json['assignee_avatar'] as String?,
        createdBy: json['created_by'] as int?,
        creatorName: json['creator_name'] as String?,
        creatorEmail: json['creator_email'] as String?,
        creatorAvatar: json['creator_avatar'] as String?,
        comments: (json['comments'] as List<dynamic>? ?? [])
            .map((item) => Comment.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'status': status,
        'description': description,
        'deadline': deadline?.toIso8601String(),
        'assigned_to': assignedTo,
        'team_id': teamId,
        'team_name': teamName,
      };

  Task copyWith({
    String? title,
    String? status,
    String? description,
    DateTime? deadline,
    int? assignedTo,
    List<Comment>? comments,
  }) =>
      Task(
        id: id,
        title: title ?? this.title,
        status: status ?? this.status,
        description: description ?? this.description,
        deadline: deadline ?? this.deadline,
        assignedTo: assignedTo ?? this.assignedTo,
        teamId: teamId,
        teamName: teamName,
        assigneeName: assigneeName,
        assigneeEmail: assigneeEmail,
        assigneeAvatar: assigneeAvatar,
        createdBy: createdBy,
        creatorName: creatorName,
        creatorEmail: creatorEmail,
        creatorAvatar: creatorAvatar,
        comments: comments ?? this.comments,
      );
}
