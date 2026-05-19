const app = require('./app');
const http = require('http');
const socketConfig = require('./config/socket');
const { startSession } = require('./services/whatsappService');
const fs = require('fs');
const path = require('path');

const server = http.createServer(app);

// Initialize Socket.io
socketConfig.init(server);

const PORT = process.env.PORT || 3000;

server.listen(PORT, async () => {
    console.log(`Server running on port ${PORT}`);
    
    // Auto-reconnect all existing sessions
    const sessionsDir = path.join(__dirname, '../sessions');
    if (fs.existsSync(sessionsDir)) {
        const sessionFolders = fs.readdirSync(sessionsDir).filter(f => fs.statSync(path.join(sessionsDir, f)).isDirectory());
        
        if (sessionFolders.length > 0) {
            console.log(`Found ${sessionFolders.length} existing session(s), attempting auto-reconnect...`);
            for (const sessionId of sessionFolders) {
                console.log(`Reconnecting session: ${sessionId}`);
                try {
                    await startSession(sessionId);
                } catch (error) {
                    console.error(`Failed to reconnect session ${sessionId}:`, error.message);
                }
            }
        }
    }
});
