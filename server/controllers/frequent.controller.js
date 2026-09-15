const { Op } = require('sequelize');
const FrequentSms = require('../models/frequentsms.model');
const User = require('../models/user.model');
const { calculateNextRun } = require('../utils/recurrence');

/**
 * Creates a new recurring/frequent SMS rule
 * POST /smsmitra/v1/frequent
 */
exports.createFrequent = async (req, res) => {
  try {
    const {
      userId,
      title,
      receiverNumber,
      message,
      simId,
      frequencyType = 'daily',
      frequencyConfig = {},
      dispatchTime = '09:00',
      startDate,
    } = req.body;

    if (!userId || !receiverNumber || !message || !dispatchTime) {
      return res.status(400).json({
        message: 'userId, receiverNumber, message, and dispatchTime are required',
      });
    }

    const parsedUserId = parseInt(userId, 10);
    const user = await User.findByPk(parsedUserId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const effectiveStartDate = startDate ? new Date(startDate) : new Date();
    const nextRunAt = calculateNextRun(frequencyType, frequencyConfig, dispatchTime, effectiveStartDate);

    const frequent = await FrequentSms.create({
      userId: parsedUserId,
      title: title || null,
      receiverNumber,
      message,
      simId: simId || null,
      frequencyType,
      frequencyConfig,
      dispatchTime,
      startDate: effectiveStartDate,
      nextRunAt,
      status: 'active',
      totalDispatchedCount: 0,
    });

    const io = req.app.get('io');
    if (io) {
      io.to(parsedUserId.toString()).emit('frequent_update');
    }

    res.status(201).json({
      success: true,
      message: 'Recurring SMS rule created successfully',
      data: frequent,
    });
  } catch (error) {
    console.error('[FrequentController] Create error:', error);
    res.status(500).json({ message: error.message });
  }
};

/**
 * Lists recurring SMS rules for a user with status filter & counters
 * GET /smsmitra/v1/frequent?userId=...&status=...
 */
exports.getFrequentList = async (req, res) => {
  try {
    const { userId, status } = req.query;

    if (!userId) {
      return res.status(400).json({ message: 'userId query parameter is required' });
    }

    const where = { userId };
    if (status && status !== 'all') {
      where.status = status;
    }

    const rules = await FrequentSms.findAll({
      where,
      order: [
        ['status', 'ASC'],
        ['nextRunAt', 'ASC'],
      ],
    });

    const allRules = await FrequentSms.findAll({ where: { userId } });
    const counts = {
      active: allRules.filter(r => r.status === 'active').length,
      paused: allRules.filter(r => r.status === 'paused').length,
      totalDispatched: allRules.reduce((sum, r) => sum + (r.totalDispatchedCount || 0), 0),
    };

    res.json({
      success: true,
      counts,
      data: rules,
    });
  } catch (error) {
    console.error('[FrequentController] Get error:', error);
    res.status(500).json({ message: error.message });
  }
};

/**
 * Updates a recurring SMS rule
 * PUT /smsmitra/v1/frequent/:id
 */
exports.updateFrequent = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      title,
      receiverNumber,
      message,
      simId,
      frequencyType,
      frequencyConfig,
      dispatchTime,
      startDate,
    } = req.body;

    const rule = await FrequentSms.findByPk(id);
    if (!rule) {
      return res.status(404).json({ message: 'Recurring SMS rule not found' });
    }

    if (title !== undefined) rule.title = title;
    if (receiverNumber) rule.receiverNumber = receiverNumber;
    if (message) rule.message = message;
    if (simId !== undefined) rule.simId = simId || null;
    if (frequencyType) rule.frequencyType = frequencyType;
    if (frequencyConfig) rule.frequencyConfig = frequencyConfig;
    if (dispatchTime) rule.dispatchTime = dispatchTime;
    if (startDate) rule.startDate = new Date(startDate);

    // Recalculate nextRunAt
    rule.nextRunAt = calculateNextRun(
      rule.frequencyType,
      rule.frequencyConfig,
      rule.dispatchTime,
      new Date()
    );

    await rule.save();

    const io = req.app.get('io');
    if (io) {
      io.to(rule.userId.toString()).emit('frequent_update');
    }

    res.json({
      success: true,
      message: 'Recurring SMS rule updated successfully',
      data: rule,
    });
  } catch (error) {
    console.error('[FrequentController] Update error:', error);
    res.status(500).json({ message: error.message });
  }
};

/**
 * Toggles status between active and paused
 * PATCH /smsmitra/v1/frequent/:id/toggle
 */
exports.toggleFrequentStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const rule = await FrequentSms.findByPk(id);
    if (!rule) {
      return res.status(404).json({ message: 'Recurring SMS rule not found' });
    }

    if (rule.status === 'active') {
      rule.status = 'paused';
    } else {
      rule.status = 'active';
      // When unpausing, recalculate nextRunAt from current timestamp
      rule.nextRunAt = calculateNextRun(
        rule.frequencyType,
        rule.frequencyConfig,
        rule.dispatchTime,
        new Date()
      );
    }

    await rule.save();

    const io = req.app.get('io');
    if (io) {
      io.to(rule.userId.toString()).emit('frequent_update');
    }

    res.json({
      success: true,
      message: `Recurring rule is now ${rule.status}`,
      data: rule,
    });
  } catch (error) {
    console.error('[FrequentController] Toggle error:', error);
    res.status(500).json({ message: error.message });
  }
};

/**
 * Deletes a recurring SMS rule
 * DELETE /smsmitra/v1/frequent/:id
 */
exports.deleteFrequent = async (req, res) => {
  try {
    const { id } = req.params;
    const rule = await FrequentSms.findByPk(id);
    if (!rule) {
      return res.status(404).json({ message: 'Recurring SMS rule not found' });
    }

    const userId = rule.userId;
    await rule.destroy();

    const io = req.app.get('io');
    if (io) {
      io.to(userId.toString()).emit('frequent_update');
    }

    res.json({
      success: true,
      message: 'Recurring SMS rule deleted successfully',
    });
  } catch (error) {
    console.error('[FrequentController] Delete error:', error);
    res.status(500).json({ message: error.message });
  }
};
