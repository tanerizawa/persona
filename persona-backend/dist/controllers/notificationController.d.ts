import { Request, Response } from 'express';
export declare class NotificationController {
    private notificationService;
    constructor();
    registerDevice: (req: Request, res: Response) => Promise<void>;
    unregisterDevice: (req: Request, res: Response) => Promise<void>;
    sendNotification: (req: Request, res: Response) => Promise<void>;
    getNotificationHistory: (req: Request, res: Response) => Promise<void>;
}
