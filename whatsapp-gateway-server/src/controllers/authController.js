const whatsappService = require('../services/whatsappService');

exports.startSession = async (req, res) => {
    try {
        const sessionId = req.body.sessionId || req.query.sessionId || 'user_1';
        await whatsappService.startSession(sessionId);
        res.json({ success: true, message: 'Session starting', sessionId });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

exports.getStatus = (req, res) => {
    const sessionId = req.query.sessionId || 'user_1';
    res.json(whatsappService.getStatus(sessionId));
};

exports.disconnect = async (req, res) => {
    try {
        const sessionId = req.body.sessionId || 'user_1';
        await whatsappService.disconnect(sessionId);
        res.json({ success: true, message: 'Disconnected successfully' });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};
