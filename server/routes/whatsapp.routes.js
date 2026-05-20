const express = require('express');
const router = express.Router();
const whatsappController = require('../controllers/whatsapp.controller');

router.post('/initiate', whatsappController.initiateSession);
router.get('/status', whatsappController.getSessionStatus);
router.delete('/delete', whatsappController.deleteSession);
router.post('/send-bulk', whatsappController.sendBulkWhatsApp);

module.exports = router;
