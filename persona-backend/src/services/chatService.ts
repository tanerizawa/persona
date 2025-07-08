import { prisma } from '../config/database';
import { ApiError } from '../types';
import axios from 'axios';

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

export class ChatService {
  private static readonly OPENROUTER_API_URL = 'https://openrouter.ai/api/v1';
  private static readonly OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY;
  private static readonly DEFAULT_MODEL = process.env.DEFAULT_MODEL;

  /**
   * Send a message and get AI response
   */
  static async sendMessage(data: CreateMessageRequest): Promise<ChatResponse> {
    const { conversationId, content, userId } = data;

    if (!this.OPENROUTER_API_KEY) {
      throw new ApiError(500, 'OpenRouter API key not configured');
    }

    try {
      // Get or create conversation
      let conversation;
      if (conversationId) {
        conversation = await prisma.conversation.findFirst({
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
          throw new ApiError(404, 'Conversation not found');
        }
      } else {
        // Create new conversation
        conversation = await prisma.conversation.create({
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
      const userMessage = await prisma.message.create({
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
          role: msg.role as 'user' | 'assistant',
          content: msg.content
        })),
        {
          role: 'user' as const,
          content
        }
      ];

      // Get AI response
      const aiContent = await this.getAIResponse(messages, userId);

      // Save AI response
      const aiMessage = await prisma.message.create({
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
        await prisma.conversation.update({
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
    } catch (error) {
      console.error('Chat service error:', error);
      if (error instanceof ApiError) {
        throw error;
      }
      throw new ApiError(500, 'Failed to process message');
    }
  }

  /**
   * Get conversation history
   */
  static async getConversationHistory(conversationId: string, userId: string) {
    const conversation = await prisma.conversation.findFirst({
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
      throw new ApiError(404, 'Conversation not found');
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
  static async getUserConversations(userId: string) {
    const conversations = await prisma.conversation.findMany({
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
  static async deleteConversation(conversationId: string, userId: string) {
    const conversation = await prisma.conversation.findFirst({
      where: {
        id: conversationId,
        userId
      }
    });

    if (!conversation) {
      throw new ApiError(404, 'Conversation not found');
    }

    await prisma.conversation.delete({
      where: { id: conversationId }
    });
  }

  /**
   * Get AI response from OpenRouter
   */
  private static async getAIResponse(messages: Array<{role: 'user' | 'assistant', content: string}>, userId: string): Promise<string> {
    try {
      const response = await axios.post(
        `${this.OPENROUTER_API_URL}/chat/completions`,
        {
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
        },
        {
          headers: {
            'Authorization': `Bearer ${this.OPENROUTER_API_KEY}`,
            'Content-Type': 'application/json',
            'X-Title': 'Persona AI Assistant'
          }
        }
      );

      return response.data.choices[0].message.content;
    } catch (error: any) {
      console.error('OpenRouter API error:', error.response?.data || error.message);
      if (error.response?.status === 401) {
        throw new ApiError(500, 'AI service authentication failed');
      }
      if (error.response?.status === 429) {
        throw new ApiError(429, 'AI service rate limit exceeded');
      }
      throw new ApiError(500, 'AI service temporarily unavailable');
    }
  }

  /**
   * Generate conversation title from first message
   */
  private static generateConversationTitle(content: string): string {
    // Take first 50 characters and clean up
    let title = content.substring(0, 50).trim();
    if (content.length > 50) {
      title += '...';
    }
    return title || 'New Conversation';
  }
}
