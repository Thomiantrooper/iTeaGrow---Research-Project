const express = require('express');
const router = express.Router();
const alertController = require('../controllers/alert.controller');
const { protect, admin } = require('../middleware/authMiddleware');

router.post('/system-alert', alertController.sendSystemAlert);
router.get('/alert-stats', protect, admin, alertController.getAlertStats);
router.get('/recent-activity', protect, admin, alertController.getRecentActivity);
router.get('/alerts/history', protect, admin, alertController.getAlertHistory);
router.patch('/alerts/:id/status', protect, admin, alertController.updateAlertStatus);

module.exports = router;
