"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.NotificationController = void 0;
const types_1 = require("../types");
const notificationService_1 = require("../services/notificationService");
class NotificationController {
    constructor() {
        this.registerDevice = async (req, res) => {
            var _a;
            try {
                const userId = (_a = req.user) === null || _a === void 0 ? void 0 : _a.userId;
                if (!userId) {
                    throw new types_1.ApiError(401, 'User not authenticated');
                }
                const { fcmToken, platform } = req.body;
                if (!fcmToken) {
                    throw new types_1.ApiError(400, 'FCM token is required');
                }
                await this.notificationService.registerDeviceToken(userId, fcmToken, platform);
                res.status(200).json({
                    success: true,
                    message: 'Device token registered successfully',
                });
            }
            catch (error) {
                console.error('Register device error:', error);
                if (error.statusCode) {
                    res.status(error.statusCode).json({
                        success: false,
                        message: error.message,
                    });
                }
                else {
                    res.status(500).json({
                        success: false,
                        message: 'Internal server error',
                    });
                }
            }
        };
        this.unregisterDevice = async (req, res) => {
            var _a;
            try {
                const userId = (_a = req.user) === null || _a === void 0 ? void 0 : _a.userId;
                if (!userId) {
                    throw new types_1.ApiError(401, 'User not authenticated');
                }
                await this.notificationService.unregisterDeviceToken(userId);
                res.status(200).json({
                    success: true,
                    message: 'Device token unregistered successfully',
                });
            }
            catch (error) {
                console.error('Unregister device error:', error);
                if (error.statusCode) {
                    res.status(error.statusCode).json({
                        success: false,
                        message: error.message,
                    });
                }
                else {
                    res.status(500).json({
                        success: false,
                        message: 'Internal server error',
                    });
                }
            }
        };
        this.sendNotification = async (req, res) => {
            try {
                const { targetUserId, title, body, data } = req.body;
                if (!targetUserId || !title || !body) {
                    throw new types_1.ApiError(400, 'Target user ID, title, and body are required');
                }
                const result = await this.notificationService.sendNotificationToUser(targetUserId, title, body, data);
                res.status(200).json({
                    success: true,
                    message: 'Notification sent successfully',
                    data: result,
                });
            }
            catch (error) {
                console.error('Send notification error:', error);
                if (error.statusCode) {
                    res.status(error.statusCode).json({
                        success: false,
                        message: error.message,
                    });
                }
                else {
                    res.status(500).json({
                        success: false,
                        message: 'Internal server error',
                    });
                }
            }
        };
        this.getNotificationHistory = async (req, res) => {
            var _a;
            try {
                const userId = (_a = req.user) === null || _a === void 0 ? void 0 : _a.userId;
                if (!userId) {
                    throw new types_1.ApiError(401, 'User not authenticated');
                }
                const page = parseInt(req.query.page) || 1;
                const limit = parseInt(req.query.limit) || 20;
                const history = await this.notificationService.getNotificationHistory(userId, page, limit);
                res.status(200).json({
                    success: true,
                    data: history,
                });
            }
            catch (error) {
                console.error('Get notification history error:', error);
                if (error.statusCode) {
                    res.status(error.statusCode).json({
                        success: false,
                        message: error.message,
                    });
                }
                else {
                    res.status(500).json({
                        success: false,
                        message: 'Internal server error',
                    });
                }
            }
        };
        this.notificationService = new notificationService_1.NotificationService();
    }
}
exports.NotificationController = NotificationController;
//# sourceMappingURL=notificationController.js.map