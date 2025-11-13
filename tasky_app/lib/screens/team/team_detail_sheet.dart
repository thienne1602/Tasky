import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/task.dart';
import '../../models/team.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/team_provider.dart';
import '../../theme/palette.dart';
import '../home/widgets/task_card.dart';
import '../tasks/create_task_sheet.dart';
import 'add_member_sheet.dart';

class TeamDetailSheet extends StatelessWidget {
  const TeamDetailSheet({
    super.key,
    required this.team,
    required this.onOpenTask,
  });

  final Team team;
  final void Function(Task task) onOpenTask;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.6,
      expand: false,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 60,
                height: 6,
                decoration: BoxDecoration(
                  color: TaskyPalette.midnight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    team.name,
                    style: Theme.of(
                      context,
                    )
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditTeamDialog(context, team);
                    } else if (value == 'delete') {
                      _showDeleteTeamDialog(context, team.id);
                    } else if (value == 'leave') {
                      _showLeaveTeamDialog(context, team.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 20),
                          SizedBox(width: 12),
                          Text('Chỉnh sửa'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_rounded,
                              size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Xóa team', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'leave',
                      child: Row(
                        children: [
                          Icon(Icons.exit_to_app_rounded,
                              size: 20, color: Colors.orange),
                          SizedBox(width: 12),
                          Text('Rời nhóm',
                              style: TextStyle(color: Colors.orange)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (team.description != null)
              Text(
                team.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: TaskyPalette.midnight.withOpacity(0.7),
                    ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Thành viên (${team.members.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showMembersManagement(context, team),
                  icon: const Icon(Icons.people_rounded, size: 18),
                  label: const Text('Quản lý'),
                  style: TextButton.styleFrom(
                    foregroundColor: TaskyPalette.coral,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _showAddMemberSheet(context, team.id),
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  label: const Text('Thêm'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: team.members
                  .map(
                    (member) => _MemberChip(
                      member: member,
                      teamId: team.id,
                      onTransferLeadership: () => Navigator.pop(context),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nhiệm vụ của team',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                // Only show create task button for leaders
                if (team.members.any(
                  (m) =>
                      m.id == context.read<AuthProvider>().currentUser?.id &&
                      (m.role == 'leader' || m.role == 'owner'),
                ))
                  IconButton(
                    onPressed: () async {
                      final taskProvider = context.read<TaskProvider>();
                      await showModalBottomSheet<bool>(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(32)),
                        ),
                        builder: (_) => CreateTaskSheet(team: team),
                      );
                      await taskProvider.fetchTasks();
                      await context.read<TeamProvider>().fetchTeams();
                    },
                    icon: const Icon(Icons.add_circle),
                    color: TaskyPalette.mint,
                    tooltip: 'Tạo task mới',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: team.tasks.isEmpty
                  ? const Center(
                      child: Text('Chưa có nhiệm vụ nào, tạo mới nhé ✨'),
                    )
                  : ListView.builder(
                      controller: controller,
                      itemCount: team.tasks.length,
                      itemBuilder: (_, index) {
                        final task = team.tasks[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: TaskCard(
                            task: task,
                            onTap: () => onOpenTask(task),
                            onStatusToggle: () async {
                              try {
                                final newStatus =
                                    task.status == 'done' ? 'todo' : 'done';
                                final updatedTask =
                                    task.copyWith(status: newStatus);
                                await context
                                    .read<TaskProvider>()
                                    .updateTask(updatedTask);
                                await context.read<TeamProvider>().fetchTeams();
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
                            onDelete: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Xóa task'),
                                  content: const Text(
                                    'Bạn có chắc chắn muốn xóa task này?\nHành động này không thể hoàn tác!',
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Hủy'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: TaskyPalette.coral,
                                      ),
                                      child: const Text('Xóa'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed == true && context.mounted) {
                                try {
                                  await context
                                      .read<TaskProvider>()
                                      .deleteTask(task.id);
                                  await context
                                      .read<TeamProvider>()
                                      .fetchTeams();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('✅ Đã xóa task'),
                                        backgroundColor: TaskyPalette.mint,
                                      ),
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
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMembersManagement(BuildContext context, Team team) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, controller) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 6,
                  decoration: BoxDecoration(
                    color: TaskyPalette.midnight.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Quản lý thành viên',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '${team.members.length} thành viên',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: TaskyPalette.midnight.withOpacity(0.6),
                    ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: team.members.length,
                  itemBuilder: (context, index) {
                    final member = team.members[index];
                    final isLeader =
                        member.role == 'leader' || member.role == 'owner';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isLeader
                              ? Colors.amber.withOpacity(0.2)
                              : TaskyPalette.lavender.withOpacity(0.3),
                          child: Text(
                            member.name.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: isLeader
                                  ? Colors.amber.shade700
                                  : TaskyPalette.midnight,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(child: Text(member.name)),
                            if (isLeader)
                              const Icon(Icons.star_rounded,
                                  color: Colors.amber, size: 16),
                          ],
                        ),
                        subtitle: Text(member.email),
                        trailing: !isLeader
                            ? PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (value) async {
                                  if (value == 'transfer') {
                                    await _transferLeadership(
                                        context, team.id, member.id);
                                  } else if (value == 'remove') {
                                    await _removeMember(
                                        context, team.id, member.id);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'transfer',
                                    child: Row(
                                      children: [
                                        Icon(Icons.admin_panel_settings_rounded,
                                            size: 18),
                                        SizedBox(width: 12),
                                        Text('Chuyển quyền leader'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'remove',
                                    child: Row(
                                      children: [
                                        Icon(Icons.person_remove_rounded,
                                            size: 18, color: Colors.red),
                                        SizedBox(width: 12),
                                        Text('Xóa khỏi team',
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : const Chip(
                                label: Text('Leader',
                                    style: TextStyle(fontSize: 12)),
                                backgroundColor: Colors.amber,
                                labelPadding:
                                    EdgeInsets.symmetric(horizontal: 8),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddMemberSheet(BuildContext context, int teamId) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => AddMemberSheet(teamId: teamId),
    );
    if (result == true && context.mounted) {
      // Refresh team detail if member was added
      Navigator.pop(context);
    }
  }

  Future<void> _showEditTeamDialog(BuildContext context, Team team) async {
    final nameController = TextEditingController(text: team.name);
    final descController = TextEditingController(text: team.description);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa Team'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Tên team',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
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
            ),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      try {
        await context.read<TeamProvider>().updateTeam(
              teamId: team.id,
              name: nameController.text.trim(),
              description: descController.text.trim(),
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã cập nhật team'),
              backgroundColor: TaskyPalette.mint,
            ),
          );
          Navigator.pop(context);
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
    }
  }

  Future<void> _showDeleteTeamDialog(BuildContext context, int teamId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa Team'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa team này?\n\n'
          'Tất cả task trong team cũng sẽ bị xóa. Hành động này không thể hoàn tác!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await context.read<TeamProvider>().deleteTeam(teamId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa team'),
              backgroundColor: TaskyPalette.mint,
            ),
          );
          Navigator.pop(context);
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
    }
  }

  Future<void> _showLeaveTeamDialog(BuildContext context, int teamId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rời khỏi Team'),
        content: const Text(
          'Bạn có chắc chắn muốn rời khỏi team này?\n\n'
          'Nếu bạn là leader, bạn cần chuyển quyền leader cho người khác trước khi rời nhóm.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Rời nhóm'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await context.read<TeamProvider>().leaveTeam(teamId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã rời khỏi team'),
              backgroundColor: TaskyPalette.mint,
            ),
          );
          Navigator.pop(context);
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
    }
  }

  Future<void> _transferLeadership(
      BuildContext context, int teamId, int newLeaderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chuyển quyền Leader'),
        content: const Text(
            'Bạn có chắc chắn muốn chuyển quyền leader cho thành viên này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('Chuyển'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await context.read<TeamProvider>().transferLeadership(
              teamId: teamId,
              newLeaderId: newLeaderId,
            );
        if (context.mounted) {
          Navigator.pop(context); // Close management sheet
          Navigator.pop(context); // Close team detail
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã chuyển quyền leader'),
              backgroundColor: TaskyPalette.mint,
            ),
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
    }
  }

  Future<void> _removeMember(
      BuildContext context, int teamId, int userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa thành viên'),
        content:
            const Text('Bạn có chắc chắn muốn xóa thành viên này khỏi team?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await context.read<TeamProvider>().removeMember(
              teamId: teamId,
              userId: userId,
            );
        if (context.mounted) {
          Navigator.pop(context); // Close management sheet
          Navigator.pop(context); // Close team detail
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa thành viên'),
              backgroundColor: TaskyPalette.mint,
            ),
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
    }
  }
}

class _MemberChip extends StatelessWidget {
  const _MemberChip({
    required this.member,
    required this.teamId,
    required this.onTransferLeadership,
  });

  final User member;
  final int teamId;
  final VoidCallback onTransferLeadership;

  @override
  Widget build(BuildContext context) {
    final isLeader = member.role == 'leader' || member.role == 'owner';

    // Only non-leader members can receive leadership transfer
    final canTransfer = isLeader == false;

    return InkWell(
      onLongPress: canTransfer ? () => _showMemberActionsDialog(context) : null,
      borderRadius: BorderRadius.circular(20),
      child: Chip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(member.name),
            if (isLeader) ...[
              const SizedBox(width: 6),
              const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
            ],
          ],
        ),
        avatar: CircleAvatar(
          child: Text(member.name.substring(0, 1).toUpperCase()),
        ),
        backgroundColor: isLeader
            ? TaskyPalette.mint.withOpacity(0.4)
            : TaskyPalette.lavender.withOpacity(0.3),
      ),
    );
  }

  Future<void> _showMemberActionsDialog(BuildContext context) async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(member.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.star_rounded, color: Colors.amber),
              title: const Text('Chuyển quyền Leader'),
              onTap: () => Navigator.pop(context, 'transfer'),
            ),
            ListTile(
              leading:
                  const Icon(Icons.person_remove_rounded, color: Colors.red),
              title: const Text('Xóa khỏi team',
                  style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context, 'remove'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );

    if (action == 'transfer' && context.mounted) {
      await _showTransferDialog(context);
    } else if (action == 'remove' && context.mounted) {
      await _showRemoveMemberDialog(context);
    }
  }

  Future<void> _showRemoveMemberDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa thành viên'),
        content: Text(
          'Bạn có muốn xóa ${member.name} khỏi team?\n\n'
          'Các task đã giao cho người này sẽ không bị xóa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await context.read<TeamProvider>().removeMember(
              teamId: teamId,
              userId: member.id,
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã xóa ${member.name} khỏi team'),
              backgroundColor: TaskyPalette.mint,
            ),
          );
          onTransferLeadership();
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
    }
  }

  Future<void> _showTransferDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chuyển quyền Leader'),
        content: Text(
          'Bạn có muốn chuyển quyền Leader cho ${member.name}?\n\n'
          'Bạn sẽ trở thành thành viên thường sau khi chuyển quyền.',
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
            ),
            child: const Text('Chuyển quyền'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await context.read<TeamProvider>().transferLeadership(
              teamId: teamId,
              newLeaderId: member.id,
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã chuyển quyền Leader cho ${member.name}'),
              backgroundColor: TaskyPalette.mint,
            ),
          );
          onTransferLeadership();
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
    }
  }
}
