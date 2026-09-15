const express = require('express');
const router = express.Router();

const authRoutes = require('./auth.routes');
const smsRoutes = require('./sms.routes');
const scheduleRoutes = require('./schedule.routes');

router.use('/auth', authRoutes);
router.use('/sms', smsRoutes);
router.use('/schedules', scheduleRoutes);

router.use('/test', (req, res) => {
    res.status(200).json({
        "Server": "SMS Mitra",
        "status": "Running"
    });
});

module.exports = router;
