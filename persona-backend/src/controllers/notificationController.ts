import { Request, Response } from 'express';
import { ApiError } from '../types';
import { NotificationService } from '../services/notificationService';

export class NotificationController {
  private notificationService: NotificationService;

  constructor() {
    this.notificationService = new NotificationService();
  }

  public registerDevice = async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = req.user?.userId;
      if (!userId) {
        throw new ApiError(401, 'User not authenticated');
      }

      const { fcmToken, platform } = req.body;

      if (!fcmToken) {
        throw new ApiError(400, 'FCM token is required');
      }

      await this.notificationService.registerDeviceToken(userId, fcmToken, platform);

      res.status(200).json({
        success: true,
        message: 'Device token registered successfully',
      });
    } catch (error: any) {
      console.error('Register device error:', error);

      if (error.statusCode) {
        res.status(error.statusCode).json({
          success: false,
          message: error.message,
        });
      } else {
        res.status(500).json({
          success: false,
          message: 'Internal server error',
        });
      }
    }
  };

  public unregisterDevice = async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = req.user?.userId;
      if (!userId) {
        throw new ApiError(401, 'User not authenticated');
      }

      await this.notificationService.unregisterDeviceToken(userId);

      res.status(200).json({
        success: true,
        message: 'Device token unregistered successfully',
      });
    } catch (error: any) {
      console.error('Unregister device error:', error);

      if (error.statusCode) {
        res.status(error.statusCode).json({
          success: false,
          message: error.message,
        });
      } else {
        res.status(500).json({
          success: false,
          message: 'Internal server error',
        });
      }
    }
  };

  public sendNotification = async (req: Request, res: Response): Promise<void> => {
    try {
      const { targetUserId, title, body, data } = req.body;

      if (!targetUserId || !title || !body) {
        throw new ApiError(400, 'Target user ID, title, and body are required');
      }

      const result = await this.notificationService.sendNotificationToUser(
        targetUserId,
        title,
        body,
        data
      );

      res.status(200).json({
        success: true,
        message: 'Notification sent successfully',
        data: result,
      });
    } catch (error: any) {
      console.error('Send notification error:', error);

      if (error.statusCode) {
        res.status(error.statusCode).json({
          success: false,
          message: error.message,
        });
      } else {
        res.status(500).json({
          success: false,
          message: 'Internal server error',
        });
      }
    }
  };

  public getNotificationHistory = async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = req.user?.userId;
      if (!userId) {
        throw new ApiError(401, 'User not authenticated');
      }

      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 20;

      const history = await this.notificationService.getNotificationHistory(userId, page, limit);

      res.status(200).json({
        success: true,
        data: history,
      });
    } catch (error: any) {
      console.error('Get notification history error:', error);

      if (error.statusCode) {
        res.status(error.statusCode).json({
          success: false,
          message: error.message,
        });
      } else {
        res.status(500).json({
          success: false,
          message: 'Internal server error',
        });
      }
    }
  };
}
