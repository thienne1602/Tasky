import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../theme/palette.dart';
import '../widgets/active_tasks_banner.dart';
import 'widgets/task_card.dart';

class TaskTimelineView extends StatelessWidget {
  const TaskTimelineView({
    super.key,
    required this.onOpenTask,
    required this.onCreateTask,
  });

  final void Function(Task task) onOpenTask;
  final VoidCallback onCreateTask;

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        return RefreshIndicator(
          onRefresh: taskProvider.fetchTasks,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: TaskyPalette.lavender.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: TableCalendar(
                  locale: 'vi_VN',
                  firstDay: DateTime.utc(2020),
                  lastDay: DateTime.utc(2035),
                  focusedDay: taskProvider.selectedDay,
                  selectedDayPredicate: (day) =>
                      _sameDay(taskProvider.selectedDay, day),
                  onDaySelected: (selected, focused) =>
                      taskProvider.selectDay(selected),
                  calendarStyle: CalendarStyle(
                    todayDecoration: const BoxDecoration(
                      color: TaskyPalette.aqua,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: TaskyPalette.mint,
                      shape: BoxShape.circle,
                    ),
                    weekendTextStyle: const TextStyle(color: Colors.purple),
                    defaultTextStyle: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                    leftChevronIcon: const Icon(Icons.chevron_left_rounded),
                    rightChevronIcon: const Icon(Icons.chevron_right_rounded),
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                      final count = taskProvider.tasks
                          .where(
                            (task) =>
                                task.deadline != null &&
                                _sameDay(task.deadline!, day),
                          )
                          .length;
                      if (count == 0) return null;
                      return Positioned(
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: TaskyPalette.coral,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ActiveTasksBanner(onOpenTask: onOpenTask),
              const SizedBox(height: 24),
              Text(
                'Timeline hôm nay',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              if (taskProvider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (taskProvider.tasksForSelectedDay.isEmpty)
                _EmptyState(onAction: onCreateTask)
              else
                ...taskProvider.tasksForSelectedDay.map(
                  (task) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TaskCard(task: task, onTap: () => onOpenTask(task)),
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                'Deadline sắp đến',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: taskProvider.upcomingDeadlines.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final task = taskProvider.upcomingDeadlines[index];
                    return _DeadlineCard(
                      task: task,
                      onTap: () => onOpenTask(task),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAction});

  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: TaskyPalette.lavender.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          const Text('✨'),
          const SizedBox(height: 12),
          Text(
            'Không nhiệm vụ nào hôm nay',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy tới tab Team để tạo task mới nha! 💫',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.6),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DeadlineCard extends StatelessWidget {
  const _DeadlineCard({required this.task, required this.onTap});

  final Task task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        height: 140,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: TaskyPalette.lavender.withOpacity(0.3),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: TaskyPalette.coral.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Sắp deadline',
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('⏰'),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Text(
                task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Spacer(),
            Text(
              task.deadline != null
                  ? DateFormat(
                      'dd MMM HH:mm',
                      'vi',
                    ).format(task.deadline!.toLocal())
                  : 'Không deadline',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withOpacity(0.6),
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
