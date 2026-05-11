// const TelegramContact = require('../models/telegramcontact.model');
// const SmsLog = require('../models/smslog.model');
// const User = require('../models/user.model');
// const { sendTelegramMessage } = require('../services/telegramService');
// const axios = require('axios');
// 
// exports.setupWebhook = async (req, res) => {
//     try {
//         const url = `https://api.telegram.org/bot${process.env.TELEGRAM_BOT_TOKEN}/setWebhook?url=${process.env.WEBHOOK_URL}/smsmitra/v1/telegram/webhook`;
//         const response = await axios.get(url);
//         res.json({ success: true, data: response.data });
//     } catch (error) {
//         res.status(500).json({ success: false, message: error.message });
//     }
// };
// 
// exports.webhook = async (req, res) => {
//     try {
//         const update = req.body;
//         
//         if (update.message && update.message.text) {
//             const chatId = update.message.chat.id.toString();
//             const text = update.message.text;
//             const firstName = update.message.chat.first_name || 'User';
//             const username = update.message.chat.username || null;
// 
//             if (text === '/start') {
//                 // Determine user context. Without a specific payload we might just attach to the first admin or require them to pass a parameter like /start orgCode.
//                 // For this implementation, we will just store the contact. If they need to be linked to a specific user/org, we might need to parse the text.
//                 // We'll store userId as 1 (default admin) if not specified, or we should extract it.
//                 // Assuming single tenant or we expect users to provide org code. Let's just create it with a generic approach or look for /start ORG123
//                 
//                 let orgCode = null;
//                 const parts = text.split(' ');
//                 if (parts.length > 1) {
//                     orgCode = parts[1];
//                 }
// 
//                 // Defaulting userId to 1 for now if we can't determine it, as telegram bot is usually bound to the organization
//                 const userId = 1; 
// 
//                 const [contact, created] = await TelegramContact.findOrCreate({
//                     where: { telegramChatId: chatId },
//                     defaults: {
//                         userId: userId,
//                         orgCode: orgCode,
//                         name: firstName,
//                         telegramUsername: username
//                     }
//                 });
// 
//                 if (!created) {
//                     await contact.update({
//                         name: firstName,
//                         telegramUsername: username,
//                         orgCode: orgCode || contact.orgCode,
//                     });
//                 }
//                 
//                 await sendTelegramMessage(chatId, `Hello ${firstName}! You have successfully connected to SMSMitra.`);
//             }
//         }
//         res.status(200).send('OK');
//     } catch (error) {
//         console.error('Webhook Error:', error);
//         res.status(500).send('Error');
//     }
// };
// 
// exports.getContacts = async (req, res) => {
//     try {
//         const { orgCode } = req.params;
//         const whereClause = {};
//         if (orgCode && orgCode !== 'all') {
//             whereClause.orgCode = orgCode;
//         }
//         
//         const contacts = await TelegramContact.findAll({ where: whereClause });
//         res.json({ success: true, data: contacts });
//     } catch (error) {
//         res.status(500).json({ success: false, message: error.message });
//     }
// };
// 
// exports.bulkSend = async (req, res) => {
//     try {
//         const { org_code, message, contacts } = req.body;
//         
//         if (!message || !contacts || !Array.isArray(contacts) || contacts.length === 0) {
//             return res.status(400).json({ success: false, message: 'Invalid payload' });
//         }
// 
//         // Get user ID. For bulk send, we can get it from headers or use a default.
//         // Assuming API key based auth or JWT based auth. We'll extract userId if available, else 1.
//         const userId = req.user ? req.user.id : 1;
// 
//         res.json({ success: true, message: 'Telegram bulk send started' });
// 
//         // Process sequentially in background
//         (async () => {
//             for (const contact of contacts) {
//                 const personalizedMessage = message.replace(/{name}/g, contact.name || 'User');
//                 let status = 'sent';
//                 let errorMessage = null;
// 
//                 try {
//                     await sendTelegramMessage(contact.telegram_chat_id, personalizedMessage);
//                     // Add a small delay
//                     await new Promise(resolve => setTimeout(resolve, 200));
//                 } catch (error) {
//                     status = 'failed';
//                     errorMessage = error.message;
//                     
//                     // Retry once
//                     try {
//                         await new Promise(resolve => setTimeout(resolve, 1000));
//                         await sendTelegramMessage(contact.telegram_chat_id, personalizedMessage);
//                         status = 'sent';
//                         errorMessage = null;
//                     } catch (retryError) {
//                         errorMessage = retryError.message;
//                     }
//                 }
// 
//                 await SmsLog.create({
//                     userId: userId,
//                     receiverNumber: contact.telegram_chat_id, // Store chatId in receiverNumber for compatibility or telegramChatId
//                     telegramChatId: contact.telegram_chat_id,
//                     message: personalizedMessage,
//                     orgCode: org_code || null,
//                     channel: 'telegram',
//                     status: status,
//                     errorMessage: errorMessage,
//                 });
//                 
//                 // Notify via socket
//                 const io = req.app.get('io');
//                 if (io) {
//                     io.to(userId.toString()).emit('stats_update');
//                 }
//             }
//         })();
// 
//     } catch (error) {
//         console.error('Telegram Bulk Send Error:', error);
//         res.status(500).json({ success: false, message: error.message });
//     }
// };
// 