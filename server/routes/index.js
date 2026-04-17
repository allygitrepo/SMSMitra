const express = require('express');
const router = express.Router();

const authRoutes = require('./auth.routes');
const smsRoutes = require('./sms.routes');

router.use('/auth', authRoutes);
router.use('/sms', smsRoutes);

module.exports = router;
