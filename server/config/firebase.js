const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

const serviceAccountPath = path.join(__dirname, '../serviceAccountKey.json');

if (fs.existsSync(serviceAccountPath)) {
  try {
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    console.log('Firebase Admin initialized for project:', serviceAccount.project_id || 'SMS Mitra');
  } catch (err) {
    console.error('Failed to initialize Firebase Admin SDK with serviceAccountKey.json:', err.message);
  }
} else {
  console.warn('⚠️ WARNING: server/serviceAccountKey.json not found. Push notifications (FCM) will be disabled until configured.');
}

module.exports = admin;
