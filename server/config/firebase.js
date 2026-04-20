const admin = require('firebase-admin');
const path = require('path');
require('dotenv').config();

// Using the serviceAccountKey.json file directly for better reliability with private keys
const serviceAccount = require('../serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

console.log('Firebase Admin initialized for project:', process.env.FIREBASE_PROJECT_ID);

module.exports = admin;
