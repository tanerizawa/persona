import { Router, Request, Response, NextFunction } from 'express';
import { authenticateToken } from '../middlewares/auth';
import { AiService } from '../services/aiService';
import rateLimit from 'express-rate-limit';

// Rate limiter for AI endpoints
const aiLimiter = rateLimit({
  windowMs: Number(process.env.RATE_LIMIT_WINDOW_MS) || 900000, // 15 minutes
  max: Number(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,      // Limit each IP
  message: {
    success: false,
    error: 'Too many AI requests from this IP, please try again after 15 minutes'
  },
  standardHeaders: true,
  legacyHeaders: false,
});

const router = Router();

// Get AI scripts
router.get('/scripts', authenticateToken, async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const scripts = await AiService.getActiveScripts();

    res.status(200).json({
      success: true,
      data: { scripts },
      message: 'AI scripts retrieved successfully',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    next(error);
  }
});

// Get specific AI script
router.get('/scripts/:scriptName', authenticateToken, async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { scriptName } = req.params;

    const script = await AiService.getScriptByName(scriptName);

    if (!script) {
      res.status(404).json({
        success: false,
        error: 'AI script not found',
        timestamp: new Date().toISOString()
      });
      return;
    }

    res.status(200).json({
      success: true,
      data: { script },
      message: 'AI script retrieved successfully',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    next(error);
  }
});

// Health check for AI services
router.get('/health', async (_req: Request, res: Response): Promise<void> => {
  res.status(200).json({
    success: true,
    message: 'AI services operational',
    timestamp: new Date().toISOString()
  });
});

// OpenRouter Chat Proxy Endpoint
router.post('/chat', authenticateToken, aiLimiter, async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { message, conversationId, model } = req.body;
    
    if (!message) {
      res.status(400).json({
        success: false,
        error: 'Message is required',
        timestamp: new Date().toISOString()
      });
      return;
    }
    
    // Get user ID from authenticated request
    const userId = req.user?.id;
    
    if (!userId) {
      res.status(401).json({
        success: false,
        error: 'Authentication required',
        message: 'User ID not found in token',
        timestamp: new Date().toISOString()
      });
      return;
    }
    
    // Process chat message through OpenRouter
    const response = await AiService.processChat(message, {
      userId,
      conversationId,
      model: model || process.env.DEFAULT_MODEL
    });
    
    // Log usage
    await AiService.logApiUsage(userId, 'chat', model || process.env.DEFAULT_MODEL || 'default');
    
    res.status(200).json({
      success: true,
      data: response,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    next(error);
  }
});

// OpenRouter Content Generation Proxy Endpoint
router.post('/content', authenticateToken, aiLimiter, async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { contentType, parameters, model } = req.body;
    
    if (!contentType) {
      res.status(400).json({
        success: false,
        error: 'Content type is required',
        timestamp: new Date().toISOString()
      });
      return;
    }
    
    // Get user ID from authenticated request
    const userId = req.user?.id;
    
    if (!userId) {
      res.status(401).json({
        success: false,
        error: 'Authentication required',
        message: 'User ID not found in token',
        timestamp: new Date().toISOString()
      });
      return;
    }
    
    // Generate content through OpenRouter
    const content = await AiService.generateContent(contentType, parameters, {
      userId,
      model: model || process.env.DEFAULT_MODEL
    });
    
    // Log usage
    await AiService.logApiUsage(userId, 'content', model || process.env.DEFAULT_MODEL || 'default');
    
    res.status(200).json({
      success: true,
      data: content,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    next(error);
  }
});
router.get('/health', async (req: Request, res: Response): Promise<void> => {
  try {
    // Simple health check for AI services
    const health = {
      openRouterApi: process.env.OPENROUTER_API_KEY ? 'configured' : 'not configured',
      timestamp: new Date().toISOString()
    };

    res.status(200).json({
      success: true,
      data: { health },
      message: 'AI services health check completed',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'AI services health check failed',
      timestamp: new Date().toISOString()
    });
  }
});

export default router;
