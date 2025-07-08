import { Router } from 'express';
import { authenticateToken } from '../middlewares/auth';
import { NotificationController } from '../controllers/notificationController';

const router = Router();
const notificationController = new NotificationController();

/**
 * @route   POST /api/notifications/register-device
 * @desc    Register FCM device token for push notifications
 * @access  Private
 */
router.post('/register-device', authenticateToken, notificationController.registerDevice);

/**
 * @route   DELETE /api/notifications/unregister-device
 * @desc    Unregister FCM device token
 * @access  Private
 */
router.delete('/unregister-device', authenticateToken, notificationController.unregisterDevice);

/**
 * @route   POST /api/notifications/send
 * @desc    Send push notification to user (admin only)
 * @access  Private/Admin
 */
router.post('/send', authenticateToken, notificationController.sendNotification);

/**
 * @route   GET /api/notifications/history
 * @desc    Get notification history for user
 * @access  Private
 */
router.get('/history', authenticateToken, notificationController.getNotificationHistory);

export { router as notificationRoutes };
