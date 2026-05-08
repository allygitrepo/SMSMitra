const SmsTemplate = require('../models/smstemplate.model');
const logger = require('../utils/logger');

exports.createTemplate = async (req, res) => {
  try {
    logger.info('Creating template', req.body);
    const { userId, templateName, templateMessage } = req.body;

    const template = await SmsTemplate.create({
      userId,
      templateName,
      templateMessage
    });

    logger.info('Template created', template.id);
    res.status(201).json({
      success: true,
      data: template
    });
  } catch (error) {
    logger.error('Error creating template', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.listTemplates = async (req, res) => {
  try {
    const { userId } = req.query;
    const templates = await SmsTemplate.findAll({ where: { userId } });
    res.json({
      success: true,
      data: templates
    });
  } catch (error) {
    logger.error('Error listing templates', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.deleteTemplate = async (req, res) => {
  try {
    const { id } = req.params;
    await SmsTemplate.destroy({ where: { id } });
    logger.info('Template deleted', id);
    res.json({
      success: true,
      message: 'Template deleted'
    });
  } catch (error) {
    logger.error('Error deleting template', error);
    res.status(500).json({ success: false, message: error.message });
  }
};
