// const axios = require("axios");
// 
// const TELEGRAM_BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN;
// 
// const sendTelegramMessage = async (chatId, message) => {
//     try {
//         const url = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`;
// 
//         const response = await axios.post(url, {
//             chat_id: chatId,
//             text: message,
//             parse_mode: "HTML",
//         });
// 
//         return response.data;
//     } catch (error) {
//         console.log("Telegram Error:", error.message);
//         throw error;
//     }
// };
// 
// module.exports = {
//     sendTelegramMessage,
// };