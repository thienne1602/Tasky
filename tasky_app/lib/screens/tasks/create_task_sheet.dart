import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/team.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/team_provider.dart';
import '../../theme/palette.dart';
import '../../widgets/fun_notification.dart';
import '../../widgets/pastel_button.dart';

class CreateTaskSheet extends StatefulWidget {
  const CreateTaskSheet({
    super.key,
    required this.team,
  });

  final Team team;

  @override
  State<CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends State<CreateTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'vi');

  List<User> _members = [];
  int? _assigneeId;
  DateTime? _deadline;
  String _status = 'todo';
  bool _isSubmitting = false;
  bool _isLoadingMembers = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMembers());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoadingMembers = true;
      _members = [];
      _assigneeId = null;
    });
    try {
      final teamProvider = context.read<TeamProvider>();
      final detail = await teamProvider.fetchTeamDetail(widget.team.id);
      setState(() {
        _members = detail.members;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được thành viên: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingMembers = false);
      }
    }
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final initialDate = _deadline ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    final combined = DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? initialDate.hour,
      time?.minute ?? initialDate.minute,
    );
    setState(() => _deadline = combined);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await context.read<TaskProvider>().createTask(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            deadline: _deadline,
            status: _status,
            teamId: widget.team.id,
            assigneeId: _assigneeId,
          );
      if (!mounted) return;
      Navigator.pop(context, true);

      // Only show notification if creating task for yourself
      final currentUserId = context.read<AuthProvider>().currentUser?.id;
      if (_assigneeId == null || _assigneeId == currentUserId) {
        FunNotification.taskCreated(context);
      } else {
        // Task assigned to someone else, just show simple snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã tạo task và giao cho thành viên'),
            backgroundColor: TaskyPalette.mint,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      FunNotification.error(
        context,
        title: 'Tạo task thất bại',
        message: 'Đã có lỗi xảy ra, thử lại nhé! 😔',
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 60,
                height: 5,
                decoration: BoxDecoration(
                  color: TaskyPalette.midnight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Task mới nè 🎀',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Tiêu đề'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Nhập tiêu đề nhé'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Mô tả (tuỳ chọn)'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            // Show team name (read-only)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TaskyPalette.lavender.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: TaskyPalette.lavender.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.group,
                    color: TaskyPalette.lavender,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Team',
                          style: TextStyle(
                            fontSize: 12,
                            color: TaskyPalette.midnight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.team.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _StatusSelector(
              status: _status,
              onChanged: (value) => setState(() => _status = value),
            ),
            const SizedBox(height: 16),
            _DeadlinePicker(
              deadline: _deadline,
              dateFormat: _dateFormat,
              onPick: _pickDeadline,
            ),
            const SizedBox(height: 16),
            if (_isLoadingMembers)
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<int?>(
                initialValue: _assigneeId,
                decoration: const InputDecoration(labelText: 'Phân công'),
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('Chưa giao ai')),
                  ..._members.map(
                    (member) => DropdownMenuItem(
                      value: member.id,
                      child: Text(member.name),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _assigneeId = value),
              ),
            const SizedBox(height: 24),
            PastelButton(
              text: _isSubmitting ? 'Đang tạo...' : 'Lưu nhiệm vụ',
              onPressed: _isSubmitting ? null : _submit,
              icon: '🚀',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusSelector extends StatelessWidget {
  const _StatusSelector({required this.status, required this.onChanged});

  final String status;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const statuses = ['todo', 'doing', 'done'];
    String label(String value) {
      switch (value) {
        case 'done':
          return 'Hoàn thành';
        case 'doing':
          return 'Đang làm';
        default:
          return 'Todo';
      }
    }

    String emoji(String value) {
      switch (value) {
        case 'done':
          return '🌸';
        case 'doing':
          return '🌱';
        default:
          return '🌤️';
      }
    }

    return Wrap(
      spacing: 12,
      children: statuses
          .map(
            (value) => ChoiceChip(
              label: Text('${emoji(value)} ${label(value)}'),
              selected: status == value,
              onSelected: (_) => onChanged(value),
              selectedColor: TaskyPalette.mint,
            ),
          )
          .toList(),
    );
  }
}

class _DeadlinePicker extends StatelessWidget {
  const _DeadlinePicker({
    required this.deadline,
    required this.dateFormat,
    required this.onPick,
  });

  final DateTime? deadline;
  final DateFormat dateFormat;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final label = deadline == null
        ? 'Không deadline'
        : dateFormat.format(deadline!.toLocal());
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Deadline', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: TaskyPalette.midnight.withOpacity(0.7)),
            ),
          ],
        ),
        const Spacer(),
        TextButton(onPressed: onPick, child: const Text('Chọn thời gian')),
      ],
    );
  }
}
