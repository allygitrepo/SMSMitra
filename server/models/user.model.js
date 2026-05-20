const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/db');

const User = sequelize.define('User', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  fullName: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  email: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true,
    validate: {
      isEmail: true,
    },
  },
  phoneNumber: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  password: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  deviceCode: {
    type: DataTypes.STRING(4),
    unique: true,
    allowNull: false,
  },
  fcmToken: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  whatsappInstanceKey: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  whatsappProfileImage: {
    type: DataTypes.TEXT('long'),
    allowNull: true,
  },
  whatsappPhone: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  whatsappName: {
    type: DataTypes.STRING,
    allowNull: true,
  },
}, {
  timestamps: true,
});

module.exports = User;
