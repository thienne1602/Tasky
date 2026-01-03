class TaskStatistics {
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int inProgressTasks;
  final double completionRate;
  final Map<String, int> tasksByStatus;
  final Map<String, int> tasksByTeam;
  final Map<String, int> tasksByUser;
  final List<TaskCompletionData> completionTrend;
  final List<TeamPerformanceData> teamPerformance;

  TaskStatistics({
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.inProgressTasks,
    required this.completionRate,
    required this.tasksByStatus,
    required this.tasksByTeam,
    required this.tasksByUser,
    required this.completionTrend,
    required this.teamPerformance,
  });

  factory TaskStatistics.fromJson(Map<String, dynamic> json) {
    return TaskStatistics(
      totalTasks: json['totalTasks'] ?? 0,
      completedTasks: json['completedTasks'] ?? 0,
      pendingTasks: json['pendingTasks'] ?? 0,
      inProgressTasks: json['inProgressTasks'] ?? 0,
      completionRate: (json['completionRate'] ?? 0.0).toDouble(),
      tasksByStatus: Map<String, int>.from(json['tasksByStatus'] ?? {}),
      tasksByTeam: Map<String, int>.from(json['tasksByTeam'] ?? {}),
      tasksByUser: Map<String, int>.from(json['tasksByUser'] ?? {}),
      completionTrend: (json['completionTrend'] as List<dynamic>?)
          ?.map((item) => TaskCompletionData.fromJson(item))
          .toList() ?? [],
      teamPerformance: (json['teamPerformance'] as List<dynamic>?)
          ?.map((item) => TeamPerformanceData.fromJson(item))
          .toList() ?? [],
    );
  }
}

class TaskCompletionData {
  final String date;
  final int completed;
  final int total;

  TaskCompletionData({
    required this.date,
    required this.completed,
    required this.total,
  });

  factory TaskCompletionData.fromJson(Map<String, dynamic> json) {
    return TaskCompletionData(
      date: json['date'] ?? '',
      completed: json['completed'] ?? 0,
      total: json['total'] ?? 0,
    );
  }
}

class TeamPerformanceData {
  final String teamName;
  final int completedTasks;
  final int totalTasks;
  final double completionRate;

  TeamPerformanceData({
    required this.teamName,
    required this.completedTasks,
    required this.totalTasks,
    required this.completionRate,
  });

  factory TeamPerformanceData.fromJson(Map<String, dynamic> json) {
    return TeamPerformanceData(
      teamName: json['teamName'] ?? '',
      completedTasks: json['completedTasks'] ?? 0,
      totalTasks: json['totalTasks'] ?? 0,
      completionRate: (json['completionRate'] ?? 0.0).toDouble(),
    );
  }
}
