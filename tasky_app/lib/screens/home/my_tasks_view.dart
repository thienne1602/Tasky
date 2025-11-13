import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/task.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../theme/palette.dart';
import '../../widgets/fun_notification.dart';
import 'widgets/task_card.dart';

class MyTasksView extends StatelessWidget {
  const MyTasksView({super.key, required this.onOpenTask});

  final void Function(Task task) onOpenTask;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final taskProvider = context.watch<TaskProvider>();

    if (user == null) {
      return const Center(child: Text('Vui lòng đăng nhập'));
    }

    final myTasks = taskProvider.myTasks(user.id);
    final createdTasks = taskProvider.createdByMe(user.id);

    final todoTasks = myTasks.where((t) => t.status == 'todo').toList();
    final doingTasks = myTasks.where((t) => t.status == 'doing').toList();
    final doneTasks = myTasks.where((t) => t.status == 'done').toList();

    return RefreshIndicator(
      onRefresh: () => taskProvider.fetchTasks(),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Được giao',
                  count: myTasks.length,
                  icon: '📋',
                  color: TaskyPalette.mint,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  title: 'Tôi tạo',
                  count: createdTasks.length,
                  icon: '✨',
                  color: TaskyPalette.lavender,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Todo Tasks
          if (todoTasks.isNotEmpty) ...[
            _SectionHeader(
              title: '🌤️ Cần làm',
              count: todoTasks.length,
            ),
            const SizedBox(height: 12),
            ...todoTasks.map((task) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TaskCard(task: task, onTap: () => onOpenTask(task)),
                )),
            const SizedBox(height: 20),
          ],

          // Doing Tasks
          if (doingTasks.isNotEmpty) ...[
            _SectionHeader(
              title: '🌱 Đang làm',
              count: doingTasks.length,
            ),
            const SizedBox(height: 12),
            ...doingTasks.map((task) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TaskCard(task: task, onTap: () => onOpenTask(task)),
                )),
            const SizedBox(height: 20),
          ],

          // Done Tasks
          if (doneTasks.isNotEmpty) ...[
            _SectionHeader(
              title: '🌸 Hoàn thành',
              count: doneTasks.length,
            ),
            const SizedBox(height: 12),
            ...doneTasks.map((task) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TaskCard(task: task, onTap: () => onOpenTask(task)),
                )),
            const SizedBox(height: 20),
          ],

          // Created Tasks (for leaders to remind assignees)
          if (createdTasks.isNotEmpty) ...[
            _SectionHeader(
              title: '✨ Tôi tạo (Leader)',
              count: createdTasks.length,
            ),
            const SizedBox(height: 12),
            ...createdTasks.map((task) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _LeaderTaskCard(
                    task: task,
                    onTap: () => onOpenTask(task),
                    onRemind: () => _sendReminder(context, task),
                  ),
                )),
          ],

          // Empty State
          if (myTasks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 16),
                    Text(
                      'Chưa có task nào được giao cho bạn',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: TaskyPalette.midnight.withOpacity(0.6),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  final String title;
  final int count;
  final String icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: TaskyPalette.midnight,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: TaskyPalette.midnight.withOpacity(0.7),
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: TaskyPalette.lavender.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

void _sendReminder(BuildContext context, Task task) {
  // Show confirmation dialog first
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Nhắc nhở thành viên'),
      content: Text(
        'Gửi thông báo nhắc nhở cập nhật tiến độ task "${task.title}" đến ${task.assigneeName ?? "thành viên"}?',
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            // Send reminder via API
            try {
              await context.read<TaskProvider>().sendTaskReminder(task.id);
              if (context.mounted) {
                FunNotification.show(
                  context,
                  emoji: '⏰',
                  title: 'Đã gửi nhắc nhở',
                  message:
                      '${task.assigneeName ?? "Thành viên"} sẽ nhận được thông báo nhắc nhở!',
                  color: TaskyPalette.coral,
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi: ${e.toString()}'),
                    backgroundColor: TaskyPalette.coral,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: TaskyPalette.coral,
          ),
          child: const Text('Gửi nhắc nhở'),
        ),
      ],
    ),
  );
}

class _LeaderTaskCard extends StatelessWidget {
  const _LeaderTaskCard({
    required this.task,
    required this.onTap,
    required this.onRemind,
  });

  final Task task;
  final VoidCallback onTap;
  final VoidCallback onRemind;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: TaskyPalette.lavender.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: TaskyPalette.lavender.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getStatusBadge(),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.notifications_active_rounded),
                  color: TaskyPalette.coral,
                  iconSize: 24,
                  onPressed: onRemind,
                  tooltip: 'Nhắc nhở cập nhật',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 16, color: TaskyPalette.lavender),
                const SizedBox(width: 4),
                Text(
                  task.assigneeName ?? 'Chưa giao',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: TaskyPalette.midnight.withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getStatusBadge() {
    Color color;
    String label;
    switch (task.status) {
      case 'done':
        color = TaskyPalette.mint;
        label = '✓ Xong';
        break;
      case 'doing':
        color = TaskyPalette.lavender;
        label = '⚡ Đang làm';
        break;
      default:
        color = TaskyPalette.coral;
        label = '○ Chưa làm';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
