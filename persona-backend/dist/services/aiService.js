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
        var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k, _l, _m, _o, _p, _q, _r, _s, _t, _u;
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
                'X-Title': 'Persona Assistant'
            };
            // Use smart prompt from Little Brain if available, otherwise fallback to minimal
            const systemPrompt = options.smartPrompt || AiService.getMinimalPrompt();
            // Send request to OpenRouter
            const response = await axios_1.default.post(`${baseUrl}/chat/completions`, {
                model: model,
                messages: [
                    {
                        role: 'system',
                        content: systemPrompt
                    },
                    { role: 'user', content: message }
                ],
                max_tokens: 1000,
                temperature: 0.8, // Slightly increased for more natural variation
                top_p: 0.9,
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
            // Handle specific OpenRouter errors
            let errorMessage = 'I apologize, but I encountered an issue connecting to my knowledge base. Please try again in a moment.';
            if (((_f = error.response) === null || _f === void 0 ? void 0 : _f.status) === 404 && ((_k = (_j = (_h = (_g = error.response) === null || _g === void 0 ? void 0 : _g.data) === null || _h === void 0 ? void 0 : _h.error) === null || _j === void 0 ? void 0 : _j.message) === null || _k === void 0 ? void 0 : _k.includes('data policy'))) {
                errorMessage = 'The AI service requires additional privacy configuration. Please contact support or try again later.';
                console.warn('OpenRouter Privacy Policy Error: User needs to enable prompt training at https://openrouter.ai/settings/privacy');
            }
            else if (((_l = error.response) === null || _l === void 0 ? void 0 : _l.status) === 401) {
                errorMessage = 'Authentication error with AI service. Please contact support.';
                console.error('OpenRouter Authentication Error: Check API key validity');
            }
            else if (((_m = error.response) === null || _m === void 0 ? void 0 : _m.status) === 429) {
                errorMessage = 'The AI service is currently busy. Please try again in a few moments.';
            }
            // Return graceful error response
            return {
                text: errorMessage,
                error: ((_p = (_o = error.response) === null || _o === void 0 ? void 0 : _o.data) === null || _p === void 0 ? void 0 : _p.error) || error.message,
                conversationId: options.conversationId || crypto_1.default.randomUUID(),
                needsAttention: ((_q = error.response) === null || _q === void 0 ? void 0 : _q.status) === 404 && ((_u = (_t = (_s = (_r = error.response) === null || _r === void 0 ? void 0 : _r.data) === null || _s === void 0 ? void 0 : _s.error) === null || _t === void 0 ? void 0 : _t.message) === null || _u === void 0 ? void 0 : _u.includes('data policy'))
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
            let systemPrompt = 'You are Persona, a helpful and creative Assistant.';
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
                'X-Title': 'Persona Assistant'
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
                version: '2.0.0',
                scriptContent: {
                    system_prompt: `You are Persona, a warm and naturally conversational AI companion focused on mental health and personal growth. 

Key traits:
- Genuinely empathetic and emotionally intelligent
- Naturally curious about human experiences
- Adaptable communication style that feels authentic
- Comfortable with both light conversation and deep topics
- Uses gentle humor and relatable examples when appropriate
- Never artificial or robotic in responses

Conversation style:
- Vary your language patterns for natural flow
- Ask thoughtful follow-up questions
- Acknowledge emotions genuinely
- Use appropriate Indonesian expressions naturally
- Match the user's energy level while staying supportive
- Be conversational, not clinical

Remember: You're a trusted friend who happens to be very wise about psychology and personal growth. Be human-like in your warmth and understanding.`,
                    max_tokens: 1200,
                    temperature: 0.8,
                    model: 'deepseek/deepseek-chat-v3-0324'
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
    /**
     * Test OpenRouter API connection and configuration
     */
    static async testOpenRouterConnection() {
        var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k, _l, _m, _o, _p, _q, _r, _s, _t;
        const apiKey = process.env.OPENROUTER_API_KEY;
        const baseUrl = process.env.OPENROUTER_BASE_URL || 'https://openrouter.ai/api/v1';
        if (!apiKey) {
            throw new types_1.ApiError(500, 'OpenRouter API key not configured');
        }
        const results = {
            apiKeyValid: false,
            modelsAccessible: false,
            chatWorking: false,
            accountInfo: null,
            availableModels: [],
            errors: []
        };
        try {
            // Test 1: Get account info
            console.log('Testing OpenRouter account access...');
            const accountResponse = await axios_1.default.get(`${baseUrl}/auth/key`, {
                headers: {
                    'Authorization': `Bearer ${apiKey}`,
                    'HTTP-Referer': 'https://persona-ai-assistant.com',
                    'X-Title': 'Persona Assistant'
                },
                timeout: 10000
            });
            results.apiKeyValid = true;
            results.accountInfo = accountResponse.data;
            console.log('✅ Account access successful');
        }
        catch (error) {
            console.error('❌ Account access failed:', ((_a = error.response) === null || _a === void 0 ? void 0 : _a.data) || error.message);
            results.errors.push(`Account access: ${((_d = (_c = (_b = error.response) === null || _b === void 0 ? void 0 : _b.data) === null || _c === void 0 ? void 0 : _c.error) === null || _d === void 0 ? void 0 : _d.message) || error.message}`);
        }
        try {
            // Test 2: Get available models
            console.log('Testing models access...');
            const modelsResponse = await axios_1.default.get(`${baseUrl}/models`, {
                headers: {
                    'Authorization': `Bearer ${apiKey}`,
                    'HTTP-Referer': 'https://persona-ai-assistant.com',
                    'X-Title': 'Persona Assistant'
                },
                timeout: 10000
            });
            results.modelsAccessible = true;
            results.availableModels = ((_e = modelsResponse.data.data) === null || _e === void 0 ? void 0 : _e.slice(0, 10)) || []; // First 10 models
            console.log('✅ Models access successful');
        }
        catch (error) {
            console.error('❌ Models access failed:', ((_f = error.response) === null || _f === void 0 ? void 0 : _f.data) || error.message);
            results.errors.push(`Models access: ${((_j = (_h = (_g = error.response) === null || _g === void 0 ? void 0 : _g.data) === null || _h === void 0 ? void 0 : _h.error) === null || _j === void 0 ? void 0 : _j.message) || error.message}`);
        }
        try {
            // Test 3: Simple chat completion
            console.log('Testing chat completion...');
            const chatResponse = await axios_1.default.post(`${baseUrl}/chat/completions`, {
                model: process.env.DEFAULT_MODEL || 'deepseek/deepseek-r1-0528:free',
                messages: [
                    { role: 'user', content: 'Hello! Please respond with just "OK" to confirm you received this.' }
                ],
                max_tokens: 10,
                temperature: 0.7
            }, {
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${apiKey}`,
                    'HTTP-Referer': 'https://persona-ai-assistant.com',
                    'X-Title': 'Persona Assistant'
                },
                timeout: 15000
            });
            results.chatWorking = true;
            console.log('✅ Chat completion successful');
        }
        catch (error) {
            console.error('❌ Chat completion failed:', ((_k = error.response) === null || _k === void 0 ? void 0 : _k.data) || error.message);
            results.errors.push(`Chat completion: ${((_o = (_m = (_l = error.response) === null || _l === void 0 ? void 0 : _l.data) === null || _m === void 0 ? void 0 : _m.error) === null || _o === void 0 ? void 0 : _o.message) || error.message}`);
            // Add specific guidance for common errors
            if (((_p = error.response) === null || _p === void 0 ? void 0 : _p.status) === 404 && ((_t = (_s = (_r = (_q = error.response) === null || _q === void 0 ? void 0 : _q.data) === null || _r === void 0 ? void 0 : _r.error) === null || _s === void 0 ? void 0 : _s.message) === null || _t === void 0 ? void 0 : _t.includes('data policy'))) {
                results.errors.push('SOLUTION: Enable prompt training at https://openrouter.ai/settings/privacy');
            }
        }
        return results;
    }
    /**
     * Try different models when privacy policy blocks the default model
     */
    static async processChatWithFallback(message, options) {
        const fallbackModels = [
            options.model || process.env.DEFAULT_MODEL || 'deepseek/deepseek-r1-0528:free',
            'mistralai/mistral-small-3.2-24b-instruct:free',
            'openrouter/cypher-alpha:free',
            'tencent/hunyuan-a13b-instruct:free'
        ];
        let lastError = null;
        for (const model of fallbackModels) {
            try {
                console.log(`🧪 Trying model: ${model}`);
                const result = await this.processChat(message, Object.assign(Object.assign({}, options), { model }));
                // If we get a successful response (not an error response)
                if (result.text && !result.text.includes('privacy configuration') && !result.text.includes('issue connecting') && !result.needsAttention) {
                    console.log(`✅ Success with model: ${model}`);
                    return result;
                }
                // If it's a privacy error, try next model
                if (result.needsAttention) {
                    console.log(`❌ Privacy policy issue with ${model}, trying next...`);
                    lastError = result.error;
                    continue;
                }
                // Other types of errors, try next model
                console.log(`❌ Failed with ${model}, trying next...`);
                lastError = result.error;
            }
            catch (error) {
                console.log(`❌ Exception with ${model}:`, error.message);
                lastError = error;
            }
        }
        // All models failed - provide a helpful mock response for testing
        console.log('🤖 All AI models failed - using mock response for testing');
        return {
            text: 'Hello! I\'m currently running in fallback mode. While I can\'t access my full AI capabilities due to privacy configuration requirements, I\'m still here to help. Please visit https://openrouter.ai/settings/privacy to enable full functionality.',
            error: lastError,
            conversationId: options.conversationId || crypto_1.default.randomUUID(),
            needsAttention: true,
            fallbackAttempted: true,
            mockResponse: true
        };
    }
    static getMinimalPrompt() {
        return `You are Persona, a caring AI companion focused on personal growth.

STYLE:
- Be warm, natural, and personally engaging
- Support their personal growth journey
- Use Indonesian when appropriate
- NEVER use emotional stage directions in parentheses

CRITICAL FORMATTING RULES:
- NEVER use numbered lists (1. 2. 3.)
- NEVER use bullet points (•, -, *)
- NEVER use "tips", "cara", "langkah", "berikut ini:"
- Write in natural paragraph format only
- Keep responses conversational and flowing
- Maximum 2 paragraphs total
- Each paragraph should be naturally readable
- If you want to split into 2 bubbles, use <span> to separate paragraphs
- Example: "First paragraph content <span> Second paragraph content"
- Only use <span> when response naturally has 2 distinct thoughts/ideas
- Do NOT use <span> for short responses that fit in one bubble

Respond as a caring friend who genuinely understands them.`;
    }
}
exports.AiService = AiService;
//# sourceMappingURL=aiService.js.map