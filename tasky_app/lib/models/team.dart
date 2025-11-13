import 'user.dart';
import 'task.dart';

class Team {
  Team({
    required this.id,
    required this.name,
    this.description,
    this.progress = 0,
    this.members = const [],
    this.tasks = const [],
  });

  final int id;
  final String name;
  final String? description;
  final int progress;
  final List<User> members;
  final List<Task> tasks;

  factory Team.fromJson(Map<String, dynamic> json) => Team(
    id: json['id'] as int,
    name: json['name'] as String,
    description: json['description'] as String?,
    progress: json['progress'] is int
        ? json['progress'] as int
        : int.tryParse(json['progress']?.toString() ?? '0') ?? 0,
    members: (json['members'] as List<dynamic>? ?? [])
        .map((item) => User.fromJson(item as Map<String, dynamic>))
        .toList(),
    tasks: (json['tasks'] as List<dynamic>? ?? [])
        .map((item) => Task.fromJson(item as Map<String, dynamic>))
        .toList(),
  );
}
