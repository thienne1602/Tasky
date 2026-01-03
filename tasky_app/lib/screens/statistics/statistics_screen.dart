import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/statistics.dart';
import '../../providers/auth_provider.dart';
import '../../providers/statistics_provider.dart';
import '../../providers/team_provider.dart';
import '../../theme/palette.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedView = 'all'; // 'all', 'team', 'personal'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load statistics after the first frame is built to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStatistics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    final statsProvider = context.read<StatisticsProvider>();
    final teamProvider = context.read<TeamProvider>();

    switch (_selectedView) {
      case 'all':
        await statsProvider.loadStatistics();
        break;
      case 'team':
        if (teamProvider.teams.isNotEmpty) {
          await statsProvider.loadTeamStatistics(teamProvider.teams.first.id);
        }
        break;
      case 'personal':
        final userId = context.read<AuthProvider>().currentUser?.id;
        if (userId != null) {
          await statsProvider.loadUserStatistics(userId);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Thống kê'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tổng quan'),
            Tab(text: 'Xu hướng'),
            Tab(text: 'Chi tiết'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Text('🔧'),
            tooltip: 'Test API',
            onPressed: () async {
              final statsProvider = context.read<StatisticsProvider>();
              try {
                // Test API connection first
                final result = await statsProvider.testConnection();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✅ API OK: ${result['message']}')),
                );
              } catch (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('❌ API Error: $error')),
                );
              }
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              setState(() {
                _selectedView = value;
              });
              // Small delay to ensure setState completes before loading
              await Future.delayed(const Duration(milliseconds: 10));
              _loadStatistics();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('Toàn bộ hệ thống'),
              ),
              const PopupMenuItem(
                value: 'team',
                child: Text('Nhóm của tôi'),
              ),
              const PopupMenuItem(
                value: 'personal',
                child: Text('Cá nhân'),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<StatisticsProvider>(
        builder: (context, statsProvider, _) {
          if (statsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (statsProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('❌ Không thể tải dữ liệu thống kê'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadStatistics,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final stats = statsProvider.statistics;
          if (stats == null) {
            return const Center(child: Text('Không có dữ liệu'));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(stats),
              _buildTrendTab(stats),
              _buildDetailTab(stats),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(TaskStatistics stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Tổng task',
                  stats.totalTasks.toString(),
                  TaskyPalette.mint,
                  Icons.task,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Hoàn thành',
                  '${stats.completionRate.round()}%',
                  TaskyPalette.aqua,
                  Icons.check_circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Đang làm',
                  stats.inProgressTasks.toString(),
                  TaskyPalette.lavender,
                  Icons.work,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Chưa làm',
                  stats.pendingTasks.toString(),
                  TaskyPalette.coral,
                  Icons.pending,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Text(
            '📈 Phân bố trạng thái',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: _getStatusPieSections(stats),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            '🏆 Team Performance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...stats.teamPerformance.map((team) => _buildTeamPerformanceCard(team)),
        ],
      ),
    );
  }

  Widget _buildTrendTab(TaskStatistics stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Xu hướng hoàn thành',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            height: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: stats.completionTrend.asMap().entries.map((entry) {
                      final data = entry.value;
                      return FlSpot(entry.key.toDouble(), data.completed.toDouble());
                    }).toList(),
                    isCurved: true,
                    color: TaskyPalette.mint,
                    barWidth: 4,
                    belowBarData: BarAreaData(
                      show: true,
                      color: TaskyPalette.mint.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTab(TaskStatistics stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '👥 Thống kê theo thành viên',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...stats.tasksByUser.entries.map((entry) {
            final userName = entry.key;
            final taskCount = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: TaskyPalette.lavender,
                  child: Text(userName[0].toUpperCase()),
                ),
                title: Text(userName),
                trailing: Text(
                  '$taskCount task',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          }),

          const SizedBox(height: 24),
          const Text(
            '📋 Chi tiết trạng thái',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...stats.tasksByStatus.entries.map((entry) {
            final status = entry.key;
            final count = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  _getStatusIcon(status),
                  color: _getStatusColor(status),
                ),
                title: Text(_getStatusLabel(status)),
                trailing: Text(
                  '$count task',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamPerformanceCard(TeamPerformanceData team) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team.teamName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${team.completedTasks}/${team.totalTasks} task hoàn thành',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: team.completionRate / 100,
                backgroundColor: TaskyPalette.lavender.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(TaskyPalette.mint),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '${team.completionRate.round()}%',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _getStatusPieSections(TaskStatistics stats) {
    final colors = [TaskyPalette.coral, TaskyPalette.lavender, TaskyPalette.mint];
    final statuses = ['todo', 'doing', 'done'];

    return statuses.asMap().entries.map((entry) {
      final index = entry.key;
      final status = entry.value;
      final count = stats.tasksByStatus[status] ?? 0;

      return PieChartSectionData(
        value: count.toDouble(),
        title: '${_getStatusLabel(status)}\n$count',
        color: colors[index],
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'todo':
        return Icons.circle_outlined;
      case 'doing':
        return Icons.work;
      case 'done':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'todo':
        return TaskyPalette.coral;
      case 'doing':
        return TaskyPalette.lavender;
      case 'done':
        return TaskyPalette.mint;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'todo':
        return 'Chưa làm';
      case 'doing':
        return 'Đang làm';
      case 'done':
        return 'Hoàn thành';
      default:
        return status;
    }
  }
}
