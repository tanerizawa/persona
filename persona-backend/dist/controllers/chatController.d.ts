import { Request, Response } from 'express';
export declare class ChatController {
    sendMessage(req: Request, res: Response): Promise<void>;
    getConversationHistory(req: Request, res: Response): Promise<void>;
    getUserConversations(req: Request, res: Response): Promise<void>;
    deleteConversation(req: Request, res: Response): Promise<void>;
    clearUserConversations(req: Request, res: Response): Promise<void>;
}
