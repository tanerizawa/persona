import { AiScript } from '../types';
export declare class AiService {
    static getActiveScripts(): Promise<AiScript[]>;
    static getScriptByName(scriptName: string): Promise<AiScript | null>;
    static createScript(scriptName: string, version: string, scriptContent: Record<string, any>): Promise<AiScript>;
    static processChat(message: string, options: {
        userId: string;
        conversationId?: string;
        model?: string;
        smartPrompt?: string;
    }): Promise<{
        text: any;
        model: any;
        conversationId: string;
        error?: undefined;
        needsAttention?: undefined;
    } | {
        text: string;
        error: any;
        conversationId: string;
        needsAttention: any;
        model?: undefined;
    }>;
    static generateContent(contentType: string, parameters: any, options: {
        userId: string;
        model?: string;
    }): Promise<{
        content: any;
        type: string;
        model: any;
    } | {
        content: {
            error: any;
            message: string;
        };
        type: string;
        model?: undefined;
    }>;
    static logApiUsage(userId: string, type: string, model: string): Promise<void>;
    static storeConversation(userId: string, conversationId: string, userMessage: string, aiResponse: string): Promise<void>;
    static generateConversationTitle(firstMessage: string): string;
    static updateScript(scriptName: string, scriptContent: Record<string, any>): Promise<AiScript | null>;
    static deactivateScript(scriptName: string): Promise<boolean>;
    static checkHealth(): Promise<{
        database: boolean;
        scripts: number;
        status: string;
    }>;
    static initializeDefaultScripts(): Promise<void>;
    /**
     * Test OpenRouter API connection and configuration
     */
    static testOpenRouterConnection(): Promise<{
        apiKeyValid: boolean;
        modelsAccessible: boolean;
        chatWorking: boolean;
        accountInfo: null;
        availableModels: any[];
        errors: string[];
    }>;
    /**
     * Try different models when privacy policy blocks the default model
     */
    static processChatWithFallback(message: string, options: {
        userId: string;
        conversationId?: string;
        model?: string;
    }): Promise<{
        text: any;
        model: any;
        conversationId: string;
        error?: undefined;
        needsAttention?: undefined;
    } | {
        text: string;
        error: any;
        conversationId: string;
        needsAttention: any;
        model?: undefined;
    } | {
        text: string;
        error: any;
        conversationId: string;
        needsAttention: boolean;
        fallbackAttempted: boolean;
        mockResponse: boolean;
    }>;
    static getMinimalPrompt(): string;
}
