"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.notFoundHandler = void 0;
const notFoundHandler = (req, res) => {
    const response = {
        success: false,
        error: `Route ${req.originalUrl} not found`,
        timestamp: new Date().toISOString()
    };
    res.status(404).json(response);
};
exports.notFoundHandler = notFoundHandler;
//# sourceMappingURL=notFoundHandler.js.map