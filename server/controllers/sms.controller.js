const User = require('../models/user.model');
const SmsLog = require('../models/smslog.model');
const SimDetail = require('../models/simdetail.model');
const admin = require('../config/firebase');

exports.sendSmsTrigger = async (req, res) => {
  try {
    const { deviceCode, phoneNumber, message } = req.body;

    // 1. Verify Device
    const user = await User.findOne({ where: { deviceCode } });
    if (!user) return res.status(404).json({ message: 'Invalid Device Code' });
    if (!user.fcmToken) return res.status(400).json({ message: 'Device not registered for push notifications' });

    // 2. Create Log
    const log = await SmsLog.create({
      userId: user.id,
      receiverNumber: phoneNumber,
      message,
      status: 'pending'
    });

    // 3. Prepare FCM Payload for the Phone
    const payload = {
      token: user.fcmToken,
      data: {
        type: 'SEND_SMS',
        logId: log.id,
        phoneNumber: phoneNumber,
        message: message
      },
      android: {
        priority: 'high'
      }
    };

    // 4. Send Notification to Phone
    await admin.messaging().send(payload);

    res.json({
      message: 'SMS Trigger sent to device',
      logId: log.id
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

exports.syncSims = async (req, res) => {
  try {
    const { userId, sims } = req.body; // sims is an array of SIM objects

    // Delete old SIM details and replace with new ones (simple sync)
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

    log.status = status; // 'sent' or 'failed'
    log.errorMessage = errorMessage;
    log.simId = simId;
    await log.save();

    res.json({ message: 'Status updated' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
