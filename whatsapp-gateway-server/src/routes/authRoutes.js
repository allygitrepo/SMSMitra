const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

router.post('/start-session', authController.startSession);
router.get('/status', authController.getStatus);
router.post('/disconnect', authController.disconnect);

module.exports = router;
