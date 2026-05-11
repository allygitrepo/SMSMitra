// const { DataTypes } = require('sequelize');
// const { sequelize } = require('../config/db');
// 
// const TelegramContact = sequelize.define('TelegramContact', {
//   id: {
//     type: DataTypes.INTEGER,
//     autoIncrement: true,
//     primaryKey: true,
//   },
//   userId: {
//     type: DataTypes.INTEGER,
//     allowNull: false,
//   },
//   orgCode: {
//     type: DataTypes.STRING,
//     allowNull: true,
//   },
//   name: {
//     type: DataTypes.STRING,
//     allowNull: false,
//   },
//   telegramChatId: {
//     type: DataTypes.STRING,
//     allowNull: false,
//     unique: true,
//   },
//   telegramUsername: {
//     type: DataTypes.STRING,
//     allowNull: true,
//   },
// }, {
//   timestamps: true,
//   tableName: 'telegram_contacts',
// });
// 
// module.exports = TelegramContact;
// 