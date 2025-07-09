import express from 'express';
import { AiService } from '../services/aiService';

const router = express.Router();

/**
 * Test OpenRouter API connectivity and configuration
 */
router.get('/openrouter/test', async (req, res) => {
  try {
    console.log('Testing OpenRouter API connectivity...');
    
    const testResult = await AiService.testOpenRouterConnection();
    
    res.json({
      success: true,
      message: 'OpenRouter API test completed',
      data: testResult
    });
  } catch (error: any) {
    console.error('OpenRouter test error:', error);
    
    res.status(500).json({
      success: false,
      message: 'OpenRouter API test failed',
      error: error.message,
      details: error.response?.data || null
    });
  }
});

/**
 * Get OpenRouter API status and configuration
 */
router.get('/openrouter/status', (req, res) => {
  const apiKey = process.env.OPENROUTER_API_KEY;
  const baseUrl = process.env.OPENROUTER_BASE_URL;
  const defaultModel = process.env.DEFAULT_MODEL;
  
  res.json({
    success: true,
    data: {
      apiKeyConfigured: !!apiKey,
      apiKeyLength: apiKey ? apiKey.length : 0,
      baseUrl: baseUrl || 'https://openrouter.ai/api/v1',
      defaultModel: defaultModel || 'deepseek/deepseek-r1-0528:free',
      environment: process.env.NODE_ENV || 'development'
    }
  });
});

/**
 * Simple chat test with fallback handling
 */
router.post('/openrouter/chat-test', async (req, res) => {
  try {
    const { message = 'Hello, this is a test message.' } = req.body;
    
    const result = await AiService.processChatWithFallback(message, {
      userId: 'test-user',
      conversationId: 'test-conversation'
    });
    
    res.json({
      success: true,
      message: 'Chat test completed',
      data: result
    });
    
  } catch (error: any) {
    console.error('Chat test error:', error);
    
    res.status(500).json({
      success: false,
      message: 'Chat test failed',
      error: error.message,
      details: error.response?.data || null
    });
  }
});

export default router;
