"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ChatService = void 0;
const database_1 = require("../config/database");
const types_1 = require("../types");
const axios_1 = __importDefault(require("axios"));
class ChatService {
    /**
     * Send a message and get AI response
     */
    static async sendMessage(data) {
        const { conversationId, content, userId } = data;
        if (!this.OPENROUTER_API_KEY) {
            throw new types_1.ApiError(500, 'OpenRouter API key not configured');
        }
        try {
            // Get or create conversation
            let conversation;
            if (conversationId) {
                conversation = await database_1.prisma.conversation.findFirst({
                    where: {
                        id: conversationId,
                        userId
                    },
                    include: {
                        messages: {
                            orderBy: { createdAt: 'asc' },
                            take: 20 // Get last 20 messages for context
                        }
                    }
                });
                if (!conversation) {
                    throw new types_1.ApiError(404, 'Conversation not found');
                }
            }
            else {
                // Create new conversation
                conversation = await database_1.prisma.conversation.create({
                    data: {
                        userId,
                        title: this.generateConversationTitle(content)
                    },
                    include: {
                        messages: true
                    }
                });
            }
            // Save user message
            const userMessage = await database_1.prisma.message.create({
                data: {
                    conversationId: conversation.id,
                    userId,
                    role: 'user',
                    content,
                    metadata: {
                        timestamp: new Date().toISOString()
                    }
                }
            });
            // Prepare messages for AI
            const messages = [
                ...conversation.messages.map(msg => ({
                    role: msg.role,
                    content: msg.content
                })),
                {
                    role: 'user',
                    content
                }
            ];
            // Get AI response
            const aiContent = await this.getAIResponse(messages, userId);
            // Save AI response
            const aiMessage = await database_1.prisma.message.create({
                data: {
                    conversationId: conversation.id,
                    userId,
                    role: 'assistant',
                    content: aiContent,
                    metadata: {
                        model: this.DEFAULT_MODEL,
                        timestamp: new Date().toISOString()
                    }
                }
            });
            // Update conversation title if it's the first exchange
            if (conversation.messages.length === 0) {
                await database_1.prisma.conversation.update({
                    where: { id: conversation.id },
                    data: {
                        title: this.generateConversationTitle(content)
                    }
                });
            }
            return {
                conversationId: conversation.id,
                message: {
                    id: userMessage.id,
                    role: 'user',
                    content: userMessage.content,
                    createdAt: userMessage.createdAt,
                    metadata: userMessage.metadata
                },
                aiResponse: {
                    id: aiMessage.id,
                    role: 'assistant',
                    content: aiMessage.content,
                    createdAt: aiMessage.createdAt,
                    metadata: aiMessage.metadata
                }
            };
        }
        catch (error) {
            console.error('Chat service error:', error);
            if (error instanceof types_1.ApiError) {
                throw error;
            }
            throw new types_1.ApiError(500, 'Failed to process message');
        }
    }
    /**
     * Get conversation history
     */
    static async getConversationHistory(conversationId, userId) {
        const conversation = await database_1.prisma.conversation.findFirst({
            where: {
                id: conversationId,
                userId
            },
            include: {
                messages: {
                    orderBy: { createdAt: 'asc' }
                }
            }
        });
        if (!conversation) {
            throw new types_1.ApiError(404, 'Conversation not found');
        }
        return {
            id: conversation.id,
            title: conversation.title,
            createdAt: conversation.createdAt,
            messages: conversation.messages.map(msg => ({
                id: msg.id,
                role: msg.role,
                content: msg.content,
                createdAt: msg.createdAt,
                metadata: msg.metadata
            }))
        };
    }
    /**
     * Get user's conversations
     */
    static async getUserConversations(userId) {
        const conversations = await database_1.prisma.conversation.findMany({
            where: { userId },
            include: {
                messages: {
                    orderBy: { createdAt: 'desc' },
                    take: 1 // Get last message for preview
                }
            },
            orderBy: { updatedAt: 'desc' }
        });
        return conversations.map(conv => ({
            id: conv.id,
            title: conv.title,
            createdAt: conv.createdAt,
            updatedAt: conv.updatedAt,
            lastMessage: conv.messages[0] ? {
                content: conv.messages[0].content,
                role: conv.messages[0].role,
                createdAt: conv.messages[0].createdAt
            } : null
        }));
    }
    /**
     * Delete conversation
     */
    static async deleteConversation(conversationId, userId) {
        const conversation = await database_1.prisma.conversation.findFirst({
            where: {
                id: conversationId,
                userId
            }
        });
        if (!conversation) {
            throw new types_1.ApiError(404, 'Conversation not found');
        }
        await database_1.prisma.conversation.delete({
            where: { id: conversationId }
        });
    }
    /**
     * Get AI response from OpenRouter
     */
    static async getAIResponse(messages, userId) {
        var _a, _b, _c;
        try {
            const response = await axios_1.default.post(`${this.OPENROUTER_API_URL}/chat/completions`, {
                model: this.DEFAULT_MODEL,
                messages: [
                    {
                        role: 'system',
                        content: `You are Persona, an intelligent AI assistant that understands and adapts to the user's personality. You provide thoughtful, personalized responses that help the user grow and understand themselves better. Be empathetic, insightful, and supportive.`
                    },
                    ...messages
                ],
                temperature: 0.7,
                max_tokens: 1000
            }, {
                headers: {
                    'Authorization': `Bearer ${this.OPENROUTER_API_KEY}`,
                    'Content-Type': 'application/json',
                    'X-Title': 'Persona AI Assistant'
                }
            });
            return response.data.choices[0].message.content;
        }
        catch (error) {
            console.error('OpenRouter API error:', ((_a = error.response) === null || _a === void 0 ? void 0 : _a.data) || error.message);
            if (((_b = error.response) === null || _b === void 0 ? void 0 : _b.status) === 401) {
                throw new types_1.ApiError(500, 'AI service authentication failed');
            }
            if (((_c = error.response) === null || _c === void 0 ? void 0 : _c.status) === 429) {
                throw new types_1.ApiError(429, 'AI service rate limit exceeded');
            }
            throw new types_1.ApiError(500, 'AI service temporarily unavailable');
        }
    }
    /**
     * Generate conversation title from first message
     */
    static generateConversationTitle(content) {
        // Take first 50 characters and clean up
        let title = content.substring(0, 50).trim();
        if (content.length > 50) {
            title += '...';
        }
        return title || 'New Conversation';
    }
}
exports.ChatService = ChatService;
ChatService.OPENROUTER_API_URL = 'https://openrouter.ai/api/v1';
ChatService.OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY;
ChatService.DEFAULT_MODEL = process.env.DEFAULT_MODEL;
//# sourceMappingURL=chatService.js.map