const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/db');
const User = require('./user.model');

const FrequentSms = sequelize.define('FrequentSms', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  userId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: User,
      key: 'id',
    },
  },
  title: {
    type: DataTypes.STRING,
    allowNull: true,
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
  frequencyType: {
    type: DataTypes.ENUM('daily', 'alternate', 'weekly', 'monthly', 'custom'),
    allowNull: false,
    defaultValue: 'daily',
  },
  frequencyConfig: {
    type: DataTypes.JSON,
    allowNull: false,
    defaultValue: {},
  },
  dispatchTime: {
    type: DataTypes.STRING(10), // e.g. "09:30" (HH:mm)
    allowNull: false,
  },
  startDate: {
    type: DataTypes.DATEONLY,
    allowNull: false,
  },
  nextRunAt: {
    type: DataTypes.DATE,
    allowNull: false,
  },
  lastRunAt: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  totalDispatchedCount: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  },
  status: {
    type: DataTypes.ENUM('active', 'paused', 'completed', 'cancelled'),
    allowNull: false,
    defaultValue: 'active',
  },
}, {
  timestamps: true,
  indexes: [
    {
      name: 'idx_frequent_status_nextRun',
      fields: ['status', 'nextRunAt'],
    },
    {
      name: 'idx_frequent_userId',
      fields: ['userId'],
    },
  ],
});

User.hasMany(FrequentSms, { foreignKey: 'userId', onDelete: 'CASCADE' });
FrequentSms.belongsTo(User, { foreignKey: 'userId' });

module.exports = FrequentSms;
