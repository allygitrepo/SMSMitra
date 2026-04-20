const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/db');

const SimDetail = sequelize.define('SimDetail', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  userId: {
    type: DataTypes.INTEGER,
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
  currentUsage: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
  },
  isActive: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
  }
}, {
  timestamps: true,
});

module.exports = SimDetail;
