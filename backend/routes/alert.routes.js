const express = require('express');
const router = express.Router();
const alertController = require('../controllers/alert.controller');

router.post('/system-alert', alertController.sendSystemAlert);

module.exports = router;
