const SmsTemplate = require('../models/smstemplate.model');

/**
 * Creates a new SMS Template
 * POST /smsmitra/v1/templates
 */
exports.createTemplate = async (req, res) => {
  try {
    const { userId, templateName, templateMessage } = req.body;

    if (!userId || !templateName || !templateMessage) {
      return res.status(400).json({
        success: false,
        message: 'userId, templateName, and templateMessage are required',
      });
    }

    const template = await SmsTemplate.create({
      userId: parseInt(userId, 10),
      templateName: templateName.trim(),
      templateMessage: templateMessage.trim(),
    });

    res.status(201).json({
      success: true,
      message: 'Template created successfully',
      data: template,
    });
  } catch (error) {
    console.error('[TemplateController] Create error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * Lists all SMS templates for a user
 * GET /smsmitra/v1/templates?userId=X
 */
exports.listTemplates = async (req, res) => {
  try {
    const { userId } = req.query;

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: 'userId query parameter is required',
      });
    }

    const templates = await SmsTemplate.findAll({
      where: { userId: parseInt(userId, 10) },
      order: [['createdAt', 'DESC']],
    });

    res.json({
      success: true,
      data: templates,
    });
  } catch (error) {
    console.error('[TemplateController] List error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * Updates an SMS Template
 * PUT /smsmitra/v1/templates/:id
 */
exports.updateTemplate = async (req, res) => {
  try {
    const { id } = req.params;
    const { templateName, templateMessage } = req.body;

    const template = await SmsTemplate.findByPk(id);
    if (!template) {
      return res.status(404).json({ success: false, message: 'Template not found' });
    }

    if (templateName) template.templateName = templateName.trim();
    if (templateMessage) template.templateMessage = templateMessage.trim();

    await template.save();

    res.json({
      success: true,
      message: 'Template updated successfully',
      data: template,
    });
  } catch (error) {
    console.error('[TemplateController] Update error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * Deletes an SMS Template
 * DELETE /smsmitra/v1/templates/:id
 */
exports.deleteTemplate = async (req, res) => {
  try {
    const { id } = req.params;

    const template = await SmsTemplate.findByPk(id);
    if (!template) {
      return res.status(404).json({ success: false, message: 'Template not found' });
    }

    await template.destroy();

    res.json({
      success: true,
      message: 'Template deleted successfully',
    });
  } catch (error) {
    console.error('[TemplateController] Delete error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};
