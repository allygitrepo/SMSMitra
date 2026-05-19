const { getSock } = require('../services/whatsappService');
const path = require('path');
const fs = require('fs');
const http = require('http');

exports.sendBulkMessage = async (req, res) => {
    try {
        const { messages, sessionId = 'user_1', userId, orgCode, simId } = req.body;
        
        if (!messages || !Array.isArray(messages)) {
            return res.status(400).json({ success: false, message: 'messages array is required' });
        }

        const sock = getSock(sessionId);
        if (!sock) {
            return res.status(500).json({ success: false, message: 'WhatsApp not connected for this session' });
        }

        // Return immediately to let the client know the queue has started
        res.json({ success: true, message: 'Bulk messages queued successfully', queuedCount: messages.length });

        const QUEUE_INTERVAL_MS = 2000;
        
        // Process the queue asynchronously
        (async () => {
            for (const msg of messages) {
                const { number, message } = msg;
                let status = 'failed';
                let errorMsg = null;
                
                try {
                    const cleanNumber = number.replace(/\D/g, '');
                    const [result] = await sock.onWhatsApp(cleanNumber);

                    if (result && result.exists) {
                        await sock.sendMessage(result.jid, { text: message });
                        status = 'sent';
                    } else {
                        errorMsg = 'Number is not on WhatsApp';
                    }
                } catch (error) {
                    errorMsg = error.message;
                }

                // Log to the main SMS server
                try {
                    const postData = JSON.stringify({
                        userId: userId || sessionId,
                        phoneNumber: number,
                        message: message,
                        status: status,
                        simId: simId || 'whatsapp',
                        orgCode: orgCode,
                        channel: 'whatsapp',
                        errorMessage: errorMsg
                    });
                    
                    const options = {
                        hostname: 'localhost',
                        port: 3001,
                        path: '/smsmitra/v1/sms/log',
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            'Content-Length': Buffer.byteLength(postData)
                        }
                    };
                    
                    const logReq = http.request(options, (logRes) => {
                        let data = '';
                        logRes.on('data', (chunk) => data += chunk);
                        logRes.on('end', () => {
                            if (logRes.statusCode !== 201 && logRes.statusCode !== 200) {
                                console.error(`[LOG-ERROR] Main server returned ${logRes.statusCode}: ${data}`);
                            } else {
                                console.log(`[LOG-SUCCESS] Message logged to main server for ${number}`);
                            }
                        });
                    });
                    
                    logReq.on('error', (e) => console.error('[LOG-NETWORK-ERROR] Failed to connect to main server:', e.message));
                    logReq.write(postData);
                    logReq.end();
                } catch (logError) {
                    console.error('[LOG-PREP-ERROR] Failed to prepare log request:', logError.message);
                }

                // Wait before sending the next message
                await new Promise(resolve => setTimeout(resolve, QUEUE_INTERVAL_MS));
            }
        })();

    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

exports.sendMessage = async (req, res) => {
    try {
        const { number, message, sessionId = 'user_1' } = req.body;
        const file = req.file;

        if (!number) {
            if (file) fs.unlinkSync(file.path);
            return res.status(400).json({ success: false, message: 'Number is required' });
        }

        if (!message && !file) {
            return res.status(400).json({ success: false, message: 'Either message or file is required' });
        }

        const sock = getSock(sessionId);
        if (!sock) {
            if (file) fs.unlinkSync(file.path);
            return res.status(500).json({ success: false, message: 'WhatsApp not connected for this session' });
        }

        const cleanNumber = number.replace(/\D/g, '');
        const [result] = await sock.onWhatsApp(cleanNumber);

        if (!result || !result.exists) {
            if (file) fs.unlinkSync(file.path);
            return res.status(400).json({ success: false, message: 'Number is not on WhatsApp' });
        }

        if (file) {
            const ext = path.extname(file.originalname).toLowerCase();
            const isImage = ['.jpg', '.jpeg', '.png', '.gif'].includes(ext);

            if (isImage) {
                await sock.sendMessage(result.jid, {
                    image: { url: file.path },
                    caption: message || ''
                });
            } else {
                await sock.sendMessage(result.jid, {
                    document: { url: file.path },
                    mimetype: file.mimetype,
                    fileName: file.originalname,
                    caption: message || ''
                });
            }
            fs.unlinkSync(file.path);
        } else {
            await sock.sendMessage(result.jid, { text: message });
        }

        res.json({ success: true, message: 'Message sent successfully' });

        // Log to main server
        try {
            const postData = JSON.stringify({
                userId: sessionId,
                phoneNumber: number,
                message: message || (file ? `File: ${file.originalname}` : ''),
                status: 'sent',
                simId: 'whatsapp',
                channel: 'whatsapp'
            });
            
            const options = {
                hostname: 'localhost',
                port: 3001,
                path: '/smsmitra/v1/sms/log',
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Content-Length': Buffer.byteLength(postData)
                }
            };
            
            const logReq = http.request(options);
            logReq.on('error', (e) => console.error('Failed to log message:', e.message));
            logReq.write(postData);
            logReq.end();
        } catch (e) {
            console.error('Logging error:', e);
        }

    } catch (error) {
        if (req.file && fs.existsSync(req.file.path)) fs.unlinkSync(req.file.path);
        res.status(500).json({ success: false, error: error.message });
    }
};
