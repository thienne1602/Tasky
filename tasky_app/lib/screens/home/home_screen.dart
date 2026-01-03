import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/task.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/team_provider.dart';
import '../../theme/palette.dart';
import '../profile/profile_view.dart';
import '../statistics/statistics_screen.dart';
import '../team/team_hub_view.dart';
import '../tasks/create_task_sheet.dart';
import '../tasks/task_detail_screen.dart';
import 'my_tasks_view.dart';
import 'notification_list_screen.dart';
import 'task_timeline_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) {
        context.read<TaskProvider>().fetchTasks();
        context.read<TeamProvider>().fetchTeams();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final tabs = [
      TaskTimelineView(
        onOpenTask: _openTaskDetail,
        onCreateTask: _showCreateTaskSheet,
      ),
      MyTasksView(onOpenTask: _openTaskDetail),
      TeamHubView(
        onCreateTask: _showCreateTaskSheet,
        onOpenTask: _openTaskDetail,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xin chào ${user?.name.split(' ').last ?? 'bạn'} 🌸',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              'Cùng làm việc thật chill hôm nay nhé!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        actions: [
          // Statistics button
          IconButton(
            icon: const Text('📊', style: TextStyle(fontSize: 20)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StatisticsScreen(),
                ),
              );
            },
          ),

          // Notification bell icon with badge
          Consumer<NotificationProvider>(
            builder: (context, notifProvider, _) {
              final unreadCount = notifProvider.unreadCount;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_rounded),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationListScreen(),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: TaskyPalette.coral,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(
                      title: const Text('Profile 🌙'),
                    ),
                    body: const ProfileView(),
                  ),
                ),
              );
            },
            child: CircleAvatar(
              backgroundColor: TaskyPalette.lavender,
              child: Text(
                user?.name.substring(0, 1).toUpperCase() ?? '?',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Text('🌈', style: TextStyle(fontSize: 20)),
            label: 'Timeline',
          ),
          NavigationDestination(
            icon: Text('📋', style: TextStyle(fontSize: 20)),
            label: 'Task của tôi',
          ),
          NavigationDestination(
            icon: Text('🧑‍🤝‍🧑', style: TextStyle(fontSize: 20)),
            label: 'Team',
          ),
        ],
      ),
    );
  }

  void _showCreateTaskSheet() async {
    final taskProvider = context.read<TaskProvider>();
    final teamProvider = context.read<TeamProvider>();
    final teams = teamProvider.teams;
    if (teams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn cần tạo team trước nha 💌')),
      );
      return;
    }
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => CreateTaskSheet(team: teams.first),
    );
    await taskProvider.fetchTasks();
    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task mới đã sẵn sàng ✨')),
      );
    }
  }

  void _openTaskDetail(Task task) async {
    final updated = await Navigator.push<Task>(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id)),
    );
    if (updated != null && mounted) {
      context.read<TaskProvider>().fetchTasks();
    }
  }
}
