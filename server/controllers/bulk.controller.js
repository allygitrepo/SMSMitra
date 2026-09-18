const { Op } = require('sequelize');
const User = require('../models/user.model');
const SmsLog = require('../models/smslog.model');
const SimDetail = require('../models/simdetail.model');
const admin = require('../config/firebase');

/**
 * Normalizes phone numbers to standard format (e.g. +919876543210)
 */
const formatPhoneNumber = (phone) => {
  if (!phone) return '';
  let cleaned = phone.toString().replace(/[^0-9+]/g, '');
  if (cleaned.startsWith('+')) return cleaned;
  if (cleaned.length === 10) return `+91${cleaned}`;
  if (cleaned.length === 12 && cleaned.startsWith('91')) return `+${cleaned}`;
  return `+${cleaned}`;
};

/**
 * Server-side Bulk SMS Dispatch Queue
 * POST /smsmitra/v1/bulk/send
 */
exports.sendBulkSms = async (req, res) => {
  try {
    const deviceCode = req.headers['x-api-key'] || req.query.apiKey || req.body.deviceCode;
    const { recipients, message, templateId } = req.body;

    if (!deviceCode) {
      return res.status(400).json({ success: false, message: 'API key / deviceCode is required' });
    }

    if (!recipients || !Array.isArray(recipients) || recipients.length === 0) {
      return res.status(400).json({ success: false, message: 'recipients list cannot be empty' });
    }

    if (!message || message.trim().length === 0) {
      return res.status(400).json({ success: false, message: 'Message content is required' });
    }

    const user = await User.findOne({ where: { deviceCode } });
    if (!user) return res.status(404).json({ success: false, message: 'Invalid device code' });

    // Select active SIM
    const sims = await SimDetail.findAll({
      where: { userId: user.id, isActive: true },
      order: [['priority', 'ASC']],
    });

    const activeSim = sims.length > 0 ? sims[0] : null;

    const createdLogs = [];
    for (const recipient of recipients) {
      const phone = formatPhoneNumber(recipient.phone || recipient.phoneNumber || recipient.mobile);
      if (!phone || phone.length < 8) continue;

      // Personalize message with all custom fields in recipient object
      let personalized = message;
      if (recipient && typeof recipient === 'object') {
        for (const [key, val] of Object.entries(recipient)) {
          if (val !== undefined && val !== null) {
            personalized = personalized.replaceAll(`{${key}}`, val.toString());
            personalized = personalized.replaceAll(`{${key.toLowerCase()}}`, val.toString());
          }
        }
      }
      // Fallback for {name}
      personalized = personalized.replaceAll('{name}', recipient.name || 'User');

      const log = await SmsLog.create({
        userId: user.id,
        receiverNumber: phone,
        message: personalized,
        simId: activeSim ? activeSim.simId : null,
        status: 'pending',
      });
      createdLogs.push(log.id);

      // If user is connected to FCM, trigger first few or batch
      if (user.fcmToken) {
        const payload = {
          token: user.fcmToken,
          data: {
            type: 'SEND_SMS',
            logId: log.id.toString(),
            phoneNumber: phone,
            message: personalized,
            simId: activeSim ? activeSim.simId : '',
          },
          android: { priority: 'high' },
        };
        try {
          await admin.messaging().send(payload);
        } catch (fcmErr) {
          console.warn('[BulkController] FCM push error for log', log.id, fcmErr.message);
        }
      }
    }

    res.status(200).json({
      success: true,
      message: `${createdLogs.length} message(s) queued for dispatch`,
      data: createdLogs,
    });
  } catch (error) {
    console.error('[BulkController] Send error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};
