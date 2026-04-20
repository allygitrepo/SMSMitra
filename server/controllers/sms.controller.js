const { Op } = require('sequelize');
const User = require('../models/user.model');
const SmsLog = require('../models/smslog.model');
const SimDetail = require('../models/simdetail.model');
const admin = require('../config/firebase');

exports.sendSmsTrigger = async (req, res) => {
  try {
    const { deviceCode, phoneNumber, message } = req.body;

    const user = await User.findOne({ where: { deviceCode } });
    if (!user) return res.status(404).json({ message: 'Invalid Device Code' });
    if (!user.fcmToken) return res.status(400).json({ message: 'Device not registered for push notifications' });

    // Find the best SIM based on priority and limits
    const sims = await SimDetail.findAll({
      where: { userId: user.id, isActive: true },
      order: [['priority', 'ASC']]
    });

    let selectedSim = null;
    const today = new Date(new Date().toLocaleString("en-US", {timeZone: "Asia/Kolkata"}));
    today.setHours(0, 0, 0, 0);

    for (const sim of sims) {
      // Reset usage if it's a new day
      const lastUpdate = new Date(sim.updatedAt).toDateString();
      if (lastUpdate !== today) {
        sim.currentUsage = 0;
        await sim.save();
      }

      if (sim.currentUsage < sim.dailyLimit) {
        selectedSim = sim;
        break;
      }
    }

    if (!selectedSim && sims.length > 0) {
      return res.status(400).json({ message: 'All SIMs have reached their daily limits' });
    }

    const log = await SmsLog.create({
      userId: user.id,
      receiverNumber: phoneNumber,
      message,
      simId: selectedSim ? selectedSim.simId : null,
      status: 'pending'
    });

    const payload = {
      token: user.fcmToken,
      data: {
        type: 'SEND_SMS',
        logId: log.id.toString(),
        phoneNumber: phoneNumber,
        message: message,
        simId: selectedSim ? selectedSim.simId : '' // Tell phone which SIM to use
      },
      android: {
        priority: 'high'
      }
    };

    await admin.messaging().send(payload);

    // Increment usage
    if (selectedSim) {
      selectedSim.currentUsage += 1;
      await selectedSim.save();
    }

    res.json({
      message: 'SMS Trigger sent to device',
      logId: log.id,
      simUsed: selectedSim ? selectedSim.carrierName : 'Default'
    });
  } catch (error) {
    console.error('FCM Error:', error);
    res.status(500).json({ message: 'Failed to trigger SMS on device' });
  }
};

exports.getReports = async (req, res) => {
  try {
    const { userId } = req.params;
    const logs = await SmsLog.findAll({
      where: { userId },
      order: [['createdAt', 'DESC']],
      limit: 50
    });
    res.json(logs);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getDailyStats = async (req, res) => {
  try {
    const { userId } = req.query;
    if (!userId) return res.status(400).json({ message: 'userId is required' });

    const today = new Date(new Date().toLocaleString("en-US", {timeZone: "Asia/Kolkata"}));
    today.setHours(0, 0, 0, 0);

    const sentToday = await SmsLog.count({
      where: {
        userId,
        status: 'sent',
        createdAt: { [Op.gte]: today }
      }
    });

    const failedToday = await SmsLog.count({
      where: {
        userId,
        status: 'failed',
        createdAt: { [Op.gte]: today }
      }
    });

    res.json({
      success: true,
      data: {
        sentToday,
        failedToday
      }
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getDetailedReports = async (req, res) => {
  try {
    const { userId, startDate, endDate, simId } = req.query;
    if (!userId) return res.status(400).json({ message: 'userId is required' });

    const where = { userId };

    if (startDate && endDate) {
      const end = new Date(endDate);
      end.setHours(23, 59, 59, 999);
      where.createdAt = { [Op.between]: [new Date(startDate), end] };
    } else if (startDate) {
      where.createdAt = { [Op.gte]: new Date(startDate) };
    } else if (endDate) {
      const end = new Date(endDate);
      end.setHours(23, 59, 59, 999);
      where.createdAt = { [Op.lte]: end };
    }

    if (simId && simId !== 'all') {
      where.simId = simId;
    }

    const logs = await SmsLog.findAll({
      where,
      order: [['createdAt', 'DESC']]
    });

    const stats = {
      pending: logs.filter(l => l.status === 'pending').length,
      sent: logs.filter(l => l.status === 'sent').length,
      failed: logs.filter(l => l.status === 'failed').length
    };

    res.json({
      success: true,
      data: { stats, logs }
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.syncSims = async (req, res) => {
  try {
    const { userId, sims } = req.body;
    await SimDetail.destroy({ where: { userId } });
    
    const simEntries = sims.map((sim, index) => ({
      userId,
      simId: sim.id,
      carrierName: sim.carrierName,
      phoneNumber: sim.number,
      dailyLimit: sim.dailyLimit || 100,
      limitPeriod: sim.limitPeriod || 'day',
      priority: index + 1,
      isActive: true
    }));

    await SimDetail.bulkCreate(simEntries);
    res.json({ message: 'SIM details synced successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.updateSmsStatus = async (req, res) => {
  try {
    const { logId, status, errorMessage, simId } = req.body;
    const log = await SmsLog.findByPk(logId);
    if (!log) return res.status(404).json({ message: 'Log not found' });

    log.status = status;
    log.errorMessage = errorMessage;
    log.simId = simId;
    await log.save();
    res.json({ message: 'Status updated' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.createManualLog = async (req, res) => {
  try {
    const { userId, phoneNumber, message, simId, status } = req.body;
    const log = await SmsLog.create({
      userId,
      receiverNumber: phoneNumber,
      message,
      simId,
      status
    });
    res.status(201).json(log);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
