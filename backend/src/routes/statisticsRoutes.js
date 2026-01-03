const express = require('express');
const router = express.Router();
const statisticsController = require('../controllers/statisticsController');
const authMiddleware = require('../middleware/authMiddleware');

// All statistics routes require authentication
router.use(authMiddleware);

// Test endpoint (no auth required)
router.get('/debug', (req, res) => {
  res.json({
    success: true,
    message: 'Statistics API is working',
    timestamp: new Date().toISOString()
  });
});

// Test endpoint with auth
router.get('/test', (req, res) => {
  res.json({
    success: true,
    message: 'Statistics API is working with auth',
    user: req.user,
    timestamp: new Date().toISOString()
  });
});

// Get overall system statistics
router.get('/', statisticsController.getStatistics);

// Get team-specific statistics
router.get('/teams/:teamId', statisticsController.getTeamStatistics);

// Get user-specific statistics
router.get('/users/:userId', statisticsController.getUserStatistics);

module.exports = router;
