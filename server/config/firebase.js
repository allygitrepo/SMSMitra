const admin = require('firebase-admin');
const path = require('path');
// Using the serviceAccountKey.json file directly for better reliability with private keys
const serviceAccount = require('../serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

console.log('Firebase Admin initialized for project:', serviceAccount.project_id);

module.exports = admin;
