import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/task.dart';
import '../../../theme/palette.dart';
import '../../../widgets/deadline_urgency_icon.dart';
import '../../../widgets/task_progress_indicator.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onStatusToggle,
    this.onDelete,
  });

  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onStatusToggle;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final statusBadge = _statusBadge();
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: [
              _statusColor().withOpacity(0.15),
              Theme.of(context).colorScheme.surface,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: _statusColor().withOpacity(0.25),
              blurRadius: 18,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                statusBadge,
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz_rounded),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onSelected: (value) {
                    if (value == 'toggle' && onStatusToggle != null) {
                      onStatusToggle!();
                    } else if (value == 'delete' && onDelete != null) {
                      onDelete!();
                    }
                  },
                  itemBuilder: (context) => [
                    if (onStatusToggle != null)
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              task.status == 'done'
                                  ? Icons.restart_alt
                                  : Icons.check_circle,
                              size: 20,
                              color: TaskyPalette.mint,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              task.status == 'done'
                                  ? 'Đánh dấu chưa xong'
                                  : 'Đánh dấu hoàn thành',
                            ),
                          ],
                        ),
                      ),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: TaskyPalette.coral,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Xóa task',
                              style: TextStyle(color: TaskyPalette.coral),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              task.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
            ),
            if (task.description?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text(
                task.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.7),
                    ),
              ),
            ],
            const SizedBox(height: 16),
            TaskProgressIndicator(status: task.status, showLabel: false),
            const SizedBox(height: 12),
            Row(
              children: [
                DeadlineUrgencyIcon(deadline: task.deadline, size: 24),
                const SizedBox(width: 8),
                _deadlineChip(),
                const SizedBox(width: 12),
                _assigneeChip(context),
                const Spacer(),
                if (task.teamName != null)
                  Chip(
                    label: Text(
                      task.teamName!,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    avatar: const Text('🧑‍🤝‍🧑'),
                    backgroundColor: TaskyPalette.lavender.withOpacity(0.3),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor() {
    switch (task.status) {
      case 'done':
        return TaskyPalette.mint;
      case 'doing':
        return TaskyPalette.lavender;
      default:
        return TaskyPalette.coral;
    }
  }

  Widget _statusBadge() {
    final emoji = task.status == 'done'
        ? '🌸'
        : task.status == 'doing'
            ? '🌱'
            : '🌤️';
    final label = task.status == 'done'
        ? 'Đã xong'
        : task.status == 'doing'
            ? 'Đang làm'
            : 'Chuẩn bị';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _statusColor().withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }

  Widget _deadlineChip() {
    if (task.deadline == null) {
      return const Chip(label: Text('Không deadline'), avatar: Text('🧘'));
    }
    final isOverdue = task.deadline!.isBefore(DateTime.now());
    final text = isOverdue
        ? 'Quá hạn'
        : DateFormat('dd MMM, HH:mm', 'vi').format(task.deadline!.toLocal());
    return Chip(
      label: Text(
        text,
        style: TextStyle(
          color: isOverdue ? Colors.redAccent : TaskyPalette.midnight,
        ),
      ),
      avatar: Text(isOverdue ? '⏰' : '🗓️'),
      backgroundColor: isOverdue
          ? TaskyPalette.coral.withOpacity(0.3)
          : TaskyPalette.aqua.withOpacity(0.4),
    );
  }

  Widget _assigneeChip(BuildContext context) {
    final name = task.assigneeName ?? 'Chưa giao';
    final short = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Chip(
      label: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      avatar: CircleAvatar(
        backgroundColor: isDark
            ? Theme.of(context).colorScheme.primary
            : TaskyPalette.midnight,
        foregroundColor: Colors.white,
        child: Text(short),
      ),
      backgroundColor: TaskyPalette.blush.withOpacity(0.3),
    );
  }
}
