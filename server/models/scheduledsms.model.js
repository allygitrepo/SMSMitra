const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/db');
const User = require('./user.model');

const ScheduledSms = sequelize.define('ScheduledSms', {
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
  scheduledAt: {
    type: DataTypes.DATE,
    allowNull: false,
  },
  status: {
    type: DataTypes.ENUM('scheduled', 'processing', 'completed', 'cancelled', 'failed'),
    defaultValue: 'scheduled',
    allowNull: false,
  },
  executedAt: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  errorMessage: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  logId: {
    type: DataTypes.INTEGER,
    allowNull: true,
  },
}, {
  timestamps: true,
  indexes: [
    {
      name: 'idx_scheduled_status_time',
      fields: ['status', 'scheduledAt'],
    },
    {
      name: 'idx_scheduled_userId',
      fields: ['userId'],
    },
  ],
});

User.hasMany(ScheduledSms, { foreignKey: 'userId', onDelete: 'CASCADE' });
ScheduledSms.belongsTo(User, { foreignKey: 'userId' });

module.exports = ScheduledSms;
