const xlsx = require('xlsx');
const csv = require('csv-parser');
const fs = require('fs');
const path = require('path');
const User = require('../models/user.model');
const SmsLog = require('../models/smslog.model');
const SimDetail = require('../models/simdetail.model');
const admin = require('../config/firebase');
const logger = require('../utils/logger');

exports.parseFile = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, message: 'No file uploaded' });
    }

    const filePath = req.file.path;
    const ext = path.extname(req.file.originalname).toLowerCase();
    let recipients = [];

    if (ext === '.csv') {
      recipients = await parseCSV(filePath);
    } else if (ext === '.xls' || ext === '.xlsx') {
      recipients = parseExcel(filePath);
    } else {
      fs.unlinkSync(filePath);
      return res.status(400).json({ success: false, message: 'Unsupported file format' });
    }

    // Process recipients: unique, format phone
    const uniqueRecipients = [];
    const seenPhones = new Set();

    recipients.forEach(r => {
      // Normalize keys: lowercase and trim
      const normalizedRow = {};
      Object.keys(r).forEach(key => {
        const normalizedKey = key.toLowerCase().trim().replace(/^\uFEFF/, ''); // Remove BOM if present
        normalizedRow[normalizedKey] = r[key];
      });

      let phone = normalizedRow.phone ? normalizedRow.phone.toString().trim() : '';
      let name = normalizedRow.name ? normalizedRow.name.toString().trim() : 'Guest';

      if (phone) {
        // Simple phone validation/formatting
        if (!phone.startsWith('+')) {
          if (phone.length === 10) {
            phone = '+91' + phone;
          } else if (phone.length === 12 && phone.startsWith('91')) {
            phone = '+' + phone;
          }
        }

        if (!seenPhones.has(phone)) {
          seenPhones.add(phone);
          uniqueRecipients.push({ name, phone });
        }
      }
    });

    // Delete file after parsing
    fs.unlinkSync(filePath);
    logger.info('File parsed successfully', { count: uniqueRecipients.length });

    res.json({
      success: true,
      data: uniqueRecipients
    });
  } catch (error) {
    logger.error('Error parsing file', error);
    if (req.file) fs.unlinkSync(req.file.path);
    res.status(500).json({ success: false, message: error.message });
  }
};

const parseCSV = (filePath) => {
  return new Promise((resolve, reject) => {
    const results = [];
    fs.createReadStream(filePath)
      .pipe(csv())
      .on('data', (data) => results.push(data))
      .on('end', () => resolve(results))
      .on('error', (err) => reject(err));
  });
};

const parseExcel = (filePath) => {
  const workbook = xlsx.readFile(filePath);
  const sheetName = workbook.SheetNames[0];
  const worksheet = workbook.Sheets[sheetName];
  return xlsx.utils.sheet_to_json(worksheet);
};

exports.sendBulkSmsApi = async (req, res) => {
  try {
    const { organizationCode, message, recipients } = req.body;
    logger.info('Bulk Send API Request', { organizationCode, recipientCount: recipients?.length });
    const accessCode = req.headers['x-api-key'] || req.query.apiKey;

    if (!accessCode) {
      return res.status(401).json({ success: false, message: 'API Access Code required' });
    }

    const user = await User.findOne({ where: { deviceCode: accessCode } });
    if (!user) {
      return res.status(401).json({ success: false, message: 'Invalid API Access Code' });
    }

    if (!recipients || !Array.isArray(recipients) || recipients.length === 0) {
      return res.status(400).json({ success: false, message: 'Recipients list is required' });
    }

    // In a real bulk API, we might queue these or notify the app to process them.
    // Based on requirements, the app should handle sequential sending.
    // So here we'll just create "pending" logs and return them, 
    // or maybe notify the app to "PROCESS_BULK_QUEUE".

    const createdLogs = [];
    for (const recipient of recipients) {
      const personalizedMessage = message.replace(/{name}/g, recipient.name || 'User');
      
      const log = await SmsLog.create({
        userId: user.id,
        receiverNumber: recipient.phone,
        message: personalizedMessage,
        orgCode: organizationCode || null,
        status: 'pending'
      });
      createdLogs.push(log);
    }

    // Notify app if it's connected
    if (user.fcmToken) {
        const payload = {
            token: user.fcmToken,
            data: {
              type: 'PROCESS_BULK_QUEUE',
            },
            android: { priority: 'high' }
          };
          await admin.messaging().send(payload);
          logger.info('FCM Process Signal Sent', user.id);
    }

    logger.info('Bulk messages queued', createdLogs.length);
    res.json({
      success: true,
      message: `${createdLogs.length} messages queued for sending`,
      data: createdLogs.map(l => l.id)
    });

  } catch (error) {
    logger.error('Error in sendBulkSmsApi', error);
    res.status(500).json({ success: false, message: error.message });
  }
};
