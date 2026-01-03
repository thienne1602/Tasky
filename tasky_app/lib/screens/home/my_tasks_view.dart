import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/task.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../theme/palette.dart';
import '../../widgets/fun_notification.dart';
import 'widgets/task_card.dart';

enum TaskSortOption {
  deadlineAsc('📅 Deadline gần nhất'),
  deadlineDesc('📅 Deadline xa nhất'),
  createdAsc('📝 Tạo gần nhất'),
  createdDesc('📝 Tạo xa nhất'),
  priorityHigh('⭐ Ưu tiên cao'),
  priorityLow('⭐ Ưu tiên thấp'),
  alphabetical('🔤 A-Z');

  const TaskSortOption(this.label);
  final String label;
}

class MyTasksView extends StatefulWidget {
  const MyTasksView({super.key, required this.onOpenTask});

  final void Function(Task task) onOpenTask;

  @override
  State<MyTasksView> createState() => _MyTasksViewState();
}

class _MyTasksViewState extends State<MyTasksView> {
  final TextEditingController _searchController = TextEditingController();
  TaskSortOption _sortOption = TaskSortOption.deadlineAsc;
  String _searchQuery = '';
  bool _showCompletedTasks = true;
  bool _isSelectionMode = false;
  final Set<int> _selectedTaskIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Task> _filterTasks(List<Task> tasks) {
    if (_searchQuery.isEmpty) return tasks;

    return tasks.where((task) {
      final title = task.title.toLowerCase();
      final description = task.description?.toLowerCase() ?? '';
      final assigneeName = task.assigneeName?.toLowerCase() ?? '';
      final creatorName = task.creatorName?.toLowerCase() ?? '';
      final teamName = task.teamName?.toLowerCase() ?? '';

      return title.contains(_searchQuery) ||
             description.contains(_searchQuery) ||
             assigneeName.contains(_searchQuery) ||
             creatorName.contains(_searchQuery) ||
             teamName.contains(_searchQuery);
    }).toList();
  }

  void _sortTasks(List<Task> tasks) {
    tasks.sort((a, b) {
      switch (_sortOption) {
        case TaskSortOption.deadlineAsc:
          if (a.deadline == null && b.deadline == null) return 0;
          if (a.deadline == null) return 1;
          if (b.deadline == null) return -1;
          return a.deadline!.compareTo(b.deadline!);

        case TaskSortOption.deadlineDesc:
          if (a.deadline == null && b.deadline == null) return 0;
          if (a.deadline == null) return 1;
          if (b.deadline == null) return -1;
          return b.deadline!.compareTo(a.deadline!);

        case TaskSortOption.createdAsc:
          return a.id.compareTo(b.id); // Using ID as proxy for creation time

        case TaskSortOption.createdDesc:
          return b.id.compareTo(a.id); // Using ID as proxy for creation time

        case TaskSortOption.priorityHigh:
          // Priority based on deadline urgency and status
          final aScore = _calculatePriorityScore(a);
          final bScore = _calculatePriorityScore(b);
          return bScore.compareTo(aScore); // Higher score first

        case TaskSortOption.priorityLow:
          final aScore = _calculatePriorityScore(a);
          final bScore = _calculatePriorityScore(b);
          return aScore.compareTo(bScore); // Lower score first

        case TaskSortOption.alphabetical:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
    });
  }

  int _calculatePriorityScore(Task task) {
    int score = 0;

    // Status priority: todo > doing > done
    switch (task.status) {
      case 'todo': score += 100; break;
      case 'doing': score += 50; break;
      case 'done': score += 0; break;
    }

    // Deadline urgency
    if (task.deadline != null) {
      final hoursLeft = task.deadline!.difference(DateTime.now()).inHours;
      if (hoursLeft < 0) score += 1000; // Overdue
      else if (hoursLeft < 24) score += 500; // Due today
      else if (hoursLeft < 72) score += 200; // Due in 3 days
      else if (hoursLeft < 168) score += 100; // Due this week
    } else {
      score += 10; // No deadline
    }

    return score;
  }

  void _toggleTaskSelection(int taskId) {
    setState(() {
      if (_selectedTaskIds.contains(taskId)) {
        _selectedTaskIds.remove(taskId);
      } else {
        _selectedTaskIds.add(taskId);
      }
    });
  }

  Future<void> _bulkMarkComplete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('✅'),
            SizedBox(width: 8),
            Text('Đánh dấu hoàn thành'),
          ],
        ),
        content: Text(
          'Đánh dấu ${_selectedTaskIds.length} task đã chọn là hoàn thành?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: TaskyPalette.mint,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final taskProvider = context.read<TaskProvider>();
        for (final taskId in _selectedTaskIds) {
          await taskProvider.updateTaskStatus(taskId, 'done');
        }

        setState(() {
          _isSelectionMode = false;
          _selectedTaskIds.clear();
        });

        if (mounted) {
          FunNotification.show(
            context,
            emoji: '🎉',
            title: 'Hoàn thành!',
            message: 'Đã cập nhật ${_selectedTaskIds.length} task thành công!',
            color: TaskyPalette.mint,
          );
        }
      } catch (e) {
        if (mounted) {
          FunNotification.error(
            context,
            title: 'Lỗi cập nhật',
            message: 'Có lỗi xảy ra khi cập nhật task: $e',
          );
        }
      }
    }
  }

  Future<void> _bulkDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('🗑️'),
            SizedBox(width: 8),
            Text('Xóa task'),
          ],
        ),
        content: Text(
          'Bạn có chắc muốn xóa ${_selectedTaskIds.length} task đã chọn? Hành động này không thể hoàn tác!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: TaskyPalette.coral,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final taskProvider = context.read<TaskProvider>();
        for (final taskId in _selectedTaskIds) {
          await taskProvider.deleteTask(taskId);
        }

        setState(() {
          _isSelectionMode = false;
          _selectedTaskIds.clear();
        });

        if (mounted) {
          FunNotification.show(
            context,
            emoji: '🗑️',
            title: 'Đã xóa',
            message: 'Đã xóa ${_selectedTaskIds.length} task thành công!',
            color: TaskyPalette.coral,
          );
        }
      } catch (e) {
        if (mounted) {
          FunNotification.error(
            context,
            title: 'Lỗi xóa',
            message: 'Có lỗi xảy ra khi xóa task: $e',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final taskProvider = context.watch<TaskProvider>();

    if (user == null) {
      return const Center(child: Text('Vui lòng đăng nhập'));
    }

    final myTasks = taskProvider.myTasks(user.id);
    final createdTasks = taskProvider.createdByMe(user.id);

    // Filter tasks based on search query
    final filteredTasks = _filterTasks(myTasks);
    final filteredCreatedTasks = _filterTasks(createdTasks);

    final todoTasks = filteredTasks.where((t) => t.status == 'todo').toList();
    final doingTasks = filteredTasks.where((t) => t.status == 'doing').toList();
    final doneTasks = filteredTasks.where((t) => t.status == 'done').toList();

    // Sort tasks
    _sortTasks(todoTasks);
    _sortTasks(doingTasks);
    _sortTasks(doneTasks);
    _sortTasks(filteredCreatedTasks);

    return RefreshIndicator(
      onRefresh: () => taskProvider.fetchTasks(),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: TaskyPalette.lavender.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // Selection Mode Header
                if (_isSelectionMode) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Đã chọn ${_selectedTaskIds.length} task',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: TaskyPalette.midnight,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Hủy', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: const Size(0, 32),
                        ),
                        onPressed: () {
                          setState(() {
                            _isSelectionMode = false;
                            _selectedTaskIds.clear();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Bulk Actions
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('Hoàn thành'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TaskyPalette.mint,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: const Size(0, 36),
                        ),
                        onPressed: _selectedTaskIds.isEmpty ? null : () => _bulkMarkComplete(),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Xóa'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TaskyPalette.coral,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: const Size(0, 36),
                        ),
                        onPressed: _selectedTaskIds.isEmpty ? null : () => _bulkDelete(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '🔍 Tìm kiếm task...',
                    hintStyle: TextStyle(
                      color: TaskyPalette.midnight.withOpacity(0.4),
                    ),
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                        if (!_isSelectionMode)
                          IconButton(
                            icon: const Icon(Icons.checklist_rounded, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Chọn nhiều',
                            onPressed: () {
                              setState(() => _isSelectionMode = true);
                            },
                          ),
                      ],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: TaskyPalette.lavender.withOpacity(0.1),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value.toLowerCase());
                  },
                ),
                const SizedBox(height: 12),
                // Sort and Filter Row
                Row(
                  children: [
                    // Sort Dropdown
                    Expanded(
                      child: DropdownButtonFormField<TaskSortOption>(
                        value: _sortOption,
                        decoration: InputDecoration(
                          labelText: 'Sắp xếp',
                          labelStyle: const TextStyle(fontSize: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: TaskyPalette.aqua.withOpacity(0.1),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: TaskSortOption.values.map((option) {
                          return DropdownMenuItem(
                            value: option,
                            child: Text(option.label, style: const TextStyle(fontSize: 12)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _sortOption = value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Show/Hide Completed Toggle
                    SizedBox(
                      width: 100,
                      child: FilterChip(
                        label: Text(
                          _showCompletedTasks ? 'Ẩn xong' : 'Hiện xong',
                          style: const TextStyle(fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                        selected: !_showCompletedTasks,
                        onSelected: (selected) {
                          setState(() => _showCompletedTasks = !selected);
                        },
                        avatar: Icon(
                          _showCompletedTasks ? Icons.visibility_off : Icons.visibility,
                          size: 14,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Được giao',
                  count: filteredTasks.length,
                  icon: '📋',
                  color: TaskyPalette.mint,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  title: 'Tôi tạo',
                  count: filteredCreatedTasks.length,
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
                  child: TaskCard(
                    task: task,
                    onTap: _isSelectionMode ? () => _toggleTaskSelection(task.id) : () => widget.onOpenTask(task),
                    showQuickPreview: !_isSelectionMode,
                    showSelectionIndicator: _isSelectionMode,
                    isSelected: _selectedTaskIds.contains(task.id),
                  ),
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
                  child: TaskCard(
                    task: task,
                    onTap: _isSelectionMode ? () => _toggleTaskSelection(task.id) : () => widget.onOpenTask(task),
                    showQuickPreview: !_isSelectionMode,
                    showSelectionIndicator: _isSelectionMode,
                    isSelected: _selectedTaskIds.contains(task.id),
                  ),
                )),
            const SizedBox(height: 20),
          ],

          // Done Tasks
          if (_showCompletedTasks && doneTasks.isNotEmpty) ...[
            _SectionHeader(
              title: '🌸 Hoàn thành',
              count: doneTasks.length,
            ),
            const SizedBox(height: 12),
            ...doneTasks.map((task) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TaskCard(
                    task: task,
                    onTap: _isSelectionMode ? () => _toggleTaskSelection(task.id) : () => widget.onOpenTask(task),
                    showQuickPreview: !_isSelectionMode,
                    showSelectionIndicator: _isSelectionMode,
                    isSelected: _selectedTaskIds.contains(task.id),
                  ),
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
            ...filteredCreatedTasks.map((task) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _LeaderTaskCard(
                    task: task,
                    onTap: () => widget.onOpenTask(task),
                    onRemind: () => _sendReminder(context, task),
                  ),
                )),
          ],

          // Empty State
          if (filteredTasks.isEmpty && (_searchQuery.isEmpty || myTasks.isEmpty))
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Text(
                      _searchQuery.isNotEmpty ? '🔍' : '🎉',
                      style: const TextStyle(fontSize: 64)
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isNotEmpty
                        ? 'Không tìm thấy task nào phù hợp với "$_searchQuery"'
                        : 'Chưa có task nào được giao cho bạn',
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
