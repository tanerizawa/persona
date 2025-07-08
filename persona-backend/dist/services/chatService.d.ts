export interface ChatMessage {
    id: string;
    role: 'user' | 'assistant';
    content: string;
    createdAt: Date;
    metadata?: any;
}
export interface CreateMessageRequest {
    conversationId?: string;
    content: string;
    userId: string;
}
export interface ChatResponse {
    conversationId: string;
    message: ChatMessage;
    aiResponse: ChatMessage;
}
export declare class ChatService {
    private static readonly OPENROUTER_API_URL;
    private static readonly OPENROUTER_API_KEY;
    private static readonly DEFAULT_MODEL;
    /**
     * Send a message and get AI response
     */
    static sendMessage(data: CreateMessageRequest): Promise<ChatResponse>;
    /**
     * Get conversation history
     */
    static getConversationHistory(conversationId: string, userId: string): Promise<{
        id: string;
        title: string | null;
        createdAt: Date;
        messages: {
            id: string;
            role: string;
            content: string;
            createdAt: Date;
            metadata: import("@prisma/client/runtime/library").JsonValue;
        }[];
    }>;
    /**
     * Get user's conversations
     */
    static getUserConversations(userId: string): Promise<{
        id: string;
        title: string | null;
        createdAt: Date;
        updatedAt: Date;
        lastMessage: {
            content: string;
            role: string;
            createdAt: Date;
        } | null;
    }[]>;
    /**
     * Delete conversation
     */
    static deleteConversation(conversationId: string, userId: string): Promise<void>;
    /**
     * Get AI response from OpenRouter
     */
    private static getAIResponse;
    /**
     * Generate conversation title from first message
     */
    private static generateConversationTitle;
}
