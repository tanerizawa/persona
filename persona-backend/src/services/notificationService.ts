import { PrismaClient } from '@prisma/client';
import { ApiError } from '../types';

interface NotificationHistoryItem {
  id: string;
  title: string;
  body: string;
  data?: any;
  createdAt: Date;
  read: boolean;
}

export class NotificationService {
  private prisma: PrismaClient;

  constructor() {
    this.prisma = new PrismaClient();
  }

  async registerDeviceToken(userId: string, fcmToken: string, platform?: string): Promise<void> {
    try {
      // Check if device token already exists for this user
      const existingToken = await this.prisma.deviceToken.findFirst({
        where: {
          userId,
          token: fcmToken,
        },
      });

      if (existingToken) {
        // Update the existing token
        await this.prisma.deviceToken.update({
          where: { id: existingToken.id },
          data: {
            platform: platform || existingToken.platform,
            updatedAt: new Date(),
            active: true,
          },
        });
      } else {
        // Create new device token
        await this.prisma.deviceToken.create({
          data: {
            userId,
            token: fcmToken,
            platform: platform || 'flutter',
            active: true,
          },
        });
      }

      console.log(`✅ Device token registered for user ${userId}`);
    } catch (error) {
      console.error('Error registering device token:', error);
      throw new ApiError(500, 'Failed to register device token');
    }
  }

  async unregisterDeviceToken(userId: string): Promise<void> {
    try {
      // Deactivate all device tokens for this user
      await this.prisma.deviceToken.updateMany({
        where: { userId },
        data: { active: false },
      });

      console.log(`✅ Device tokens unregistered for user ${userId}`);
    } catch (error) {
      console.error('Error unregistering device token:', error);
      throw new ApiError(500, 'Failed to unregister device token');
    }
  }

  async sendNotificationToUser(
    userId: string,
    title: string,
    body: string,
    data?: any
  ): Promise<{ sent: boolean; message: string }> {
    try {
      // Get active device tokens for the user
      const deviceTokens = await this.prisma.deviceToken.findMany({
        where: {
          userId,
          active: true,
        },
      });

      if (deviceTokens.length === 0) {
        return {
          sent: false,
          message: 'No active device tokens found for user',
        };
      }

      // For now, we'll just log the notification
      // In production, this would use Firebase Admin SDK
      console.log(`📱 Would send notification to user ${userId}:`);
      console.log(`   Title: ${title}`);
      console.log(`   Body: ${body}`);
      console.log(`   Data:`, data);
      console.log(`   Tokens: ${deviceTokens.length}`);

      // Store notification in history
      await this.prisma.notificationHistory.create({
        data: {
          userId,
          title,
          body,
          data: data || {},
          sent: true,
        },
      });

      return {
        sent: true,
        message: `Notification sent to ${deviceTokens.length} device(s)`,
      };
    } catch (error) {
      console.error('Error sending notification:', error);
      throw new ApiError(500, 'Failed to send notification');
    }
  }

  async getNotificationHistory(
    userId: string,
    page: number = 1,
    limit: number = 20
  ): Promise<{
    notifications: NotificationHistoryItem[];
    pagination: {
      page: number;
      limit: number;
      total: number;
      pages: number;
    };
  }> {
    try {
      const skip = (page - 1) * limit;

      const [notifications, total] = await Promise.all([
        this.prisma.notificationHistory.findMany({
          where: { userId },
          orderBy: { createdAt: 'desc' },
          skip,
          take: limit,
          select: {
            id: true,
            title: true,
            body: true,
            data: true,
            createdAt: true,
            read: true,
          },
        }),
        this.prisma.notificationHistory.count({
          where: { userId },
        }),
      ]);

      const pages = Math.ceil(total / limit);

      return {
        notifications,
        pagination: {
          page,
          limit,
          total,
          pages,
        },
      };
    } catch (error) {
      console.error('Error getting notification history:', error);
      throw new ApiError(500, 'Failed to get notification history');
    }
  }

  async markNotificationAsRead(userId: string, notificationId: string): Promise<void> {
    try {
      await this.prisma.notificationHistory.updateMany({
        where: {
          id: notificationId,
          userId,
        },
        data: { read: true },
      });
    } catch (error) {
      console.error('Error marking notification as read:', error);
      throw new ApiError(500, 'Failed to mark notification as read');
    }
  }

  async scheduleMoodReminder(userId: string): Promise<void> {
    // This would integrate with a job scheduler like Bull or Agenda
    // For now, just log the intention
    console.log(`📅 Would schedule mood reminder for user ${userId}`);
    
    await this.sendNotificationToUser(
      userId,
      'Mood Check-in Reminder',
      'How are you feeling today? Take a moment to track your mood.',
      {
        type: 'reminder',
        route: '/growth',
        action: 'mood_tracking',
      }
    );
  }

  async scheduleJournalReminder(userId: string): Promise<void> {
    console.log(`📅 Would schedule journal reminder for user ${userId}`);
    
    await this.sendNotificationToUser(
      userId,
      'Journal Reminder',
      'Take a moment to reflect and write in your journal.',
      {
        type: 'reminder',
        route: '/home',
        action: 'journal_prompt',
      }
    );
  }

  // Cleanup method to disconnect Prisma
  async disconnect(): Promise<void> {
    await this.prisma.$disconnect();
  }
}
