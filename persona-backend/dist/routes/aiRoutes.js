"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const auth_1 = require("../middlewares/auth");
const aiService_1 = require("../services/aiService");
const express_rate_limit_1 = __importDefault(require("express-rate-limit"));
// Rate limiter for AI endpoints
const aiLimiter = (0, express_rate_limit_1.default)({
    windowMs: Number(process.env.RATE_LIMIT_WINDOW_MS) || 900000, // 15 minutes
    max: Number(process.env.RATE_LIMIT_MAX_REQUESTS) || 100, // Limit each IP
    message: {
        success: false,
        error: 'Too many AI requests from this IP, please try again after 15 minutes'
    },
    standardHeaders: true,
    legacyHeaders: false,
});
const router = (0, express_1.Router)();
// Get AI scripts
router.get('/scripts', auth_1.authenticateToken, async (req, res, next) => {
    try {
        const scripts = await aiService_1.AiService.getActiveScripts();
        res.status(200).json({
            success: true,
            data: { scripts },
            message: 'AI scripts retrieved successfully',
            timestamp: new Date().toISOString()
        });
    }
    catch (error) {
        next(error);
    }
});
// Get specific AI script
router.get('/scripts/:scriptName', auth_1.authenticateToken, async (req, res, next) => {
    try {
        const { scriptName } = req.params;
        const script = await aiService_1.AiService.getScriptByName(scriptName);
        if (!script) {
            res.status(404).json({
                success: false,
                error: 'AI script not found',
                timestamp: new Date().toISOString()
            });
            return;
        }
        res.status(200).json({
            success: true,
            data: { script },
            message: 'AI script retrieved successfully',
            timestamp: new Date().toISOString()
        });
    }
    catch (error) {
        next(error);
    }
});
// Health check for AI services
router.get('/health', async (_req, res) => {
    res.status(200).json({
        success: true,
        message: 'AI services operational',
        timestamp: new Date().toISOString()
    });
});
// OpenRouter Chat Proxy Endpoint
router.post('/chat', auth_1.authenticateToken, aiLimiter, async (req, res, next) => {
    var _a;
    try {
        const { message, conversationId, model } = req.body;
        if (!message) {
            res.status(400).json({
                success: false,
                error: 'Message is required',
                timestamp: new Date().toISOString()
            });
            return;
        }
        // Get user ID from authenticated request
        const userId = (_a = req.user) === null || _a === void 0 ? void 0 : _a.id;
        if (!userId) {
            res.status(401).json({
                success: false,
                error: 'Authentication required',
                message: 'User ID not found in token',
                timestamp: new Date().toISOString()
            });
            return;
        }
        // Process chat message through OpenRouter
        const response = await aiService_1.AiService.processChat(message, {
            userId,
            conversationId,
            model: model || process.env.DEFAULT_MODEL
        });
        // Log usage
        await aiService_1.AiService.logApiUsage(userId, 'chat', model || process.env.DEFAULT_MODEL || 'default');
        res.status(200).json({
            success: true,
            data: response,
            timestamp: new Date().toISOString()
        });
    }
    catch (error) {
        next(error);
    }
});
// OpenRouter Content Generation Proxy Endpoint
router.post('/content', auth_1.authenticateToken, aiLimiter, async (req, res, next) => {
    var _a;
    try {
        const { contentType, parameters, model } = req.body;
        if (!contentType) {
            res.status(400).json({
                success: false,
                error: 'Content type is required',
                timestamp: new Date().toISOString()
            });
            return;
        }
        // Get user ID from authenticated request
        const userId = (_a = req.user) === null || _a === void 0 ? void 0 : _a.id;
        if (!userId) {
            res.status(401).json({
                success: false,
                error: 'Authentication required',
                message: 'User ID not found in token',
                timestamp: new Date().toISOString()
            });
            return;
        }
        // Generate content through OpenRouter
        const content = await aiService_1.AiService.generateContent(contentType, parameters, {
            userId,
            model: model || process.env.DEFAULT_MODEL
        });
        // Log usage
        await aiService_1.AiService.logApiUsage(userId, 'content', model || process.env.DEFAULT_MODEL || 'default');
        res.status(200).json({
            success: true,
            data: content,
            timestamp: new Date().toISOString()
        });
    }
    catch (error) {
        next(error);
    }
});
router.get('/health', async (req, res) => {
    try {
        // Simple health check for AI services
        const health = {
            openRouterApi: process.env.OPENROUTER_API_KEY ? 'configured' : 'not configured',
            timestamp: new Date().toISOString()
        };
        res.status(200).json({
            success: true,
            data: { health },
            message: 'AI services health check completed',
            timestamp: new Date().toISOString()
        });
    }
    catch (error) {
        res.status(500).json({
            success: false,
            error: 'AI services health check failed',
            timestamp: new Date().toISOString()
        });
    }
});
exports.default = router;
//# sourceMappingURL=aiRoutes.js.map