import { Request, Response } from 'express';
import { ChatService } from '../services/chatService';

export class ChatController {

  async sendMessage(req: Request, res: Response): Promise<void> {
    try {
      const { conversationId, content } = req.body;
      const userId = (req as any).user?.userId;

      if (!userId) {
        res.status(401).json({
          success: false,
          error: 'Unauthorized',
          message: 'User not authenticated'
        });
        return;
      }

      if (!content || typeof content !== 'string' || content.trim().length === 0) {
        res.status(400).json({
          success: false,
          error: 'Invalid message',
          message: 'Message content is required'
        });
        return;
      }

      const result = await ChatService.sendMessage({
        conversationId,
        content: content.trim(),
        userId
      });

      res.json({
        success: true,
        conversation: {
          id: result.conversationId,
          messages: [result.message, result.aiResponse]
        }
      });
    } catch (error: any) {
      console.error('Send message error:', error);
      
      if (error.statusCode) {
        res.status(error.statusCode).json({
          success: false,
          error: error.message,
          message: error.message
        });
        return;
      }

      res.status(500).json({
        success: false,
        error: 'Failed to send message',
        message: 'Internal server error'
      });
    }
  }

  async getConversationHistory(req: Request, res: Response): Promise<void> {
    try {
      const { conversationId } = req.params;
      const userId = (req as any).user?.userId;

      if (!userId) {
        res.status(401).json({
          success: false,
          error: 'Unauthorized',
          message: 'User not authenticated'
        });
        return;
      }

      const conversation = await ChatService.getConversationHistory(conversationId, userId);

      res.json({
        success: true,
        conversation
      });
    } catch (error: any) {
      console.error('Get conversation history error:', error);
      
      if (error.statusCode) {
        res.status(error.statusCode).json({
          success: false,
          error: error.message,
          message: error.message
        });
        return;
      }

      res.status(500).json({
        success: false,
        error: 'Failed to get conversation history',
        message: 'Internal server error'
      });
    }
  }

  async getUserConversations(req: Request, res: Response): Promise<void> {
    try {
      const userId = (req as any).user?.userId;

      if (!userId) {
        res.status(401).json({
          success: false,
          error: 'Unauthorized',
          message: 'User not authenticated'
        });
        return;
      }

      const conversations = await ChatService.getUserConversations(userId);

      res.json({
        success: true,
        conversations
      });
    } catch (error: any) {
      console.error('Get user conversations error:', error);
      
      res.status(500).json({
        success: false,
        error: 'Failed to get conversations',
        message: 'Internal server error'
      });
    }
  }

  async deleteConversation(req: Request, res: Response): Promise<void> {
    try {
      const { conversationId } = req.params;
      const userId = (req as any).user?.userId;

      if (!userId) {
        res.status(401).json({
          success: false,
          error: 'Unauthorized',
          message: 'User not authenticated'
        });
        return;
      }

      await ChatService.deleteConversation(conversationId, userId);

      res.json({
        success: true,
        message: 'Conversation deleted successfully'
      });
    } catch (error: any) {
      console.error('Delete conversation error:', error);
      
      if (error.statusCode) {
        res.status(error.statusCode).json({
          success: false,
          error: error.message,
          message: error.message
        });
        return;
      }

      res.status(500).json({
        success: false,
        error: 'Failed to delete conversation',
        message: 'Internal server error'
      });
    }
  }

  async clearUserConversations(req: Request, res: Response): Promise<void> {
    try {
      const userId = (req as any).user?.userId;

      if (!userId) {
        res.status(401).json({
          success: false,
          error: 'Unauthorized',
          message: 'User not authenticated'
        });
        return;
      }

      // Get all user conversations and delete them
      const conversations = await ChatService.getUserConversations(userId);
      
      for (const conversation of conversations) {
        await ChatService.deleteConversation(conversation.id, userId);
      }

      res.json({
        success: true,
        message: `Cleared ${conversations.length} conversations`,
        deletedCount: conversations.length
      });
    } catch (error: any) {
      console.error('Clear conversations error:', error);
      
      res.status(500).json({
        success: false,
        error: 'Failed to clear conversations',
        message: 'Internal server error'
      });
    }
  }
}
