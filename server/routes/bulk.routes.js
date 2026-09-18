const express = require('express');
const router = express.Router();
const bulkController = require('../controllers/bulk.controller');

router.post('/send', bulkController.sendBulkSms);

module.exports = router;
