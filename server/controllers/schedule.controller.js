const { Op } = require('sequelize');
const ScheduledSms = require('../models/scheduledsms.model');
const User = require('../models/user.model');

/**
 * Creates a new scheduled SMS
 * POST /smsmitra/v1/schedules
 */
exports.createSchedule = async (req, res) => {
  try {
    const { userId, receiverNumber, message, simId, scheduledAt } = req.body;

    if (!userId || !receiverNumber || !message || !scheduledAt) {
      return res.status(400).json({
        message: 'userId, receiverNumber, message, and scheduledAt are required',
      });
    }

    const scheduledDate = new Date(scheduledAt);
    if (isNaN(scheduledDate.getTime())) {
      return res.status(400).json({ message: 'Invalid scheduledAt date format' });
    }

    if (scheduledDate.getTime() <= Date.now()) {
      return res.status(400).json({ message: 'Scheduled time must be in the future' });
    }

    const parsedUserId = parseInt(userId, 10);
    const user = await User.findByPk(parsedUserId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const schedule = await ScheduledSms.create({
      userId: parsedUserId,
      receiverNumber,
      message,
      simId: simId || null,
      scheduledAt: scheduledDate,
      status: 'scheduled',
    });

    // Notify connected socket client
    const io = req.app.get('io');
    if (io) {
      io.to(parsedUserId.toString()).emit('schedules_update');
    }

    res.status(201).json({
      success: true,
      message: 'SMS scheduled successfully',
      data: schedule,
    });
  } catch (error) {
    console.error('[ScheduleController] Create error:', error);
    res.status(500).json({ message: error.message });
  }
};

/**
 * Lists scheduled SMS for a user
 * GET /smsmitra/v1/schedules?userId=...&status=...
 */
exports.getSchedules = async (req, res) => {
  try {
    const { userId, status } = req.query;

    if (!userId) {
      return res.status(400).json({ message: 'userId query parameter is required' });
    }

    const where = { userId };
    if (status && status !== 'all') {
      where.status = status;
    }

    const schedules = await ScheduledSms.findAll({
      where,
      order: [
        ['scheduledAt', status === 'completed' || status === 'cancelled' ? 'DESC' : 'ASC'],
      ],
    });

    const counts = {
      scheduled: await ScheduledSms.count({ where: { userId, status: 'scheduled' } }),
      completed: await ScheduledSms.count({ where: { userId, status: 'completed' } }),
      cancelled: await ScheduledSms.count({ where: { userId, status: 'cancelled' } }),
      failed: await ScheduledSms.count({ where: { userId, status: 'failed' } }),
    };

    res.json({
      success: true,
      counts,
      data: schedules,
    });
  } catch (error) {
    console.error('[ScheduleController] Get error:', error);
    res.status(500).json({ message: error.message });
  }
};

/**
 * Updates a pending scheduled SMS
 * PUT /smsmitra/v1/schedules/:id
 */
exports.updateSchedule = async (req, res) => {
  try {
    const { id } = req.params;
    const { receiverNumber, message, simId, scheduledAt } = req.body;

    const schedule = await ScheduledSms.findByPk(id);
    if (!schedule) {
      return res.status(404).json({ message: 'Scheduled SMS not found' });
    }

    if (schedule.status !== 'scheduled') {
      return res.status(400).json({
        message: `Cannot edit SMS with status '${schedule.status}'`,
      });
    }

    if (receiverNumber) schedule.receiverNumber = receiverNumber;
    if (message) schedule.message = message;
    if (simId !== undefined) schedule.simId = simId || null;

    if (scheduledAt) {
      const scheduledDate = new Date(scheduledAt);
      if (isNaN(scheduledDate.getTime())) {
        return res.status(400).json({ message: 'Invalid scheduledAt date format' });
      }
      if (scheduledDate.getTime() <= Date.now()) {
        return res.status(400).json({ message: 'Scheduled time must be in the future' });
      }
      schedule.scheduledAt = scheduledDate;
    }

    await schedule.save();

    // Notify connected socket client
    const io = req.app.get('io');
    if (io) {
      io.to(schedule.userId.toString()).emit('schedules_update');
    }

    res.json({
      success: true,
      message: 'Scheduled SMS updated successfully',
      data: schedule,
    });
  } catch (error) {
    console.error('[ScheduleController] Update error:', error);
    res.status(500).json({ message: error.message });
  }
};

/**
 * Cancels a scheduled SMS
 * DELETE /smsmitra/v1/schedules/:id
 */
exports.cancelSchedule = async (req, res) => {
  try {
    const { id } = req.params;

    const schedule = await ScheduledSms.findByPk(id);
    if (!schedule) {
      return res.status(404).json({ message: 'Scheduled SMS not found' });
    }

    if (schedule.status !== 'scheduled') {
      return res.status(400).json({
        message: `Cannot cancel SMS with status '${schedule.status}'`,
      });
    }

    schedule.status = 'cancelled';
    await schedule.save();

    // Notify connected socket client
    const io = req.app.get('io');
    if (io) {
      io.to(schedule.userId.toString()).emit('schedules_update');
    }

    res.json({
      success: true,
      message: 'Scheduled SMS cancelled successfully',
      data: schedule,
    });
  } catch (error) {
    console.error('[ScheduleController] Cancel error:', error);
    res.status(500).json({ message: error.message });
  }
};
