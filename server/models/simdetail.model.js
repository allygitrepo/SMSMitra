const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/db');

const SimDetail = sequelize.define('SimDetail', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  userId: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  simId: {
    type: DataTypes.STRING, // Native Subscription ID
    allowNull: false,
  },
  carrierName: {
    type: DataTypes.STRING,
  },
  phoneNumber: {
    type: DataTypes.STRING,
  },
  dailyLimit: {
    type: DataTypes.INTEGER,
    defaultValue: 100,
  },
  limitPeriod: {
    type: DataTypes.STRING,
    defaultValue: 'day',
  },
  priority: {
    type: DataTypes.INTEGER,
    defaultValue: 1,
  },
  isActive: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
  }
}, {
  timestamps: true,
});

module.exports = SimDetail;
