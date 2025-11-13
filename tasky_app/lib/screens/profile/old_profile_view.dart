import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../theme/palette.dart';
import '../../widgets/pastel_button.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final user = auth.currentUser;

    if (user == null) {
      return const Center(child: Text('Chưa đăng nhập rồi...'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: TaskyPalette.lavender.withOpacity(0.2),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: TaskyPalette.lavender,
                  backgroundImage:
                      user.avatar != null && user.avatar!.isNotEmpty
                          ? NetworkImage(user.avatar!)
                          : null,
                  child: user.avatar == null
                      ? Text(
                          user.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${user.userId}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: TaskyPalette.lavender,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: TaskyPalette.midnight.withOpacity(0.6),
                            ),
                      ),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(user.role),
                        avatar: const Text('🎯'),
                        backgroundColor: TaskyPalette.mint.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () => _showEditProfile(context, user),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _StatCard(
                label: 'Task hoàn thành',
                value: '${taskProvider.completedTasks}',
                emoji: '🌸',
              ),
              const SizedBox(width: 16),
              _StatCard(
                label: 'Task đang làm',
                value:
                    '${taskProvider.totalTasks - taskProvider.completedTasks}',
                emoji: '🌱',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cài đặt',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Text('🌙', style: TextStyle(fontSize: 24)),
                  title: const Text('Chuyển chế độ ngày/đêm'),
                  onTap: onToggleTheme,
                ),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Text('🔔', style: TextStyle(fontSize: 24)),
                  title: Text('Nhắc deadline sớm hơn'),
                  subtitle: Text('Sắp ra mắt, bạn nhớ cập nhật nha!'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          PastelButton(
            text: 'Đăng xuất',
            icon: '👋',
            onPressed: () async {
              await auth.logout();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (_) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showEditProfile(BuildContext context, user) async {
    final nameController = TextEditingController(text: user.name);
    final avatarController = TextEditingController(text: user.avatar ?? '');
    final auth = context.read<AuthProvider>();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chỉnh sửa hồ sơ',
              style: Theme.of(
                ctx,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Tên hiển thị'),
            ),
            TextField(
              controller: avatarController,
              decoration: const InputDecoration(
                labelText: 'Link avatar (tuỳ chọn)',
              ),
            ),
            const SizedBox(height: 16),
            PastelButton(
              text: 'Lưu thay đổi',
              icon: '💾',
              onPressed: () async {
                await auth.updateProfile(
                  name: nameController.text.trim(),
                  avatar: avatarController.text.trim().isEmpty
                      ? null
                      : avatarController.text.trim(),
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.emoji,
  });

  final String label;
  final String value;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: TaskyPalette.lavender.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: TaskyPalette.midnight.withOpacity(0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
