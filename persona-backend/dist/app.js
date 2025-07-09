"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
var _a;
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const helmet_1 = __importDefault(require("helmet"));
const express_rate_limit_1 = __importDefault(require("express-rate-limit"));
const authRoutes_1 = __importDefault(require("./routes/authRoutes"));
const chatRoutes_1 = __importDefault(require("./routes/chatRoutes"));
const aiRoutes_1 = __importDefault(require("./routes/aiRoutes"));
const syncRoutes_1 = __importDefault(require("./routes/syncRoutes"));
const crisisRoutes_1 = __importDefault(require("./routes/crisisRoutes"));
const notificationRoutes_1 = require("./routes/notificationRoutes");
const testRoutes_1 = __importDefault(require("./routes/testRoutes"));
const configRoutes_1 = __importDefault(require("./routes/configRoutes"));
const app = (0, express_1.default)();
const PORT = process.env.PORT || 3000;
// Security middleware
app.use((0, helmet_1.default)());
app.use((0, cors_1.default)({
    origin: ((_a = process.env.ALLOWED_ORIGINS) === null || _a === void 0 ? void 0 : _a.split(',')) || ['http://localhost:3000', 'http://localhost:8080'],
    credentials: true
}));
// Rate limiting
const limiter = (0, express_rate_limit_1.default)({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // limit each IP to 100 requests per windowMs
    message: {
        error: 'Too many requests',
        message: 'Too many requests from this IP, please try again later.'
    }
});
app.use(limiter);
// Body parsing middleware
app.use(express_1.default.json({ limit: '10mb' }));
app.use(express_1.default.urlencoded({ extended: true }));
// Health check endpoint
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        version: process.env.npm_package_version || '1.0.0'
    });
});
// API routes
app.use('/api/auth', authRoutes_1.default);
app.use('/api/chat', chatRoutes_1.default);
app.use('/api/ai', aiRoutes_1.default);
app.use('/api/sync', syncRoutes_1.default);
app.use('/api/crisis', crisisRoutes_1.default);
app.use('/api/notifications', notificationRoutes_1.notificationRoutes);
app.use('/api/config', configRoutes_1.default);
app.use('/api/test', testRoutes_1.default);
// 404 handler
app.use((req, res) => {
    res.status(404).json({
        error: 'Not found',
        message: 'The requested endpoint does not exist',
        timestamp: new Date().toISOString()
    });
});
// Global error handler
app.use((err, req, res, next) => {
    console.error('Global error handler:', err);
    res.status(err.statusCode || 500).json(Object.assign({ error: err.message || 'Internal server error', message: 'An unexpected error occurred', timestamp: new Date().toISOString() }, (process.env.NODE_ENV === 'development' && { stack: err.stack })));
});
// Start server
app.listen(PORT, () => {
    console.log(`🚀 Persona Backend Server running on port ${PORT}`);
    console.log(`📊 Health check available at http://localhost:${PORT}/health`);
    console.log(`🔐 Authentication API at http://localhost:${PORT}/api/auth`);
    console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
});
exports.default = app;
//# sourceMappingURL=app.js.map