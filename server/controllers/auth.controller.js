const User = require('../models/user.model');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// Helper to generate 4-digit alphanumeric code
const generateDeviceCode = () => {
  return Math.random().toString(36).substring(2, 6).toUpperCase();
};

exports.register = async (req, res) => {
  try {
    const { fullName, email, phoneNumber, password } = req.body;

    const userExists = await User.findOne({ where: { email } });
    if (userExists) return res.status(400).json({ message: 'User already exists' });

    const hashedPassword = await bcrypt.hash(password, 10);
    const deviceCode = generateDeviceCode();

    const user = await User.create({
      fullName,
      email,
      phoneNumber,
      password: hashedPassword,
      deviceCode
    });

    const token = jwt.sign({ id: user.id }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRE });

    res.status(201).json({
      token,
      user: {
        id: user.id,
        fullName: user.fullName,
        email: user.email,
        deviceCode: user.deviceCode
      }
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ where: { email } });

    if (!user || !(await bcrypt.compare(password, user.password))) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const token = jwt.sign({ id: user.id }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRE });

    res.json({
      token,
      user: {
        id: user.id,
        fullName: user.fullName,
        email: user.email,
        deviceCode: user.deviceCode
      }
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.updateFcmToken = async (req, res) => {
  try {
    const { deviceCode, fcmToken } = req.body;
    const user = await User.findOne({ where: { deviceCode } });

    if (!user) return res.status(404).json({ message: 'Device not found' });

    user.fcmToken = fcmToken;
    await user.save();

    res.json({ message: 'FCM Token updated successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
