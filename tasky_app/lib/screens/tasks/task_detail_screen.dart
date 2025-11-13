import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/comment.dart';
import '../../models/task.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/team_provider.dart';
import '../../theme/palette.dart';
import '../../widgets/cute_widgets.dart';
import '../../widgets/deadline_urgency_icon.dart';
import '../../widgets/fun_notification.dart';
import '../../widgets/task_progress_indicator.dart';
import '../../widgets/pastel_button.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final int taskId;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  Task? _task;
  List<User> _members = [];
  User? _currentUserRole;
  bool _loading = true;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTask());
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  bool get _isLeader =>
      _currentUserRole?.role == 'leader' || _currentUserRole?.role == 'owner';

  Future<void> _loadTask() async {
    final taskProvider = context.read<TaskProvider>();
    final teamProvider = context.read<TeamProvider>();
    final currentUser = context.read<AuthProvider>().currentUser;

    try {
      final task = await taskProvider.fetchTaskDetail(widget.taskId);
      setState(() {
        _task = task;
        _loading = false;
      });

      if (task.teamId != null) {
        try {
          final teamDetail = await teamProvider.fetchTeamDetail(task.teamId!);
          setState(() {
            _members = teamDetail.members;
            _currentUserRole = teamDetail.members.firstWhere(
              (m) => m.id == currentUser?.id,
              orElse: () => User(
                id: currentUser?.id ?? 0,
                userId: '',
                name: '',
                email: '',
                role: 'member',
              ),
            );
          });
        } catch (e) {
          setState(() => _members = []);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được task: $e')),
      );
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;
    final currentUser = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết nhiệm vụ'),
        actions: [
          if (task != null && _isLeader)
            IconButton(
              icon: const Icon(Icons.delete_forever_rounded),
              onPressed: () => _confirmDelete(task.id),
            ),
        ],
      ),
      body: _loading
          ? const CuteLoadingIndicator(message: 'Đang tải task...')
          : task == null
              ? EmptyStateWidget(
                  emoji: '😢',
                  title: 'Task không tồn tại',
                  message:
                      'Task này có thể đã bị xóa hoặc bạn không có quyền xem',
                  actionLabel: 'Quay lại',
                  onAction: () => Navigator.pop(context),
                )
              : RefreshIndicator(
                  onRefresh: _loadTask,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TaskHeader(task: task),
                        const SizedBox(height: 20),
                        _TaskInfoCard(task: task),
                        const SizedBox(height: 20),
                        if (_isLeader) ...[
                          _LeaderControls(
                            task: _task ?? task,
                            members: _members,
                            onTaskUpdated: (updatedTask) {
                              setState(() => _task = updatedTask);
                            },
                            onSave: () => _saveTask(_task!),
                          ),
                          const SizedBox(height: 20),
                        ],
                        if (!_isLeader &&
                            task.assignedTo == currentUser?.id) ...[
                          _MemberControls(
                            task: _task ?? task,
                            onTaskUpdated: (updatedTask) {
                              setState(() => _task = updatedTask);
                            },
                            onSave: () => _saveTask(_task!),
                          ),
                          const SizedBox(height: 20),
                        ],
                        _CommentsSection(
                          task: task,
                          commentController: _commentController,
                          onAddComment: _addComment,
                          onDeleteComment: _deleteComment,
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Future<void> _saveTask(Task task) async {
    try {
      await context.read<TaskProvider>().updateTask(task);
      if (!mounted) return;

      // Reload task detail để cập nhật UI
      final updatedTask =
          await context.read<TaskProvider>().fetchTaskDetail(widget.taskId);
      setState(() {
        _task = updatedTask;
      });

      // Nếu task được đánh dấu hoàn thành, hiển thị popup đặc biệt
      if (task.status == 'done') {
        FunNotification.taskComplete(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã lưu thay đổi'),
            backgroundColor: TaskyPalette.mint,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      FunNotification.error(
        context,
        title: 'Lưu thất bại',
        message: 'Có lỗi xảy ra, thử lại nhé! 😔',
      );
    }
  }

  Future<void> _confirmDelete(int taskId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('🗑️'),
            SizedBox(width: 8),
            Text('Xóa nhiệm vụ'),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn xóa nhiệm vụ này không? Hành động này không thể hoàn tác đâu nha! 😢',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy bỏ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa luôn'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await context.read<TaskProvider>().deleteTask(taskId);
      if (!mounted) return;
      FunNotification.taskDeleted(context);
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  Future<void> _addComment() async {
    if (_task == null || _commentController.text.trim().isEmpty) return;
    final taskProvider = context.read<TaskProvider>();
    final comment = await taskProvider.addComment(
      taskId: _task!.id,
      content: _commentController.text.trim(),
    );
    setState(() {
      _task = _task!.copyWith(comments: [..._task!.comments, comment]);
      _commentController.clear();
    });
    if (mounted) {
      FunNotification.commentAdded(context);
    }
  }

  Future<void> _deleteComment(int commentId) async {
    if (_task == null) return;
    await context.read<TaskProvider>().removeComment(
          taskId: _task!.id,
          commentId: commentId,
        );
    setState(() {
      _task = _task!.copyWith(
        comments: _task!.comments.where((c) => c.id != commentId).toList(),
      );
    });
  }
}

class _TaskHeader extends StatelessWidget {
  const _TaskHeader({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            TaskyPalette.lavender.withOpacity(0.3),
            TaskyPalette.mint.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: TaskyPalette.midnight,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              DeadlineUrgencyIcon(deadline: task.deadline, size: 32),
            ],
          ),
          const SizedBox(height: 12),
          TaskProgressIndicator(status: task.status),
          if (task.description?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            Text(
              task.description!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: TaskyPalette.midnight.withOpacity(0.7),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TaskInfoCard extends StatelessWidget {
  const _TaskInfoCard({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: TaskyPalette.lavender.withOpacity(0.2),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          if (task.creatorName != null)
            _InfoRow(
              icon: Icons.person_add_rounded,
              label: 'Người tạo',
              value: task.creatorName!,
              color: TaskyPalette.coral,
            ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.assignment_ind_rounded,
            label: 'Giao cho',
            value: task.assigneeName ?? 'Chưa giao',
            color: TaskyPalette.mint,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.flag_rounded,
            label: 'Trạng thái',
            value: _getStatusText(task.status),
            color: _getStatusColor(task.status),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'Deadline',
            value: task.deadline != null
                ? DateFormat('dd/MM/yyyy HH:mm').format(task.deadline!)
                : 'Không có',
            color: TaskyPalette.midnight,
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'done':
        return '🌸 Hoàn thành';
      case 'doing':
        return '🌱 Đang làm';
      default:
        return '🌤️ Chưa làm';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'done':
        return TaskyPalette.mint;
      case 'doing':
        return TaskyPalette.coral;
      default:
        return TaskyPalette.lavender;
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: TaskyPalette.midnight.withOpacity(0.6),
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LeaderControls extends StatefulWidget {
  const _LeaderControls({
    required this.task,
    required this.members,
    required this.onTaskUpdated,
    required this.onSave,
  });

  final Task task;
  final List<User> members;
  final Function(Task) onTaskUpdated;
  final VoidCallback onSave;

  @override
  State<_LeaderControls> createState() => _LeaderControlsState();
}

class _LeaderControlsState extends State<_LeaderControls> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late int? _selectedAssignee;
  late DateTime? _selectedDeadline;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descController = TextEditingController(text: widget.task.description);
    _selectedAssignee = widget.task.assignedTo;
    _selectedDeadline = widget.task.deadline;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: TaskyPalette.mint.withOpacity(0.2),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                'Chỉnh sửa (Leader)',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Tiêu đề',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _updateTask(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'Mô tả',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (_) => _updateTask(),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int?>(
            initialValue: _selectedAssignee,
            decoration: const InputDecoration(
              labelText: 'Giao cho',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Chưa giao')),
              ...widget.members.map(
                (m) => DropdownMenuItem(value: m.id, child: Text(m.name)),
              ),
            ],
            onChanged: (value) {
              setState(() => _selectedAssignee = value);
              _updateTask();
            },
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_rounded),
            title: Text(
              _selectedDeadline != null
                  ? DateFormat('dd/MM/yyyy HH:mm').format(_selectedDeadline!)
                  : 'Chọn deadline',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit_calendar_rounded),
              onPressed: _pickDeadline,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onSave,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Lưu thay đổi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: TaskyPalette.mint,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateTask() {
    final updatedTask = widget.task.copyWith(
      title: _titleController.text,
      description: _descController.text,
      assignedTo: _selectedAssignee,
      deadline: _selectedDeadline,
    );
    widget.onTaskUpdated(updatedTask);
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime:
            TimeOfDay.fromDateTime(_selectedDeadline ?? DateTime.now()),
      );

      if (time != null) {
        setState(() {
          _selectedDeadline = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
        _updateTask();
      }
    }
  }
}

class _MemberControls extends StatefulWidget {
  const _MemberControls({
    required this.task,
    required this.onTaskUpdated,
    required this.onSave,
  });

  final Task task;
  final Function(Task) onTaskUpdated;
  final VoidCallback onSave;

  @override
  State<_MemberControls> createState() => _MemberControlsState();
}

class _MemberControlsState extends State<_MemberControls> {
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.task.status;
  }

  @override
  void didUpdateWidget(_MemberControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.status != widget.task.status) {
      _selectedStatus = widget.task.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: TaskyPalette.coral.withOpacity(0.2),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.task_alt_rounded,
                  color: TaskyPalette.mint, size: 20),
              const SizedBox(width: 8),
              Text(
                'Hành động của bạn',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Cập nhật trạng thái:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatusChip(
                label: '🌤️ Chưa làm',
                value: 'todo',
                selected: _selectedStatus == 'todo',
                onSelected: () => _changeStatus('todo'),
              ),
              _StatusChip(
                label: '🌱 Nhận việc',
                value: 'doing',
                selected: _selectedStatus == 'doing',
                onSelected: () => _changeStatus('doing'),
              ),
              _StatusChip(
                label: '🌸 Hoàn thành',
                value: 'done',
                selected: _selectedStatus == 'done',
                onSelected: () => _changeStatus('done'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveStatusOnly,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Cập nhật'),
              style: ElevatedButton.styleFrom(
                backgroundColor: TaskyPalette.mint,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _changeStatus(String status) {
    setState(() => _selectedStatus = status);
    final updatedTask = widget.task.copyWith(status: status);
    widget.onTaskUpdated(updatedTask);
  }

  Future<void> _saveStatusOnly() async {
    try {
      await context
          .read<TaskProvider>()
          .updateTaskStatus(widget.task.id, _selectedStatus);
      if (!mounted) return;

      // Reload task detail
      await context.read<TaskProvider>().fetchTaskDetail(widget.task.id);

      // Nếu task được đánh dấu hoàn thành, hiển thị popup đặc biệt
      if (_selectedStatus == 'done') {
        FunNotification.taskComplete(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã cập nhật trạng thái'),
            backgroundColor: TaskyPalette.mint,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      FunNotification.error(
        context,
        title: 'Cập nhật thất bại',
        message: 'Có lỗi xảy ra: ${e.toString()}',
      );
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final String value;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: TaskyPalette.mint,
      checkmarkColor: Colors.white,
    );
  }
}

class _CommentsSection extends StatelessWidget {
  const _CommentsSection({
    required this.task,
    required this.commentController,
    required this.onAddComment,
    required this.onDeleteComment,
  });

  final Task task;
  final TextEditingController commentController;
  final VoidCallback onAddComment;
  final Function(int) onDeleteComment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Ghi chú nội bộ 💬',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (task.comments.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: TaskyPalette.lavender.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: TaskyPalette.lavender.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('💭', style: TextStyle(fontSize: 40)),
                  SizedBox(height: 8),
                  Text(
                    'Chưa có bình luận nào',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Hãy là người đầu tiên chia sẻ ý kiến nhé! ✨',
                    style: TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ...task.comments.map((comment) => _CommentTile(
                comment: comment,
                onDelete: () => onDeleteComment(comment.id),
              )),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: commentController,
                decoration: InputDecoration(
                  hintText: 'Viết bình luận thôi nào... 💭',
                  hintStyle: TextStyle(
                    color: TaskyPalette.midnight.withOpacity(0.4),
                  ),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 2,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 80,
              child: PastelButton(
                text: 'Gửi',
                onPressed: onAddComment,
                icon: '💬',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.onDelete,
  });

  final Comment comment;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(comment.userName?.substring(0, 1).toUpperCase() ?? '?'),
      ),
      title: Text(comment.userName ?? 'Ẩn danh'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(comment.content),
          const SizedBox(height: 4),
          Text(
            DateFormat('dd/MM HH:mm').format(comment.createdAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: onDelete,
      ),
    );
  }
}
