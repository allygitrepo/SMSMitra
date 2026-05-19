const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/db');

const SmsLog = sequelize.define('SmsLog', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  userId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  receiverNumber: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  message: {
    type: DataTypes.TEXT,
    allowNull: false,
  },
  simId: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  status: {
    type: DataTypes.ENUM('pending', 'sent', 'failed'),
    defaultValue: 'pending',
  },
  errorMessage: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  orgCode: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  channel: {
    type: DataTypes.ENUM('sms', 'whatsapp'),
    defaultValue: 'sms',
  },
  /* telegramChatId: {
    type: DataTypes.STRING,
    allowNull: true,
  }, */
}, {
  timestamps: true,
});

module.exports = SmsLog;
