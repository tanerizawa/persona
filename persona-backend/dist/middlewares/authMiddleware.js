"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.optionalAuthMiddleware = exports.authMiddleware = void 0;
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const authMiddleware = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            res.status(401).json({
                success: false,
                error: 'Authentication required',
                message: 'No valid authorization token provided'
            });
            return;
        }
        const token = authHeader.substring(7); // Remove 'Bearer ' prefix
        const jwtSecret = process.env.JWT_SECRET;
        if (!jwtSecret) {
            console.error('JWT_SECRET not configured');
            res.status(500).json({
                success: false,
                error: 'Server configuration error',
                message: 'Authentication service not properly configured'
            });
            return;
        }
        try {
            const decoded = jsonwebtoken_1.default.verify(token, jwtSecret);
            // Add user info to request object
            req.user = {
                id: decoded.id,
                userId: decoded.id, // For backward compatibility
                email: decoded.email,
                iat: decoded.iat,
                exp: decoded.exp
            };
            next();
        }
        catch (jwtError) {
            if (jwtError.name === 'TokenExpiredError') {
                res.status(401).json({
                    success: false,
                    error: 'Token expired',
                    message: 'Access token has expired. Please refresh your token.'
                });
                return;
            }
            if (jwtError.name === 'JsonWebTokenError') {
                res.status(401).json({
                    success: false,
                    error: 'Invalid token',
                    message: 'The provided token is invalid'
                });
                return;
            }
            res.status(401).json({
                success: false,
                error: 'Authentication failed',
                message: 'Token verification failed'
            });
            return;
        }
    }
    catch (error) {
        console.error('Auth middleware error:', error);
        res.status(500).json({
            success: false,
            error: 'Authentication error',
            message: 'Internal server error during authentication'
        });
        return;
    }
};
exports.authMiddleware = authMiddleware;
const optionalAuthMiddleware = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            // No auth header, continue without user info
            next();
            return;
        }
        const token = authHeader.substring(7);
        const jwtSecret = process.env.JWT_SECRET;
        if (!jwtSecret) {
            next();
            return;
        }
        try {
            const decoded = jsonwebtoken_1.default.verify(token, jwtSecret);
            req.user = {
                id: decoded.id,
                userId: decoded.id, // For backward compatibility
                email: decoded.email,
                iat: decoded.iat,
                exp: decoded.exp
            };
        }
        catch (jwtError) {
            // Invalid token, but continue without user info
            console.warn('Optional auth failed:', jwtError);
        }
        next();
    }
    catch (error) {
        console.error('Optional auth middleware error:', error);
        next(); // Continue even if there's an error
    }
};
exports.optionalAuthMiddleware = optionalAuthMiddleware;
//# sourceMappingURL=authMiddleware.js.map