"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ChatController = void 0;
const chatService_1 = require("../services/chatService");
class ChatController {
    async sendMessage(req, res) {
        var _a;
        try {
            const { conversationId, content } = req.body;
            const userId = (_a = req.user) === null || _a === void 0 ? void 0 : _a.userId;
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
            const result = await chatService_1.ChatService.sendMessage({
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
        }
        catch (error) {
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
    async getConversationHistory(req, res) {
        var _a;
        try {
            const { conversationId } = req.params;
            const userId = (_a = req.user) === null || _a === void 0 ? void 0 : _a.userId;
            if (!userId) {
                res.status(401).json({
                    success: false,
                    error: 'Unauthorized',
                    message: 'User not authenticated'
                });
                return;
            }
            const conversation = await chatService_1.ChatService.getConversationHistory(conversationId, userId);
            res.json({
                success: true,
                conversation
            });
        }
        catch (error) {
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
    async getUserConversations(req, res) {
        var _a;
        try {
            const userId = (_a = req.user) === null || _a === void 0 ? void 0 : _a.userId;
            if (!userId) {
                res.status(401).json({
                    success: false,
                    error: 'Unauthorized',
                    message: 'User not authenticated'
                });
                return;
            }
            const conversations = await chatService_1.ChatService.getUserConversations(userId);
            res.json({
                success: true,
                conversations
            });
        }
        catch (error) {
            console.error('Get user conversations error:', error);
            res.status(500).json({
                success: false,
                error: 'Failed to get conversations',
                message: 'Internal server error'
            });
        }
    }
    async deleteConversation(req, res) {
        var _a;
        try {
            const { conversationId } = req.params;
            const userId = (_a = req.user) === null || _a === void 0 ? void 0 : _a.userId;
            if (!userId) {
                res.status(401).json({
                    success: false,
                    error: 'Unauthorized',
                    message: 'User not authenticated'
                });
                return;
            }
            await chatService_1.ChatService.deleteConversation(conversationId, userId);
            res.json({
                success: true,
                message: 'Conversation deleted successfully'
            });
        }
        catch (error) {
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
    async clearUserConversations(req, res) {
        var _a;
        try {
            const userId = (_a = req.user) === null || _a === void 0 ? void 0 : _a.userId;
            if (!userId) {
                res.status(401).json({
                    success: false,
                    error: 'Unauthorized',
                    message: 'User not authenticated'
                });
                return;
            }
            // Get all user conversations and delete them
            const conversations = await chatService_1.ChatService.getUserConversations(userId);
            for (const conversation of conversations) {
                await chatService_1.ChatService.deleteConversation(conversation.id, userId);
            }
            res.json({
                success: true,
                message: `Cleared ${conversations.length} conversations`,
                deletedCount: conversations.length
            });
        }
        catch (error) {
            console.error('Clear conversations error:', error);
            res.status(500).json({
                success: false,
                error: 'Failed to clear conversations',
                message: 'Internal server error'
            });
        }
    }
}
exports.ChatController = ChatController;
//# sourceMappingURL=chatController.js.map