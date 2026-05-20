const axios = require('axios');
const User = require('../models/user.model');
const SmsLog = require('../models/smslog.model');
const logger = require('../utils/logger');

// Base URL for the remote wa-mitra API
const WA_MITRA_BASE_URL = 'https://silverapi.allysoftsolutions.com/wa-mitra/api/v1';

// Helper to get headers for wa-mitra requests
const getHeaders = () => {
  const token = process.env.WA_MITRA_MASTER_TOKEN || 'mitra_abc123...';
  return {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  };
};

/**
 * Initiates or refreshes a WhatsApp instance
 */
exports.initiateSession = async (req, res) => {
  try {
    const { userId } = req.body;
    if (!userId) {
      return res.status(400).json({ success: false, message: 'userId is required' });
    }

    const user = await User.findByPk(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    let payload = {};
    if (user.whatsappInstanceKey) {
      payload.instanceKey = user.whatsappInstanceKey;
    } else {
      // Create a clean instance name using user's name
      const safeName = user.fullName.replace(/[^a-zA-Z0-9]/g, '_');
      payload.name = `SMSMitra_${safeName}`;
    }

    logger.info(`Initiating WhatsApp session for user ${userId}`, payload);

    const response = await axios.post(`${WA_MITRA_BASE_URL}/instance/initiate`, payload, {
      headers: getHeaders()
    });

    const data = response.data;

    if (data.success) {
      // If we got a new instance key, save it
      if (data.instanceKey && !user.whatsappInstanceKey) {
        user.whatsappInstanceKey = data.instanceKey;
        await user.save();
      }

      // If connected, sync WhatsApp details
      if (data.status === 'connected') {
        user.whatsappProfileImage = data.profileImage || null;
        user.whatsappPhone = data.phone || null;
        user.whatsappName = data.name || null;
        await user.save();
      }
    }

    res.json(data);
  } catch (error) {
    logger.error('WhatsApp Initiate Error:', error.response?.data || error.message);
    res.status(error.response?.status || 500).json({
      success: false,
      message: error.response?.data?.message || error.message
    });
  }
};

/**
 * Fetches the live status of the WhatsApp session
 */
exports.getSessionStatus = async (req, res) => {
  try {
    const { userId } = req.query;
    if (!userId) {
      return res.status(400).json({ success: false, message: 'userId is required' });
    }

    const user = await User.findByPk(userId);
    if (!user || !user.whatsappInstanceKey) {
      return res.json({ success: false, status: 'disconnected', message: 'No WhatsApp session linked' });
    }

    logger.info(`Checking WhatsApp status for user ${userId} (Key: ${user.whatsappInstanceKey})`);

    const response = await axios.post(`${WA_MITRA_BASE_URL}/instance/initiate`, {
      instanceKey: user.whatsappInstanceKey
    }, {
      headers: getHeaders()
    });

    const data = response.data;

    // Sync state based on status
    if (data.success) {
      if (data.status === 'connected') {
        user.whatsappProfileImage = data.profileImage || user.whatsappProfileImage;
        user.whatsappPhone = data.phone || user.whatsappPhone;
        user.whatsappName = data.name || user.whatsappName;
        await user.save();
      } else if (data.status === 'disconnected') {
        // Clear columns if session is no longer active
        user.whatsappInstanceKey = null;
        user.whatsappProfileImage = null;
        user.whatsappPhone = null;
        user.whatsappName = null;
        await user.save();
      }
    }

    res.json(data);
  } catch (error) {
    logger.error('WhatsApp Status Error:', error.response?.data || error.message);
    res.status(error.response?.status || 500).json({
      success: false,
      message: error.response?.data?.message || error.message
    });
  }
};

/**
 * Disconnects and deletes a WhatsApp instance
 */
exports.deleteSession = async (req, res) => {
  try {
    const { userId } = req.query;
    if (!userId) {
      return res.status(400).json({ success: false, message: 'userId is required' });
    }

    const user = await User.findByPk(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    if (!user.whatsappInstanceKey) {
      return res.json({ success: true, message: 'No active session to delete' });
    }

    logger.info(`Deleting WhatsApp instance for user ${userId} (Key: ${user.whatsappInstanceKey})`);

    let responseData = { success: true };
    try {
      const response = await axios.delete(`${WA_MITRA_BASE_URL}/instance/delete`, {
        params: { instanceKey: user.whatsappInstanceKey },
        headers: getHeaders()
      });
      responseData = response.data;
    } catch (apiErr) {
      // If instance is already gone on the gateway, let's still clear it locally
      logger.warn('Instance deletion failed on gateway, cleaning up local record anyway.', apiErr.message);
    }

    // Clean up local user table fields
    user.whatsappInstanceKey = null;
    user.whatsappProfileImage = null;
    user.whatsappPhone = null;
    user.whatsappName = null;
    await user.save();

    res.json(responseData);
  } catch (error) {
    logger.error('WhatsApp Delete Error:', error.response?.data || error.message);
    res.status(error.response?.status || 500).json({
      success: false,
      message: error.response?.data?.message || error.message
    });
  }
};

/**
 * Sends bulk WhatsApp messages and logs them in SmsLog database
 */
exports.sendBulkWhatsApp = async (req, res) => {
  try {
    const { userId, messages, orgCode } = req.body;
    if (!userId || !messages || !Array.isArray(messages)) {
      return res.status(400).json({ success: false, message: 'userId and messages array are required' });
    }

    const user = await User.findByPk(userId);
    if (!user || !user.whatsappInstanceKey) {
      return res.status(400).json({ success: false, message: 'WhatsApp is not linked' });
    }

    logger.info(`Sending ${messages.length} bulk WhatsApp messages for user ${userId}`);

    // Create pending logs in local DB
    const createdLogs = [];
    for (const msg of messages) {
      const log = await SmsLog.create({
        userId: user.id,
        receiverNumber: msg.number,
        message: msg.message,
        simId: 'whatsapp',
        channel: 'whatsapp',
        orgCode: orgCode || null,
        status: 'pending'
      });
      createdLogs.push(log);
    }

    // Call the wa-mitra bulk endpoint
    const response = await axios.post(`${WA_MITRA_BASE_URL}/messages/bulk`, {
      instanceKey: user.whatsappInstanceKey,
      messages: messages
    }, {
      headers: getHeaders()
    });

    const data = response.data;

    if (data.success) {
      // Mark all logs as sent
      for (const log of createdLogs) {
        log.status = 'sent';
        await log.save();
      }
      res.json({
        success: true,
        message: 'Bulk WhatsApp messages successfully sent',
        details: data
      });
    } else {
      // Mark all logs as failed
      for (const log of createdLogs) {
        log.status = 'failed';
        log.errorMessage = data.message || 'Gateway failed to queue messages';
        await log.save();
      }
      res.status(500).json({
        success: false,
        message: data.message || 'Failed to queue bulk WhatsApp messages',
        details: data
      });
    }
  } catch (error) {
    logger.error('WhatsApp Bulk Send Error:', error.response?.data || error.message);
    res.status(error.response?.status || 500).json({
      success: false,
      message: error.response?.data?.message || error.message
    });
  }
};
