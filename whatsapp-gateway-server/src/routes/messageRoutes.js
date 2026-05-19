const express = require('express');
const router = express.Router();
const messageController = require('../controllers/messageController');
const upload = require('../middleware/uploadMiddleware');

router.post('/send', upload.single('file'), messageController.sendMessage);
router.post('/bulk', messageController.sendBulkMessage);

module.exports = router;
