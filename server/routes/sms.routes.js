const express = require('express');
const router = express.Router();
const smsController = require('../controllers/sms.controller');

router.post('/trigger', smsController.sendSmsTrigger);
router.get('/reports/stats', smsController.getDailyStats);
router.get('/reports/detailed', smsController.getDetailedReports);
router.get('/reports/:userId', smsController.getReports);
router.post('/sync', smsController.syncSims);
router.post('/update-status', smsController.updateSmsStatus);
router.post('/log', smsController.createManualLog);

module.exports = router;
