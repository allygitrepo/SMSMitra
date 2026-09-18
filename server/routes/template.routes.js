const express = require('express');
const router = express.Router();
const templateController = require('../controllers/template.controller');

router.post('/', templateController.createTemplate);
router.get('/', templateController.listTemplates);
router.put('/:id', templateController.updateTemplate);
router.delete('/:id', templateController.deleteTemplate);

module.exports = router;
