const express = require('express');
const router = express.Router();
const frequentController = require('../controllers/frequent.controller');

router.post('/', frequentController.createFrequent);
router.get('/', frequentController.getFrequentList);
router.put('/:id', frequentController.updateFrequent);
router.patch('/:id/toggle', frequentController.toggleFrequentStatus);
router.delete('/:id', frequentController.deleteFrequent);

module.exports = router;
