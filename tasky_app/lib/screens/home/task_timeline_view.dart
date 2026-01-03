import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../theme/palette.dart';
import '../widgets/active_tasks_banner.dart';
import 'widgets/task_card.dart';

class ProgressDashboard extends StatelessWidget {
  const ProgressDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        final totalTasks = taskProvider.totalTasks;
        final completedTasks = taskProvider.completedTasks;
        final completionRate = totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0.0;

        final todayTasks = taskProvider.tasksForSelectedDay.length;
        final todayCompleted = taskProvider.tasksForSelectedDay
            .where((task) => task.status == 'done')
            .length;

        final motivationalMessage = _getMotivationalMessage(completionRate);
        final weatherIndicator = _getWeatherIndicator(completionRate, todayTasks, todayCompleted);
        final dailyTip = _getDailyTip();

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                weatherIndicator.primaryColor.withOpacity(0.1),
                weatherIndicator.secondaryColor.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: weatherIndicator.primaryColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(weatherIndicator.weatherIcon, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          weatherIndicator.weatherName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: TaskyPalette.midnight,
                              ),
                        ),
                        Text(
                          weatherIndicator.description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: TaskyPalette.midnight.withOpacity(0.85),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _ProgressMetric(
                      label: 'Hoàn thành',
                      value: '${completionRate.round()}%',
                      color: TaskyPalette.mint,
                      progress: completionRate / 100,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ProgressMetric(
                      label: 'Hôm nay',
                      value: '$todayCompleted/$todayTasks',
                      color: TaskyPalette.aqua,
                      progress: todayTasks > 0 ? todayCompleted / todayTasks : 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Text(
                          motivationalMessage.emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            motivationalMessage.message,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: motivationalMessage.color,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: TaskyPalette.lavender.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: TaskyPalette.lavender.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            dailyTip,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: TaskyPalette.midnight.withOpacity(0.8),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  _WeatherIndicator _getWeatherIndicator(double completionRate, int todayTasks, int todayCompleted) {
    // Determine productivity level based on completion rate and activity
    final productivityScore = (completionRate * 0.7) + (todayTasks > 0 ? (todayCompleted / todayTasks) * 30 : 0);

    if (productivityScore >= 80) {
      return _WeatherIndicator(
        '☀️',
        'Trời nắng',
        'Sản xuất cực cao! Bạn đang ở đỉnh điểm năng suất!',
        TaskyPalette.mint,
        TaskyPalette.aqua,
      );
    } else if (productivityScore >= 60) {
      return _WeatherIndicator(
        '⛅',
        'Ít mây',
        'Thời tiết tốt! Tiếp tục giữ nhịp độ này nhé!',
        TaskyPalette.aqua,
        TaskyPalette.lavender,
      );
    } else if (productivityScore >= 40) {
      return _WeatherIndicator(
        '🌤️',
        'Nhiều mây',
        'Thời tiết ổn định. Hãy tập trung vào những gì quan trọng!',
        TaskyPalette.lavender,
        TaskyPalette.coral,
      );
    } else if (productivityScore >= 20) {
      return _WeatherIndicator(
        '🌥️',
        'U ám',
        'Cần chút động lực? Hãy bắt đầu với task nhỏ nhất!',
        TaskyPalette.coral,
        TaskyPalette.blush,
      );
    } else {
      return _WeatherIndicator(
        '🌧️',
        'Mưa',
        'Hôm nay cần nghỉ ngơi. Ngày mai sẽ tốt hơn!',
        TaskyPalette.blush,
        TaskyPalette.lavender,
      );
    }
  }

  String _getDailyTip() {
    final tips = [
      '🍅 Kỹ thuật Pomodoro: 25 phút tập trung, 5 phút nghỉ ngơi!',
      '🎯 Nguyên tắc 2 phút: Nếu task dưới 2 phút, làm ngay!',
      '📝 Viết ra mục tiêu hàng ngày giúp tăng 20% khả năng hoàn thành.',
      '🚫 Tránh đa nhiệm. Tập trung vào một task tại một thời điểm.',
      '🌅 Bắt đầu ngày với 3 task quan trọng nhất của bạn.',
      '✅ Đánh dấu hoàn thành ngay khi xong task để có động lực.',
      '⏰ Sử dụng deadline thông minh để tăng tốc độ làm việc.',
      '🎉 Tự thưởng cho bản thân khi hoàn thành mục tiêu.',
    ];

    // Use day of year as seed for consistent daily tip
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return tips[dayOfYear % tips.length];
  }

  _MotivationalMessage _getMotivationalMessage(double completionRate) {
    if (completionRate >= 80) {
      return _MotivationalMessage(
        '🎉 Xuất sắc! Bạn đã hoàn thành hầu hết các task!',
        '🌟',
        TaskyPalette.mint,
      );
    } else if (completionRate >= 60) {
      return _MotivationalMessage(
        '💪 Giữ đà này lên! Bạn đang làm rất tốt!',
        '🔥',
        TaskyPalette.coral,
      );
    } else if (completionRate >= 40) {
      return _MotivationalMessage(
        '🚀 Tiếp tục cố gắng! Mỗi bước nhỏ đều quan trọng!',
        '💡',
        TaskyPalette.lavender,
      );
    } else if (completionRate >= 20) {
      return _MotivationalMessage(
        '🌱 Bắt đầu thôi! Mỗi ngày là một cơ hội mới!',
        '🌱',
        TaskyPalette.aqua,
      );
    } else {
      return _MotivationalMessage(
        '✨ Hôm nay sẽ là ngày tuyệt vời! Bắt đầu với task đầu tiên nhé!',
        '⭐',
        TaskyPalette.blush,
      );
    }
  }
}

class _ProgressMetric extends StatelessWidget {
  const _ProgressMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.progress,
  });

  final String label;
  final String value;
  final Color color;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: TaskyPalette.midnight.withOpacity(0.85),
                      fontWeight: FontWeight.w700,
                    ),
              ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WeatherIndicator {
  const _WeatherIndicator(
    this.weatherIcon,
    this.weatherName,
    this.description,
    this.primaryColor,
    this.secondaryColor,
  );

  final String weatherIcon;
  final String weatherName;
  final String description;
  final Color primaryColor;
  final Color secondaryColor;
}

class _MotivationalMessage {
  const _MotivationalMessage(this.message, this.emoji, this.color);

  final String message;
  final String emoji;
  final Color color;
}

class TaskTimelineView extends StatefulWidget {
  const TaskTimelineView({
    super.key,
    required this.onOpenTask,
    required this.onCreateTask,
  });

  final void Function(Task task) onOpenTask;
  final VoidCallback onCreateTask;

  @override
  State<TaskTimelineView> createState() => _TaskTimelineViewState();
}

class _TaskTimelineViewState extends State<TaskTimelineView> {
  String _selectedFilter = 'all'; // 'all', 'todo', 'doing', 'done'

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
              const ProgressDashboard(),
              const SizedBox(height: 16),
              ActiveTasksBanner(onOpenTask: widget.onOpenTask),
              const SizedBox(height: 24),
              Text(
                'Timeline hôm nay',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              _TaskFilterBar(
                selectedFilter: _selectedFilter,
                onFilterChanged: (filter) => setState(() => _selectedFilter = filter),
              ),
              const SizedBox(height: 12),
              if (taskProvider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                Builder(
                  builder: (context) {
                    final filteredTasks = _getFilteredTasks(taskProvider.tasksForSelectedDay);
                    if (filteredTasks.isEmpty) {
                      return _EmptyState(onAction: widget.onCreateTask);
                    }
                    return Column(
                      children: filteredTasks.map(
                        (task) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: TaskCard(task: task, onTap: () => widget.onOpenTask(task)),
                        ),
                      ).toList(),
                    );
                  },
                ),
              if (taskProvider.upcomingDeadlines.isNotEmpty) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      'Deadline sắp đến',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '⏰',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
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
                        onTap: () => widget.onOpenTask(task),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  List<Task> _getFilteredTasks(List<Task> tasks) {
    switch (_selectedFilter) {
      case 'todo':
        return tasks.where((task) => task.status == 'todo').toList();
      case 'doing':
        return tasks.where((task) => task.status == 'doing').toList();
      case 'done':
        return tasks.where((task) => task.status == 'done').toList();
      default:
        return tasks;
    }
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class _EmptyState extends StatefulWidget {
  const _EmptyState({required this.onAction});

  final VoidCallback onAction;

  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState> with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _fadeController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: TaskyPalette.lavender.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: TaskyPalette.lavender.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_bounceController, _fadeController]),
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -_bounceAnimation.value),
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: const Text(
                      '🌸',
                      style: TextStyle(fontSize: 48),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Hôm nay thật chill!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: TaskyPalette.midnight,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Không có task nào cho ngày hôm nay.\nHãy nghỉ ngơi và tận hưởng cuộc sống nhé! ✨',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.85),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _QuickActionButton(
                icon: '🎯',
                label: 'Tạo task',
                color: TaskyPalette.mint,
                onTap: widget.onAction,
              ),
              const SizedBox(width: 16),
              _QuickActionButton(
                icon: '📊',
                label: 'Xem thống kê',
                color: TaskyPalette.aqua,
                onTap: () {
                  // Navigate to statistics or show a snackbar for now
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tính năng thống kê đang được phát triển! 🚀'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: TaskyPalette.blush.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '💡 Mẹo: Tạo task sớm giúp bạn có kế hoạch tốt hơn!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: TaskyPalette.coral,
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskFilterBar extends StatelessWidget {
  const _TaskFilterBar({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: TaskyPalette.lavender.withOpacity(0.1),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: _FilterChip(
              label: 'Tất cả',
              emoji: '📋',
              isSelected: selectedFilter == 'all',
              onTap: () => onFilterChanged('all'),
            ),
          ),
          Expanded(
            child: _FilterChip(
              label: 'Chưa',
              emoji: '🌤️',
              isSelected: selectedFilter == 'todo',
              onTap: () => onFilterChanged('todo'),
            ),
          ),
          Expanded(
            child: _FilterChip(
              label: 'Đang',
              emoji: '🌱',
              isSelected: selectedFilter == 'doing',
              onTap: () => onFilterChanged('doing'),
            ),
          ),
          Expanded(
            child: _FilterChip(
              label: 'Xong',
              emoji: '🌸',
              isSelected: selectedFilter == 'done',
              onTap: () => onFilterChanged('done'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? TaskyPalette.lavender : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : TaskyPalette.midnight.withOpacity(0.85),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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
        width: 200, // Giảm width để tránh overflow
        constraints: const BoxConstraints(minHeight: 140, maxHeight: 140),
        padding: const EdgeInsets.all(16), // Giảm padding
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20), // Giảm border radius
          boxShadow: [
            BoxShadow(
              color: TaskyPalette.lavender.withOpacity(0.3),
              blurRadius: 15, // Giảm blur
              offset: const Offset(0, 8), // Giảm offset
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min, // Thêm để tránh overflow
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: TaskyPalette.coral.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Sắp deadline',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 6),
                const Text('⏰', style: TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Text(
                task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: TaskyPalette.midnight.withOpacity(0.8),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    task.deadline != null
                        ? DateFormat(
                            'dd MMM HH:mm',
                            'vi',
                          ).format(task.deadline!.toLocal())
                        : 'Không deadline',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: TaskyPalette.midnight.withOpacity(0.8),
                          fontWeight: FontWeight.w600,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
