// require('dotenv').config();
// const axios = require('axios');
// 
// const TELEGRAM_BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN;
// const WEBHOOK_URL = 'http://localhost:3000/smsmitra/v1/telegram/webhook';
// let lastUpdateId = 0;
// 
// console.log('Starting Telegram local poller...');
// 
// const poll = async () => {
//     try {
//         const url = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates?offset=${lastUpdateId + 1}&timeout=30`;
//         const response = await axios.get(url);
//         
//         if (response.data.ok) {
//             for (const update of response.data.result) {
//                 lastUpdateId = update.update_id;
//                 console.log(`Received update ${lastUpdateId}: forwarding to webhook...`);
//                 
//                 try {
//                     await axios.post(WEBHOOK_URL, update);
//                     console.log('Successfully forwarded to webhook');
//                 } catch (err) {
//                     console.error('Failed to forward to webhook:', err.message);
//                 }
//             }
//         }
//     } catch (error) {
//         console.error('Polling error:', error.message);
//     }
//     
//     // Continue polling
//     setTimeout(poll, 1000);
// };
// 
// // Clear any existing webhook to enable polling
// axios.get(`https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/deleteWebhook`).then(() => {
//     console.log('Webhook cleared, polling started.');
//     poll();
// }).catch(console.error);
// 