"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.authenticateToken = void 0;
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const types_1 = require("../types");
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN
    if (!token) {
        const error = new types_1.ApiError(401, 'Access token required');
        return next(error);
    }
    const jwtSecret = process.env.JWT_SECRET;
    if (!jwtSecret) {
        const error = new types_1.ApiError(500, 'JWT secret not configured');
        return next(error);
    }
    jsonwebtoken_1.default.verify(token, jwtSecret, (err, decoded) => {
        if (err) {
            const error = new types_1.ApiError(403, 'Invalid or expired token');
            return next(error);
        }
        req.user = decoded;
        next();
    });
};
exports.authenticateToken = authenticateToken;
//# sourceMappingURL=auth.js.map