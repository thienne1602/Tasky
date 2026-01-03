import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/task.dart';
import '../../../theme/palette.dart';
import '../../../widgets/deadline_urgency_icon.dart';
import '../../../widgets/task_progress_indicator.dart';
import '../../../widgets/pastel_button.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onStatusToggle,
    this.onDelete,
    this.showQuickPreview = true,
    this.isSelected = false,
    this.showSelectionIndicator = false,
  });

  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onStatusToggle;
  final VoidCallback? onDelete;
  final bool showQuickPreview;
  final bool isSelected;
  final bool showSelectionIndicator;

  @override
  Widget build(BuildContext context) {
    final statusBadge = _statusBadge();

    // Build children list conditionally
    final List<Widget> children = [
      Row(
        children: [
          if (showSelectionIndicator) ...[
            Checkbox(
              value: isSelected,
              onChanged: (value) => onTap?.call(),
              activeColor: TaskyPalette.mint,
            ),
            const SizedBox(width: 12),
          ],
          statusBadge,
          const Spacer(),
          if (!showSelectionIndicator)
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
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: TaskyPalette.coral,
                        ),
                        const SizedBox(width: 12),
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
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    ];

    // Add description conditionally
    if (task.description?.isNotEmpty ?? false) {
      children.addAll([
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
                    ?.withOpacity(0.85),
                fontWeight: FontWeight.w500,
              ),
        ),
      ]);
    }

    // Add remaining widgets
    children.addAll([
      const SizedBox(height: 16),
      TaskProgressIndicator(status: task.status, showLabel: false),
      const SizedBox(height: 12),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DeadlineUrgencyIcon(deadline: task.deadline, size: 24),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _deadlineChip(),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _assigneeChip(context),
          ),
          if (task.teamName != null) ...[
            const SizedBox(width: 8),
            Container(
              constraints: const BoxConstraints(maxWidth: 80),
              child: Chip(
                label: Text(
                  task.teamName!,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                avatar: const Text('🧑‍🤝‍🧑', style: TextStyle(fontSize: 10)),
                backgroundColor: TaskyPalette.lavender.withOpacity(0.3),
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ],
      ),
    ]);

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      onLongPress: showQuickPreview ? () => _showQuickPreview(context) : null,
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
          children: children,
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
        overflow: TextOverflow.ellipsis,
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
      label: Text(
        name,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
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

  void _showQuickPreview(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _statusColor().withOpacity(0.1),
                Theme.of(context).colorScheme.surface,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and close button
              Row(
                children: [
                  _statusBadge(),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: TaskyPalette.lavender.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                task.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: TaskyPalette.midnight,
                    ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Description
              if (task.description?.isNotEmpty ?? false) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: TaskyPalette.lavender.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    task.description!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: TaskyPalette.midnight.withOpacity(0.8),
                          height: 1.4,
                        ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Progress indicator
              TaskProgressIndicator(status: task.status),
              const SizedBox(height: 16),

              // Task info row
              Row(
                children: [
                  Expanded(
                    child: _InfoChip(
                      icon: Icons.person_outline,
                      label: 'Người làm',
                      value: task.assigneeName ?? 'Chưa giao',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _InfoChip(
                      icon: Icons.calendar_today,
                      label: 'Deadline',
                      value: task.deadline != null
                          ? DateFormat('dd/MM/yyyy HH:mm', 'vi').format(task.deadline!)
                          : 'Không có',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (task.teamName != null) ...[
                _InfoChip(
                  icon: Icons.group,
                  label: 'Team',
                  value: task.teamName!,
                ),
                const SizedBox(height: 12),
              ],

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: PastelButton(
                      text: 'Xem chi tiết',
                      onPressed: () {
                        Navigator.pop(context);
                        onTap?.call();
                      },
                      icon: '👀',
                    ),
                  ),
                  if (onStatusToggle != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: PastelButton(
                        text: task.status == 'done' ? 'Đánh dấu chưa xong' : 'Đánh dấu hoàn thành',
                        onPressed: () {
                          Navigator.pop(context);
                          onStatusToggle?.call();
                        },
                        icon: task.status == 'done' ? '↶' : '✅',
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: TaskyPalette.lavender.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: TaskyPalette.lavender.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: TaskyPalette.lavender),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: TaskyPalette.midnight.withOpacity(0.6),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: TaskyPalette.midnight,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}