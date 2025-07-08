"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AiService = void 0;
const database_1 = require("../config/database");
const types_1 = require("../types");
const axios_1 = __importDefault(require("axios"));
const crypto_1 = __importDefault(require("crypto"));
class AiService {
    static async getActiveScripts() {
        const scripts = await database_1.prisma.aiScript.findMany({
            where: { isActive: true },
            orderBy: { createdAt: 'desc' }
        });
        return scripts;
    }
    static async getScriptByName(scriptName) {
        const script = await database_1.prisma.aiScript.findFirst({
            where: {
                scriptName,
                isActive: true
            }
        });
        return script;
    }
    static async createScript(scriptName, version, scriptContent) {
        // Deactivate previous versions
        await database_1.prisma.aiScript.updateMany({
            where: { scriptName },
            data: { isActive: false }
        });
        // Create new version
        const script = await database_1.prisma.aiScript.create({
            data: {
                scriptName,
                version,
                scriptContent: JSON.stringify(scriptContent),
                isActive: true
            }
        });
        return script;
    }
    static async processChat(message, options) {
        var _a, _b, _c, _d, _e, _f, _g;
        try {
            const apiKey = process.env.OPENROUTER_API_KEY;
            if (!apiKey) {
                throw new types_1.ApiError(500, 'OpenRouter API key not configured');
            }
            const baseUrl = process.env.OPENROUTER_BASE_URL || 'https://openrouter.ai/api/v1';
            const model = options.model || process.env.DEFAULT_MODEL || 'deepseek/deepseek-r1-0528:free';
            const headers = {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${apiKey}`,
                'HTTP-Referer': 'https://persona-ai-assistant.com',
                'X-Title': 'Persona AI Assistant'
            };
            // Send request to OpenRouter
            const response = await axios_1.default.post(`${baseUrl}/chat/completions`, {
                model: model,
                messages: [
                    { role: 'system', content: 'You are Persona AI, a helpful and empathetic AI assistant.' },
                    { role: 'user', content: message }
                ],
                max_tokens: 1000,
                temperature: 0.7,
                top_p: 0.95,
                user: options.userId // Help OpenRouter with billing attribution
            }, { headers });
            // Store conversation in database if conversationId is provided
            if (options.conversationId) {
                await this.storeConversation(options.userId, options.conversationId, message, ((_b = (_a = response.data.choices[0]) === null || _a === void 0 ? void 0 : _a.message) === null || _b === void 0 ? void 0 : _b.content) || '');
            }
            return {
                text: ((_d = (_c = response.data.choices[0]) === null || _c === void 0 ? void 0 : _c.message) === null || _d === void 0 ? void 0 : _d.content) || 'Sorry, I could not generate a response.',
                model: response.data.model || model,
                conversationId: options.conversationId || crypto_1.default.randomUUID()
            };
        }
        catch (error) {
            console.error('OpenRouter Chat API Error:', ((_e = error.response) === null || _e === void 0 ? void 0 : _e.data) || error.message);
            // Return graceful error response
            return {
                text: 'I apologize, but I encountered an issue connecting to my knowledge base. Please try again in a moment.',
                error: ((_g = (_f = error.response) === null || _f === void 0 ? void 0 : _f.data) === null || _g === void 0 ? void 0 : _g.error) || error.message,
                conversationId: options.conversationId || crypto_1.default.randomUUID()
            };
        }
    }
    static async generateContent(contentType, parameters, options) {
        var _a, _b, _c, _d, _e, _f, _g;
        try {
            const apiKey = process.env.OPENROUTER_API_KEY;
            if (!apiKey) {
                throw new types_1.ApiError(500, 'OpenRouter API key not configured');
            }
            const baseUrl = process.env.OPENROUTER_BASE_URL || 'https://openrouter.ai/api/v1';
            const model = options.model || process.env.DEFAULT_MODEL || 'deepseek/deepseek-r1-0528:free';
            // Create appropriate prompt based on content type
            let systemPrompt = 'You are Persona AI, a helpful and creative AI assistant.';
            let userPrompt = '';
            switch (contentType) {
                case 'music':
                    systemPrompt = 'You are a music recommendation expert who understands emotions and musical preferences.';
                    userPrompt = `Generate 5 music recommendations for someone who is feeling ${parameters.mood || 'relaxed'}. For each recommendation, include title, artist, album, year, genre, and a brief description of why it matches the mood. Format as JSON.`;
                    break;
                case 'article':
                    systemPrompt = 'You are a content curator who provides insightful article recommendations.';
                    userPrompt = `Suggest 3 interesting articles about ${parameters.topic || 'personal growth'}. For each suggestion, include title, author, publication, year, and a brief summary. Format as JSON.`;
                    break;
                case 'quote':
                    systemPrompt = 'You are a curator of inspirational and meaningful quotes.';
                    userPrompt = `Share a profound quote related to ${parameters.theme || 'resilience'}, including its author and context. Format as JSON.`;
                    break;
                case 'journal':
                    systemPrompt = 'You are a thoughtful journal prompt creator.';
                    userPrompt = `Create a reflective journal prompt related to ${parameters.focus || 'self-awareness'} that helps with personal growth. Format as JSON.`;
                    break;
                default:
                    userPrompt = `Generate creative content related to ${contentType}. Include relevant details and format as JSON.`;
            }
            const headers = {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${apiKey}`,
                'HTTP-Referer': 'https://persona-ai-assistant.com',
                'X-Title': 'Persona AI Assistant'
            };
            // Send request to OpenRouter
            const response = await axios_1.default.post(`${baseUrl}/chat/completions`, {
                model: model,
                messages: [
                    { role: 'system', content: systemPrompt },
                    { role: 'user', content: userPrompt }
                ],
                response_format: { type: "json_object" },
                max_tokens: 1000,
                temperature: 0.7,
                top_p: 0.95,
                user: options.userId // Help OpenRouter with billing attribution
            }, { headers });
            // Parse JSON response
            let content;
            try {
                const text = ((_b = (_a = response.data.choices[0]) === null || _a === void 0 ? void 0 : _a.message) === null || _b === void 0 ? void 0 : _b.content) || '{}';
                content = JSON.parse(text);
            }
            catch (e) {
                content = {
                    content: (_d = (_c = response.data.choices[0]) === null || _c === void 0 ? void 0 : _c.message) === null || _d === void 0 ? void 0 : _d.content,
                    note: "Failed to parse as JSON"
                };
            }
            return {
                content,
                type: contentType,
                model: response.data.model || model
            };
        }
        catch (error) {
            console.error('OpenRouter Content API Error:', ((_e = error.response) === null || _e === void 0 ? void 0 : _e.data) || error.message);
            // Return graceful error response
            return {
                content: {
                    error: ((_g = (_f = error.response) === null || _f === void 0 ? void 0 : _f.data) === null || _g === void 0 ? void 0 : _g.error) || error.message,
                    message: 'I apologize, but I encountered an issue generating content. Please try again later.'
                },
                type: contentType
            };
        }
    }
    static async logApiUsage(userId, type, model) {
        try {
            // Check if user has exceeded daily quota
            const user = await database_1.prisma.user.findUnique({
                where: { id: userId }
            });
            if (!user) {
                throw new types_1.ApiError(404, 'User not found');
            }
            if (user.apiUsageToday >= user.apiQuotaDaily) {
                throw new types_1.ApiError(429, 'Daily API quota exceeded');
            }
            // Check if quota needs reset
            const now = new Date();
            const lastReset = new Date(user.lastQuotaReset);
            const resetNeeded = now.getDate() !== lastReset.getDate() ||
                now.getMonth() !== lastReset.getMonth() ||
                now.getFullYear() !== lastReset.getFullYear();
            // Create usage log
            await database_1.prisma.apiUsageLog.create({
                data: {
                    userId,
                    endpoint: type,
                    model,
                    tokensUsed: 0, // Actual token count would be calculated based on response
                    success: true
                }
            });
            // Update user's usage count or reset if needed
            await database_1.prisma.user.update({
                where: { id: userId },
                data: {
                    apiUsageToday: resetNeeded ? 1 : {
                        increment: 1
                    },
                    lastQuotaReset: resetNeeded ? now : undefined
                }
            });
        }
        catch (error) {
            console.error('Failed to log API usage:', error);
            // Don't rethrow - we don't want API logging to block the response
        }
    }
    static async storeConversation(userId, conversationId, userMessage, aiResponse) {
        try {
            // Simplify: Just log that we would store the conversation
            console.log(`Would store conversation ${conversationId} for user ${userId}`);
            console.log(`User message: ${userMessage.substring(0, 50)}...`);
            console.log(`AI response: ${aiResponse.substring(0, 50)}...`);
            // In a real implementation, we would store the messages in the database
            // but for now, let's skip due to schema issues
            return;
        }
        catch (error) {
            console.error('Failed to store conversation:', error);
            // Don't rethrow - we don't want conversation storage to block the response
        }
    }
    static generateConversationTitle(firstMessage) {
        // Generate a title from the first message
        const words = firstMessage.split(' ');
        if (words.length <= 5) {
            return firstMessage;
        }
        return words.slice(0, 5).join(' ') + '...';
    }
    static async updateScript(scriptName, scriptContent) {
        const script = await database_1.prisma.aiScript.findFirst({
            where: {
                scriptName,
                isActive: true
            }
        });
        if (!script) {
            return null;
        }
        const updatedScript = await database_1.prisma.aiScript.update({
            where: { id: script.id },
            data: { scriptContent: JSON.stringify(scriptContent) }
        });
        return updatedScript;
    }
    static async deactivateScript(scriptName) {
        try {
            await database_1.prisma.aiScript.updateMany({
                where: { scriptName },
                data: { isActive: false }
            });
            return true;
        }
        catch (error) {
            return false;
        }
    }
    static async checkHealth() {
        try {
            // Check database connection
            await database_1.prisma.$queryRaw `SELECT 1`;
            // Count active scripts
            const scriptCount = await database_1.prisma.aiScript.count({
                where: { isActive: true }
            });
            return {
                database: true,
                scripts: scriptCount,
                status: 'healthy'
            };
        }
        catch (error) {
            return {
                database: false,
                scripts: 0,
                status: 'unhealthy'
            };
        }
    }
    // Initialize default scripts
    static async initializeDefaultScripts() {
        const defaultScripts = [
            {
                scriptName: 'chat_personality',
                version: '1.0.0',
                scriptContent: {
                    system_prompt: "You are Persona, an empathetic AI assistant focused on mental health and personal growth.",
                    max_tokens: 1000,
                    temperature: 0.7,
                    model: 'gpt-4'
                }
            },
            {
                scriptName: 'crisis_detection',
                version: '1.0.0',
                scriptContent: {
                    keywords: ['suicide', 'kill myself', 'end it all', 'tidak ingin hidup'],
                    threshold: 0.8,
                    response_template: "I'm here to listen and support you. Please consider reaching out to a mental health professional."
                }
            },
            {
                scriptName: 'mood_analysis',
                version: '1.0.0',
                scriptContent: {
                    mood_categories: ['happy', 'sad', 'anxious', 'angry', 'calm'],
                    analysis_prompt: "Analyze the emotional tone of this message and categorize the mood.",
                    confidence_threshold: 0.6
                }
            }
        ];
        for (const script of defaultScripts) {
            const existing = await database_1.prisma.aiScript.findFirst({
                where: { scriptName: script.scriptName }
            });
            if (!existing) {
                await this.createScript(script.scriptName, script.version, script.scriptContent);
            }
        }
    }
}
exports.AiService = AiService;
//# sourceMappingURL=aiService.js.map