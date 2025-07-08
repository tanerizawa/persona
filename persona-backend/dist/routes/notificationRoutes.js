"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.notificationRoutes = void 0;
const express_1 = require("express");
const auth_1 = require("../middlewares/auth");
const notificationController_1 = require("../controllers/notificationController");
const router = (0, express_1.Router)();
exports.notificationRoutes = router;
const notificationController = new notificationController_1.NotificationController();
/**
 * @route   POST /api/notifications/register-device
 * @desc    Register FCM device token for push notifications
 * @access  Private
 */
router.post('/register-device', auth_1.authenticateToken, notificationController.registerDevice);
/**
 * @route   DELETE /api/notifications/unregister-device
 * @desc    Unregister FCM device token
 * @access  Private
 */
router.delete('/unregister-device', auth_1.authenticateToken, notificationController.unregisterDevice);
/**
 * @route   POST /api/notifications/send
 * @desc    Send push notification to user (admin only)
 * @access  Private/Admin
 */
router.post('/send', auth_1.authenticateToken, notificationController.sendNotification);
/**
 * @route   GET /api/notifications/history
 * @desc    Get notification history for user
 * @access  Private
 */
router.get('/history', auth_1.authenticateToken, notificationController.getNotificationHistory);
//# sourceMappingURL=notificationRoutes.js.map