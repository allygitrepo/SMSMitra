const express = require('express');
const router = express.Router();
const organizationController = require('../controllers/organization.controller');
const templateController = require('../controllers/template.controller');
const bulkController = require('../controllers/bulk.controller');
const upload = require('../middlewares/upload.middleware');

// Organization Routes
router.post('/organizations', upload.single('logo'), organizationController.createOrganization);
router.put('/organizations/:id', upload.single('logo'), organizationController.updateOrganization);
router.get('/organizations', organizationController.listOrganizations);

// Template Routes
router.post('/templates', templateController.createTemplate);
router.get('/templates', templateController.listTemplates);
router.delete('/templates/:id', templateController.deleteTemplate);

// Bulk Processing Routes
router.post('/parse-file', upload.single('file'), bulkController.parseFile);
router.post('/send', bulkController.sendBulkSmsApi);

module.exports = router;
