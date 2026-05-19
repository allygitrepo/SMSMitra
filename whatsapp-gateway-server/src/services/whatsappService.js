const { default: makeWASocket, useMultiFileAuthState, DisconnectReason, Browsers } = require('@whiskeysockets/baileys');
const { Boom } = require('@hapi/boom');
const fs = require('fs');
const path = require('path');
const { getIO } = require('../config/socket');

// Store all active sessions: Map<sessionId, sessionData>
const sessions = new Map();

function getSessionPath(sessionId) {
    return path.join(__dirname, '../../sessions', sessionId);
}

async function startSession(sessionId) {
    // Check if session already exists and is already OPEN
    if (sessions.has(sessionId)) {
        const session = sessions.get(sessionId);
        if (session.connectionStatus === 'connected') {
            console.log(`Session ${sessionId} is already connected. Skipping start.`);
            return session.sock;
        }
    }

    const sessionDir = getSessionPath(sessionId);
    const { state, saveCreds } = await useMultiFileAuthState(sessionDir);

    const sock = makeWASocket({
        auth: state,
        browser: Browsers.windows('Chrome'),
        printQRInTerminal: false,
        syncFullHistory: false,
        markOnlineOnConnect: true,
    });

    // Initialize session data
    sessions.set(sessionId, {
        sock,
        qrCodeData: null,
        connectionStatus: 'connecting',
        userPhone: null
    });

    sock.ev.on('creds.update', saveCreds);

    sock.ev.on('connection.update', async (update) => {
        const { connection, lastDisconnect, qr } = update;
        const sessionData = sessions.get(sessionId);
        if (!sessionData) return;

        if (qr) {
            sessionData.qrCodeData = qr;
            sessionData.connectionStatus = 'qr';
            getIO().emit('qr', { sessionId, qr });
        }

        if (connection === 'open') {
            console.log(`[SESSION] ${sessionId} connected successfully!`);
            sessionData.qrCodeData = null;
            sessionData.connectionStatus = 'connected';
            sessionData.userPhone = sock.user.id.split(':')[0];
            getIO().emit('connected', { sessionId, phone: sessionData.userPhone });
        }

        if (connection === 'connecting') {
            console.log(`[SESSION] ${sessionId} is authenticating/syncing...`);
            sessionData.connectionStatus = 'connecting';
        }

        if (connection === 'close') {
            const statusCode = new Boom(lastDisconnect?.error)?.output?.statusCode;
            console.log(`[SESSION] ${sessionId} closed. Reason: ${statusCode}`);
            
            if (statusCode !== DisconnectReason.loggedOut) {
                sessionData.connectionStatus = 'connecting';
                getIO().emit('loading', { sessionId, message: 'Reconnecting...' });
                setTimeout(() => startSession(sessionId), 5000);
            } else {
                sessionData.connectionStatus = 'disconnected';
                sessionData.sock = null;
                sessionData.qrCodeData = null;
                sessionData.userPhone = null;
                sessions.delete(sessionId);
                if (fs.existsSync(sessionDir)) {
                    fs.rmSync(sessionDir, { recursive: true, force: true });
                }
                getIO().emit('disconnected', { sessionId });
            }
        }
    });

    return sock;
}

function getStatus(sessionId) {
    const sessionData = sessions.get(sessionId);
    if (!sessionData) {
        // If not in memory, check if directory exists
        const exists = fs.existsSync(getSessionPath(sessionId));
        return {
            connected: false,
            status: exists ? 'connecting' : 'disconnected',
            qr: null,
            phone: null
        };
    }
    return {
        connected: sessionData.connectionStatus === 'connected',
        status: sessionData.connectionStatus,
        qr: sessionData.qrCodeData,
        phone: sessionData.userPhone
    };
}

async function disconnect(sessionId) {
    const sessionData = sessions.get(sessionId);
    if (sessionData && sessionData.sock) {
        sessionData.sock.logout();
    }
    sessions.delete(sessionId);
    
    const sessionDir = getSessionPath(sessionId);
    if (fs.existsSync(sessionDir)) {
        fs.rmSync(sessionDir, { recursive: true, force: true });
    }
    getIO().emit('disconnected', { sessionId });
}

function getSock(sessionId) {
    const sessionData = sessions.get(sessionId);
    return sessionData ? sessionData.sock : null;
}

module.exports = {
    startSession,
    getStatus,
    disconnect,
    getSock
};
