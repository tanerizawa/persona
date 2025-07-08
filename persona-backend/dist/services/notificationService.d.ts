interface NotificationHistoryItem {
    id: string;
    title: string;
    body: string;
    data?: any;
    createdAt: Date;
    read: boolean;
}
export declare class NotificationService {
    private prisma;
    constructor();
    registerDeviceToken(userId: string, fcmToken: string, platform?: string): Promise<void>;
    unregisterDeviceToken(userId: string): Promise<void>;
    sendNotificationToUser(userId: string, title: string, body: string, data?: any): Promise<{
        sent: boolean;
        message: string;
    }>;
    getNotificationHistory(userId: string, page?: number, limit?: number): Promise<{
        notifications: NotificationHistoryItem[];
        pagination: {
            page: number;
            limit: number;
            total: number;
            pages: number;
        };
    }>;
    markNotificationAsRead(userId: string, notificationId: string): Promise<void>;
    scheduleMoodReminder(userId: string): Promise<void>;
    scheduleJournalReminder(userId: string): Promise<void>;
    disconnect(): Promise<void>;
}
export {};
