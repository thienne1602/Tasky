import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';

import '../../models/task.dart';
import '../../models/team.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/team_provider.dart';
import '../../services/api_service.dart';
import '../../theme/palette.dart';
import '../../widgets/fun_notification.dart';
import '../../widgets/pastel_button.dart';
import '../tasks/create_task_sheet.dart';
import 'team_detail_sheet.dart';

class TeamHubView extends StatefulWidget {
  const TeamHubView({
    super.key,
    required this.onCreateTask,
    required this.onOpenTask,
  });

  final VoidCallback onCreateTask;
  final void Function(Task task) onOpenTask;

  @override
  State<TeamHubView> createState() => _TeamHubViewState();
}

class _TeamHubViewState extends State<TeamHubView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeamProvider>().fetchTeams();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TeamProvider>(
      builder: (context, teamProvider, _) {
        return RefreshIndicator(
          onRefresh: teamProvider.fetchTeams,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: TaskyPalette.mint.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Teamwork makes dreams work 💫',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tạo nhóm, mời đồng đội và giao việc siêu nhanh!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withOpacity(0.7),
                          ),
                    ),
                    const SizedBox(height: 16),
                    PastelButton(
                      text: 'Tạo team mới',
                      onPressed: () => _showCreateTeamDialog(context),
                      icon: '🧑‍🤝‍🧑',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (teamProvider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (teamProvider.teams.isEmpty)
                _EmptyTeamState(
                  onCreateTeam: () => _showCreateTeamDialog(context),
                )
              else
                ...teamProvider.teams.map(
                  (team) => _TeamCard(
                    team: team,
                    onTap: () => _openTeamDetail(team.id),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCreateTeamDialog(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => const _CreateTeamSheet(),
    );

    if (result == true) {
      await context.read<TeamProvider>().fetchTeams();
    }
  }

  Future<void> _openTeamDetail(int teamId) async {
    final teamProvider = context.read<TeamProvider>();
    final team = await teamProvider.fetchTeamDetail(teamId);
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => TeamDetailSheet(
        team: team,
        onOpenTask: widget.onOpenTask,
      ),
    );
    await teamProvider.fetchTeams();
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({
    required this.team,
    required this.onTap,
  });

  final Team team;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final percent = (team.progress / 100).clamp(0.0, 1.0);
    final currentUser = context.watch<AuthProvider>().currentUser;

    // Kiểm tra xem user hiện tại có phải leader không
    final isLeader = team.members.any(
      (member) => member.id == currentUser?.id && member.role == 'leader',
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: TaskyPalette.lavender.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: TaskyPalette.lavender,
                  child: Text(team.name.substring(0, 1).toUpperCase()),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    team.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (isLeader)
                  IconButton(
                    icon: const Icon(Icons.add_task_rounded),
                    onPressed: () => _showCreateTaskSheet(context, team),
                    tooltip: 'Tạo task mới (Leader)',
                  ),
              ],
            ),
            if (team.description != null) ...[
              const SizedBox(height: 12),
              Text(
                team.description!,
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
            LinearPercentIndicator(
              lineHeight: 12,
              percent: percent,
              barRadius: const Radius.circular(12),
              backgroundColor: TaskyPalette.lavender.withOpacity(0.2),
              progressColor: TaskyPalette.mint,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${team.progress}% hoàn thành',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '${team.members.length} thành viên',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, index) {
                  final member = team.members[index];
                  return CircleAvatar(
                    radius: 18,
                    backgroundColor: TaskyPalette.aqua,
                    child: Text(member.name.substring(0, 1).toUpperCase()),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: team.members.isEmpty
                    ? 0
                    : team.members.length.clamp(0, 6).toInt(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTeamState extends StatelessWidget {
  const _EmptyTeamState({required this.onCreateTeam});

  final VoidCallback onCreateTeam;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: TaskyPalette.mint.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Text('🧑‍🤝‍🧑'),
          const SizedBox(height: 12),
          Text(
            'Chưa có team nào cả',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Tạo nhóm đầu tiên và gọi đồng đội vào ngay thôi!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: TaskyPalette.midnight.withOpacity(0.6),
                ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onCreateTeam,
            child: const Text('Tạo team mới 🌟'),
          ),
        ],
      ),
    );
  }
}

class _CreateTeamSheet extends StatefulWidget {
  const _CreateTeamSheet();

  @override
  State<_CreateTeamSheet> createState() => _CreateTeamSheetState();
}

class _CreateTeamSheetState extends State<_CreateTeamSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _searchController = TextEditingController();
  final List<User> _selectedMembers = [];
  List<User> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final api = ApiService();
      final response = await api.get('/users/search', query: {'q': query});
      final List<dynamic> data = response['data'] as List<dynamic>;
      setState(() {
        _searchResults = data
            .map((item) => User.fromJson(item as Map<String, dynamic>))
            .toList();
        _isSearching = false;
      });
    } catch (error) {
      setState(() => _isSearching = false);
    }
  }

  void _addMember(User user) {
    if (!_selectedMembers.any((m) => m.id == user.id)) {
      setState(() {
        _selectedMembers.add(user);
        _searchController.clear();
        _searchResults = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              'Team mới nè ✨',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên team',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.groups_rounded),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description_rounded),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            Text(
              'Thêm thành viên (tùy chọn)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Tìm theo tên hoặc email',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchResults = []);
                        },
                      )
                    : null,
              ),
              onChanged: _searchUsers,
            ),
            if (_isSearching) ...[
              const SizedBox(height: 12),
              const Center(child: CircularProgressIndicator()),
            ] else if (_searchResults.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border:
                      Border.all(color: TaskyPalette.lavender.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    final isAdded =
                        _selectedMembers.any((m) => m.id == user.id);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: TaskyPalette.lavender,
                        child: Text(user.name.substring(0, 1).toUpperCase()),
                      ),
                      title: Text(user.name),
                      subtitle: Text(user.email),
                      trailing: isAdded
                          ? const Icon(Icons.check_circle,
                              color: TaskyPalette.mint)
                          : IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => _addMember(user),
                              color: TaskyPalette.mint,
                            ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (_selectedMembers.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedMembers
                    .map(
                      (user) => Chip(
                        avatar: CircleAvatar(
                          backgroundColor: TaskyPalette.lavender,
                          child: Text(
                            user.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        label: Text(user.name),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() => _selectedMembers.remove(user));
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _createTeam,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TaskyPalette.mint,
                    ),
                    child: const Text('Tạo team'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _createTeam() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên team')),
      );
      return;
    }

    try {
      final teamProvider = context.read<TeamProvider>();

      // Create team first
      await teamProvider.createTeam(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
      );

      // Get the newly created team (should be the last one)
      await teamProvider.fetchTeams();
      final teams = teamProvider.teams;

      if (teams.isNotEmpty && _selectedMembers.isNotEmpty) {
        final newTeam = teams.last;

        // Add members
        for (final user in _selectedMembers) {
          try {
            await teamProvider.addMember(
              teamId: newTeam.id,
              email: user.email,
            );
          } catch (e) {
            // Continue adding other members even if one fails
            debugPrint('Failed to add member ${user.email}: $e');
          }
        }
      }

      if (!mounted) return;
      Navigator.pop(context, true);

      // Popup thông báo thú vị
      FunNotification.teamCreated(context);
    } catch (e) {
      if (!mounted) return;
      FunNotification.error(
        context,
        title: 'Tạo team thất bại',
        message: 'Đã có lỗi xảy ra, thử lại nhé! 😔',
      );
    }
  }
}

// Helper function to show create task sheet
Future<void> _showCreateTaskSheet(BuildContext context, Team team) async {
  final taskProvider = context.read<TaskProvider>();
  await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (_) => CreateTaskSheet(team: team),
  );
  await taskProvider.fetchTasks();
  await context.read<TeamProvider>().fetchTeams();
}
