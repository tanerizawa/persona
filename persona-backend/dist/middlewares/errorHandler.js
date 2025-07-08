"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.errorHandler = void 0;
const errorHandler = (err, req, res, next) => {
    let statusCode = err.statusCode || 500;
    let message = err.message || 'Internal Server Error';
    // Prisma errors
    if (err.name === 'PrismaClientKnownRequestError') {
        statusCode = 400;
        message = 'Database operation failed';
    }
    // JWT errors
    if (err.name === 'JsonWebTokenError') {
        statusCode = 401;
        message = 'Invalid token';
    }
    if (err.name === 'TokenExpiredError') {
        statusCode = 401;
        message = 'Token expired';
    }
    // Validation errors
    if (err.name === 'ValidationError') {
        statusCode = 400;
        message = err.message;
    }
    // Log error in production
    if (process.env.NODE_ENV === 'production') {
        console.error(`Error ${statusCode}: ${message}`, {
            stack: err.stack,
            url: req.url,
            method: req.method,
            ip: req.ip,
            userAgent: req.get('User-Agent')
        });
    }
    else {
        console.error(err);
    }
    const response = {
        success: false,
        error: message,
        timestamp: new Date().toISOString()
    };
    // Don't leak error details in production
    if (process.env.NODE_ENV === 'development') {
        response.error = err.stack || message;
    }
    res.status(statusCode).json(response);
};
exports.errorHandler = errorHandler;
//# sourceMappingURL=errorHandler.js.map