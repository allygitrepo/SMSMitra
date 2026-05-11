const { Op } = require('sequelize');
const User = require('../models/user.model');
const SmsLog = require('../models/smslog.model');
const SimDetail = require('../models/simdetail.model');
const admin = require('../config/firebase');

const notifyStatsUpdate = async (userId, io) => {
  try {
    if (io) {
      io.to(userId.toString()).emit('stats_update');
    }
    const user = await User.findByPk(userId);
    if (user && user.fcmToken) {
      const payload = {
        token: user.fcmToken,
        data: {
          type: 'STATS_UPDATE'
        },
        android: {
          priority: 'high'
        }
      };
      await admin.messaging().send(payload);
    }
  } catch (error) {
    console.error('Notify Stats Error:', error);
  }
};

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
      if (lastUpdate !== today.toDateString()) {
        sim.currentUsage = 0;
        await sim.save();
      }

      if (sim.dailyLimit === -1 || sim.currentUsage < sim.dailyLimit) {
        selectedSim = sim;
        break;
      }
    }

    if (!selectedSim) {
      return res.status(400).json({
        message: sims.length === 0 
          ? 'No SIM cards synced with this device' 
          : 'All SIMs have reached their daily limits'
      });
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

    // Trigger UI update on app
    notifyStatsUpdate(user.id, req.app.get('io'));

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

    if (req.query.orgCode) {
      if (req.query.orgCode === 'none') {
        where.orgCode = null;
      } else if (req.query.orgCode !== 'all') {
        where.orgCode = req.query.orgCode;
      }
    }

    if (req.query.channel) {
      if (req.query.channel !== 'all') {
        where.channel = req.query.channel;
      }
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

    // If a TRIGGERED SMS failed, we should return the reserved quota
    if (status === 'failed' && simId) {
      const sim = await SimDetail.findOne({ where: { userId: log.userId, simId } });
      if (sim && sim.currentUsage > 0) {
        sim.currentUsage -= 1;
        await sim.save();
      }
    }

    // Trigger UI update on app
    notifyStatsUpdate(log.userId, req.app.get('io'));

    res.json({ message: 'Status updated' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.createManualLog = async (req, res) => {
  try {
    const { userId, phoneNumber, message, simId, status, orgCode } = req.body;
    const log = await SmsLog.create({
      userId,
      receiverNumber: phoneNumber,
      message,
      simId,
      status,
      orgCode
    });

    // Increment usage on SIM for manual sends
    if (status === 'sent' && simId) {
      const sim = await SimDetail.findOne({ where: { userId, simId } });
      if (sim) {
        sim.currentUsage += 1;
        await sim.save();
      }
    }

    // Trigger UI update on app
    notifyStatsUpdate(userId, req.app.get('io'));

    res.status(201).json(log);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
