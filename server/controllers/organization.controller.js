const Organization = require('../models/organization.model');
const logger = require('../utils/logger');

exports.createOrganization = async (req, res) => {
  try {
    logger.info('Creating organization', req.body);
    const { userId, orgName, email, address } = req.body;
    const logo = req.file ? req.file.filename : null;
    
    // Generate orgCode automatically
    const orgCode = orgName.toUpperCase().replace(/\s+/g, '_') + '_' + Math.floor(1000 + Math.random() * 9000);

    const organization = await Organization.create({
      userId,
      orgCode,
      orgName,
      email,
      address,
      logo
    });

    logger.info('Organization created successfully', organization.id);
    res.status(201).json({
      success: true,
      data: organization
    });
  } catch (error) {
    logger.error('Error creating organization', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.updateOrganization = async (req, res) => {
  try {
    const { id } = req.params;
    const { orgName, email, address } = req.body;
    const organization = await Organization.findByPk(id);

    if (!organization) {
      return res.status(404).json({ success: false, message: 'Organization not found' });
    }

    organization.orgName = orgName || organization.orgName;
    organization.email = email || organization.email;
    organization.address = address || organization.address;

    if (req.file) {
      organization.logo = req.file.filename;
    }

    await organization.save();

    res.json({
      success: true,
      data: organization
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.listOrganizations = async (req, res) => {
  try {
    const { userId } = req.query;
    const organizations = await Organization.findAll({ where: { userId } });
    res.json({
      success: true,
      data: organizations
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
