const db = require('../config/db');

class StatisticsController {
  // Get overall system statistics
  async getStatistics(req, res) {
    try {
      console.log('📊 Getting statistics for user:', req.user?.id);

      // Return mock data for testing
      const mockData = {
        totalTasks: 24,
        completedTasks: 8,
        pendingTasks: 10,
        inProgressTasks: 6,
        completionRate: 33.3,
        tasksByStatus: { 'todo': 10, 'doing': 6, 'done': 8 },
        tasksByTeam: { 'Frontend Team': 12, 'Backend Team': 12 },
        tasksByUser: {
          'Nguyễn Văn Minh': 3,
          'Trần Thị Lan': 3,
          'Lê Hoàng Anh': 2,
          'Phạm Thị Mai': 2
        },
        completionTrend: [
          { date: '2025-01-01', completed: 1, total: 2 },
          { date: '2025-01-02', completed: 2, total: 4 },
          { date: '2025-01-03', completed: 3, total: 6 }
        ],
        teamPerformance: [
          { teamName: 'Frontend Team', completedTasks: 4, totalTasks: 12, completionRate: 33.3 },
          { teamName: 'Backend Team', completedTasks: 4, totalTasks: 12, completionRate: 33.3 }
        ]
      };

      console.log('📊 Returning mock data');
      return res.json({ success: true, data: mockData });
    } catch (error) {
      console.error('Error getting statistics:', error);
      res.status(500).json({
        success: false,
        message: 'Error fetching statistics'
      });
    }
  }

  // Get team-specific statistics
  async getTeamStatistics(req, res) {
    try {
      const { teamId } = req.params;

      // Return mock data for team
      const mockData = {
        totalTasks: 12,
        completedTasks: 4,
        pendingTasks: 5,
        inProgressTasks: 3,
        completionRate: 33.3,
        tasksByStatus: { 'todo': 5, 'doing': 3, 'done': 4 },
        tasksByTeam: { 'Frontend Team': 12 },
        tasksByUser: {
          'Nguyễn Văn Minh': 2,
          'Lê Hoàng Anh': 1,
          'Phạm Thị Mai': 1
        },
        completionTrend: [
          { date: '2025-01-01', completed: 1, total: 2 },
          { date: '2025-01-02', completed: 1, total: 3 }
        ],
        teamPerformance: [
          { teamName: 'Frontend Team', completedTasks: 4, totalTasks: 12, completionRate: 33.3 }
        ]
      };

      return res.json({ success: true, data: mockData });
    } catch (error) {
      console.error('Error getting team statistics:', error);
      res.status(500).json({
        success: false,
        message: 'Error fetching team statistics'
      });
    }
  }

  // Get user-specific statistics
  async getUserStatistics(req, res) {
    try {
      const { userId } = req.params;

      // Return mock data for user
      const mockData = {
        totalTasks: 3,
        completedTasks: 1,
        pendingTasks: 1,
        inProgressTasks: 1,
        completionRate: 33.3,
        tasksByStatus: { 'todo': 1, 'doing': 1, 'done': 1 },
        tasksByTeam: { 'Frontend Team': 3 },
        tasksByUser: { 'Nguyễn Văn Minh': 3 },
        completionTrend: [
          { date: '2025-01-01', completed: 0, total: 1 },
          { date: '2025-01-02', completed: 1, total: 2 }
        ],
        teamPerformance: [
          { teamName: 'Frontend Team', completedTasks: 1, totalTasks: 3, completionRate: 33.3 }
        ]
      };

      return res.json({ success: true, data: mockData });
    } catch (error) {
      console.error('Error getting user statistics:', error);
      res.status(500).json({
        success: false,
        message: 'Error fetching user statistics'
      });
    }
  }
}

module.exports = new StatisticsController();