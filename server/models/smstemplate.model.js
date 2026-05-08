const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/db');

const SmsTemplate = sequelize.define('SmsTemplate', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  userId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  templateName: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  templateMessage: {
    type: DataTypes.TEXT,
    allowNull: false,
  },
}, {
  timestamps: true,
});

module.exports = SmsTemplate;
