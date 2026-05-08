const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/db');

const Organization = sequelize.define('Organization', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  userId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  orgCode: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true,
  },
  orgName: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  email: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  address: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  logo: {
    type: DataTypes.STRING,
    allowNull: true,
  },
}, {
  timestamps: true,
});

module.exports = Organization;
