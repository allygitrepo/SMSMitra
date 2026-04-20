const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');

router.post('/register', authController.register);
router.post('/login', authController.login);
router.post('/update-token', authController.updateFcmToken);
router.post('/update-profile', authController.updateProfile);

module.exports = router;
