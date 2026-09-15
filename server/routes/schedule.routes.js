const express = require('express');
const router = express.Router();
const scheduleController = require('../controllers/schedule.controller');

router.post('/', scheduleController.createSchedule);
router.get('/', scheduleController.getSchedules);
router.put('/:id', scheduleController.updateSchedule);
router.delete('/:id', scheduleController.cancelSchedule);

module.exports = router;
