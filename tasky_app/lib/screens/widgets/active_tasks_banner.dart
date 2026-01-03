import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../theme/palette.dart';
import '../../widgets/deadline_urgency_icon.dart';
import '../../widgets/task_progress_indicator.dart';

class ActiveTasksBanner extends StatelessWidget {
  const ActiveTasksBanner({
    super.key,
    required this.onOpenTask,
  });

  final Function(Task) onOpenTask;

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().currentUser?.id;
    if (userId == null) return const SizedBox.shrink();

    final tasks = context.watch<TaskProvider>().myTasks(userId);
    final activeTasks = tasks.where((t) => t.status != 'done').toList();

    if (activeTasks.isEmpty) return const SizedBox.shrink();

    // Lấy task gần deadline nhất
    activeTasks.sort((a, b) {
      if (a.deadline == null) return 1;
      if (b.deadline == null) return -1;
      return a.deadline!.compareTo(b.deadline!);
    });

    final urgentTask = activeTasks.first;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            TaskyPalette.lavender.withOpacity(0.2),
            TaskyPalette.mint.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: TaskyPalette.lavender.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '🔥',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Task đang có (${activeTasks.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              DeadlineUrgencyIcon(
                deadline: urgentTask.deadline,
                size: 28,
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => onOpenTask(urgentTask),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: TaskyPalette.midnight.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    urgentTask.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  TaskProgressIndicator(status: urgentTask.status),
                  if (urgentTask.deadline != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: TaskyPalette.midnight.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDeadline(urgentTask.deadline!),
                          style: TextStyle(
                            fontSize: 12,
                            color: TaskyPalette.midnight.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (activeTasks.length > 1) ...[
            const SizedBox(height: 12),
            Text(
              '+ ${activeTasks.length - 1} task khác đang chờ bạn 💪',
              style: TextStyle(
                fontSize: 12,
                color: TaskyPalette.midnight.withOpacity(0.85),
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      return 'Đã quá hạn!';
    } else if (difference.inHours < 24) {
      return 'Còn ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Còn ${difference.inDays} ngày';
    } else {
      return 'Còn ${(difference.inDays / 7).floor()} tuần';
    }
  }
}
